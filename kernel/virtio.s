# This contains the basics for any VirtIO drivers.

# The VirtIO specification helps to present a variety of devices to guest
# operating systems when executed within a more sophisticated environment.
# For us, it is the TinyEmu environment acting as a hypervisor of sorts.
#
# TinyEmu supports MMIO-enabled virtio for their RISC-V system. The following
# are a set of constants and functions related to using that MMIO interface.
#
# The way a VirtIO device works is that it has a series of pages a driver and
# device can read and write from to exchange information. These are organized
# into queues (ring buffers, if done properly.) described by three different
# descriptor tables.
#
# The generic descriptor table (QUEUE_DESC) lists all of the buffers in the
# queue. These are broken down into Available buffers (QUEUE_AVAIL) which are
# particular buffers that are queued by the driver for consumption by the
# device, and Used buffers (QUEUE_USED) which are buffers queued by the device
# for consumption by the driver.
#
# Devices, overall, can have many queues. Many will choose to have a single
# queue for reading (driver->device) and writing (device->driver). You will note
# that the terminology used here is from the device's perspective. (We write to
# the read queue, and read from the write queue.) Just a nice little quirk.
#
# The device notifies us about new information via an interrupt.
# The driver (the We/Us in this situation) notifies the device of new data via
# the notify register in the MMIO interface (QUEUE_NOTIFY).
#
# The VirtIO documentation and specification makes understanding available and
# used lists, and their headers, so obtuse... it's absurd. Only systems people
# can make linked lists look like the Voynich manuscript.

.include "const.s"
.include "util.s"

# Boot Initialization
.globl virtio_init

# Interrupt manipulation
.globl virtio_ack_interrupt

# Queue manipulation
.globl virtio_queue_ready
.globl virtio_queue_select
.globl virtio_queue_notify
.globl virtio_queue_set_descriptor
.globl virtio_queue_set_available
.globl virtio_queue_set_used
.globl virtio_queue_size

# Descriptor manipulation
.globl virtio_descriptor_init
.globl virtio_descriptor_set_address
.globl virtio_descriptor_set_length
.globl virtio_descriptor_set_write

# Available List manipulation
.globl virtio_available_init

# Used List manipulation
.globl virtio_used_init

# The magic value to check for when enumerating devices
.set MAGIC_VALUE,                     0x74726976

# The offsets for each register when using virtio over MMIO
.set VIRTIO_MMIO_MAGIC_VALUE,         0x000
.set VIRTIO_MMIO_VERSION,             0x004
.set VIRTIO_MMIO_DEVICE_ID,           0x008
.set VIRTIO_MMIO_VENDOR_ID,           0x00c
.set VIRTIO_MMIO_DEVICE_FEATURES,     0x010
.set VIRTIO_MMIO_DEVICE_FEATURES_SEL, 0x014
.set VIRTIO_MMIO_DRIVER_FEATURES,     0x020
.set VIRTIO_MMIO_DRIVER_FEATURES_SEL, 0x024
.set VIRTIO_MMIO_GUEST_PAGE_SIZE,     0x028 /* version 1 only */
.set VIRTIO_MMIO_QUEUE_SEL,	          0x030
.set VIRTIO_MMIO_QUEUE_NUM_MAX,       0x034
.set VIRTIO_MMIO_QUEUE_NUM,	          0x038
.set VIRTIO_MMIO_QUEUE_ALIGN,         0x03c /* version 1 only */
.set VIRTIO_MMIO_QUEUE_PFN,           0x040 /* version 1 only */
.set VIRTIO_MMIO_QUEUE_READY,         0x044
.set VIRTIO_MMIO_QUEUE_NOTIFY,        0x050
.set VIRTIO_MMIO_INTERRUPT_STATUS,    0x060
.set VIRTIO_MMIO_INTERRUPT_ACK,       0x064
.set VIRTIO_MMIO_STATUS,              0x070
.set VIRTIO_MMIO_QUEUE_DESC_LOW,      0x080
.set VIRTIO_MMIO_QUEUE_DESC_HIGH,     0x084
.set VIRTIO_MMIO_QUEUE_AVAIL_LOW,     0x090
.set VIRTIO_MMIO_QUEUE_AVAIL_HIGH,    0x094
.set VIRTIO_MMIO_QUEUE_USED_LOW,      0x0a0
.set VIRTIO_MMIO_QUEUE_USED_HIGH,     0x0a4
.set VIRTIO_MMIO_CONFIG_GENERATION,   0x0fc
.set VIRTIO_MMIO_CONFIG,              0x100

# Input device configuration registers
.set VIRTIO_INPUT_CFG_UNSET,          0x00
.set VIRTIO_INPUT_CFG_ID_NAME,        0x01
.set VIRTIO_INPUT_CFG_ID_SERIAL,      0x02
.set VIRTIO_INPUT_CFG_ID_DEVIDS,      0x03
.set VIRTIO_INPUT_CFG_PROP_BITS,      0x10
.set VIRTIO_INPUT_CFG_EV_BITS,        0x11
.set VIRTIO_INPUT_CFG_ABS_INFO,       0x12

.text

# Initializes the virtio io devices
#
# Arguments
#   a0: virtio base address
#   a1: virtio irq
virtio_init:
  push  ra
  push  s0
  push  s1

  # Keep track of virtio base address/irq
  move  s0, a0
  move  s1, a1

  # Read magic value
  move  a0, s0
  li    a1, VIRTIO_MMIO_MAGIC_VALUE
  jal   virtio_read

  # Check
  li  t0, MAGIC_VALUE
  bne a0, t0, _virtio_init_exit

  # Read version value
  move  a0, s0
  li    a1, VIRTIO_MMIO_VERSION
  jal   virtio_read

  # Check resulting version
  li  t0, 0x2
  bgt a0, t0, _virtio_init_exit

  # Read device ID
  move  a0, s0
  li    a1, VIRTIO_MMIO_DEVICE_ID
  jal   virtio_read

  # If it is a console, initialize it
  li    t0, 0x3
  bne   a0, t0, _virtio_init_check_input
  move  a0, s0
  move  a1, s1
  jal   virtio_init_console

_virtio_init_check_input:
  # If it is an device, initialize it
  li    t0, 0x12
  bne   a0, t0, _virtio_init_exit
  move  a0, s0
  move  a1, s1
  jal   virtio_init_input

_virtio_init_exit:

  # return
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Initializes the console virtio device
#
# Arguments
#   a0: device base address
#   a1: device irq
virtio_init_console:
  push  ra
  push  s0
  push  s1

  move  s0, a0
  move  s1, a1

  # Set ACKNOWLEDGE (bit 0) and DRIVER (bit 1)
  move  a0, s0
  li    a1, VIRTIO_MMIO_STATUS
  li    a2, 0b0011
  jal   virtio_write

  # Select queue 0
  move  a0, s0
  li    a1, VIRTIO_MMIO_QUEUE_SEL
  li    a2, 0
  jal   virtio_write

  # Tell the console driver
  move  a0, s0
  move  a1, s1
  jal   console_init

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Initializes a virtio input device
#
# Arguments
#   a0: device base address
#   a1: device irq
virtio_init_input:
  push  ra
  push  s0
  push  s1
  push  s2
  push  s3
  push  s4

  # Keep track of virtio base address
  move  s0, a0
  move  s1, a1

  # Read name

  # 1. Query for the name
  move  a0, s0
  li    a1, VIRTIO_MMIO_CONFIG
  li    a2, VIRTIO_INPUT_CFG_ID_NAME
  jal   virtio_write

  # 2. Get the name's length
  move  a0, s0
  li    a1, VIRTIO_MMIO_CONFIG
  add   a1, a1, 2
  jal   virtio_read
  move  s3, a0
  add   s3, s3, 8

  # 3. Read the string (starting from byte 8)
  li    s4, 8
  la    s2, virtio_string_buffer

_virtio_init_input_read_name_loop:
  move  a0, s0
  li    a1, VIRTIO_MMIO_CONFIG
  add   a1, a1, s4
  jal   virtio_read
  sw    a0, 0(s2)
  add   s2, s2, 4
  add   s4, s4, 4
  ble   s4, s3, _virtio_init_input_read_name_loop

  # 4. Shorten the name
  la    s2, virtio_string_buffer
  add   s3, s3, -8
  add   s2, s2, s3  
  sb    zero, 0(s2)

  # The name is within 'virtio_string_buffer' and we can react
  la    a0, virtio_string_buffer
  la    a1, virtio_input_device_keyboard
  li    a2, 16
  jal   strncmp

  bnez  a0, _virtio_init_input_check_mouse
  move  a0, s0
  move  a1, s1
  jal   keyboard_init

_virtio_init_input_check_mouse:
  la    a0, virtio_string_buffer
  la    a1, virtio_input_device_mouse
  li    a2, 12
  jal   strncmp

  bnez  a0, _virtio_init_input_check_tablet
  move  a0, s0
  #jal   tablet_init

_virtio_init_input_check_tablet:
  la    a0, virtio_string_buffer
  la    a1, virtio_input_device_tablet
  li    a2, 13
  jal   strncmp

  bnez  a0, _virtio_init_input_exit
  move  a0, s0
  #jal   tablet_init

_virtio_init_input_exit:

  pop   s4
  pop   s3
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Pings the device to say it is ready.
#
# VirtIO Documentation: Writing one (0x1) to this register notifies the device that it can execute requests from this virtual queue. Reading from this register returns the last value written to it. Both read and write accesses apply to the queue selected by writing to QueueSel.
#
# Arguments
#   a0: device base address
virtio_queue_ready:
  push  ra

  li    a1, VIRTIO_MMIO_QUEUE_READY
  li    a2, 0x1
  jal   virtio_write

  pop   ra
  jr    ra

# Selects a particular queue index.
#
# Arguments
#   a0: device base address
#   a1: queue index
virtio_queue_select:
  push  ra

  move  a2, a1
  li    a1, VIRTIO_MMIO_QUEUE_SEL
  jal   virtio_write

  pop   ra
  jr    ra

# Notifies the host that the given queue should be processed.
#
# VirtIO Documentation: Writing a queue index to this register notifies the device that there are new buffers to process in the queue.
#
# Arguments
#   a0: device base address
#   a1: the queue that is ready
virtio_queue_notify:
  push  ra

  li    a1, VIRTIO_MMIO_QUEUE_NOTIFY
  li    a2, 0x1
  jal   virtio_write

  pop   ra
  jr    ra

# Sets the descriptor of this queue to the given address.
#
# VirtIO Documentation: Writing to these two registers (lower 32 bits of the address to QueueDescLow, higher 32 bits to QueueDescHigh) notifies the device about location of the Descriptor Table of the queue selected by writing to QueueSel register.
#
# Arguments
#   a0: device base address
#   a1: descriptor address
virtio_queue_set_descriptor:
  push  ra
  push  s0
  push  s1

  move  s0, a0
  move  s1, a1

  # Convert to physical addresses
  move  a0, s1
  jal   paging_vaddr_to_paddr
  move  s1, a0

  move  a0, s0
  li    a1, VIRTIO_MMIO_QUEUE_DESC_LOW
  move  a2, s1
  jal   virtio_write

  move  a0, s0
  li    a1, VIRTIO_MMIO_QUEUE_DESC_HIGH
  move  a2, s1
  srl   a2, a2, 32
  jal   virtio_write

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Sets the available list of this queue to the given address.
#
# VirtIO Documentation:
#
# Arguments
#   a0: device base address
#   a1: available list address
virtio_queue_set_available:
  push  ra
  push  s0
  push  s1

  move  s0, a0
  move  s1, a1

  # Convert to physical addresses
  move  a0, s1
  jal   paging_vaddr_to_paddr
  move  s1, a0

  move  a0, s0
  li    a1, VIRTIO_MMIO_QUEUE_AVAIL_LOW
  move  a2, s1
  jal   virtio_write

  move  a0, s0
  li    a1, VIRTIO_MMIO_QUEUE_AVAIL_HIGH
  move  a2, s1
  srl   a2, a2, 32
  jal   virtio_write

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Sets the used list of this queue to the given address.
#
# VirtIO Documentation:
#
# Arguments
#   a0: device base address
#   a1: used list address
virtio_queue_set_used:
  push  ra
  push  s0
  push  s1

  move  s0, a0
  move  s1, a1

  # Convert to physical addresses
  move  a0, s1
  jal   paging_vaddr_to_paddr
  move  s1, a0

  move  a0, s0
  li    a1, VIRTIO_MMIO_QUEUE_USED_LOW
  move  a2, s1
  jal   virtio_write

  move  a0, s0
  li    a1, VIRTIO_MMIO_QUEUE_USED_HIGH
  move  a2, s1
  srl   a2, a2, 32
  jal   virtio_write

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Gets the size of the queue
#
# VirtIO Documentation:
#
# Arguments
#   a0: device base address
#
# Returns
#   a0: the queue size in entries
virtio_queue_size:
  push  ra

  # Read queue size register
  li    a1, VIRTIO_MMIO_QUEUE_NUM
  jal   virtio_read

  pop   ra
  jr    ra

# Initializes the given descriptor
#
# Arguments
#   a0: address of descriptor
virtio_descriptor_init:
  li    t0, 0x0
  sd    t0, 0(a0)
  sd    t0, 8(a0)

  jr    ra

# Sets the address of the queue for the given descriptor
#
# Arguments
#   a0: address of descriptor
#   a1: address of queue
virtio_descriptor_set_address:
  push  ra
  push  s0
  push  s1

  move  s0, a0
  move  s1, a1

  # Convert to physical addresses
  move  a0, s1
  jal   paging_vaddr_to_paddr
  move  s1, a0

  sd    s1, 0(s0)

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Sets the queue length of the given descriptor
#
# Arguments
#   a0: address of descriptor
#   a1: value
virtio_descriptor_set_length:
  sw    a1, 8(a0)

  jr    ra

# Sets the queue write-allowed flag of the given descriptor
#
# Arguments
#   a0: address of descriptor
#   a1: value
virtio_descriptor_set_write:
  # Set the 2nd bit of the flags field, if given by the value
  lhu   t0, 12(a0)
  and   t1, a1, 0x1
  sll   t1, t1, 1
  or    t0, t0, t1
  sw    t0, 12(a0)

  jr    ra

# Initializes the given available list
#
# Arguments
#   a0: address of available list
virtio_available_init:
  li    t0, 0x0
  sd    t0, 0(a0)
  sd    t0, 8(a0)

  jr    ra

# Initializes the given used list
#
# Arguments
#   a0: address of used list
virtio_used_init:
  li    t0, 0x0
  sd    t0, 0(a0)
  sd    t0, 8(a0)

  jr    ra

# Reads a virtio register given an address and register offset.
#
# Arguments
#   a0: device base address
#   a1: register
#
# Returns
#   a0: value reported by device
virtio_read:
  add   t0, a0, a1
  lw    a0, 0(t0)

  jr    ra

# Writes a value to a virtio register given an address and register offset.
#
# Arguments
#   a0: device base address
#   a1: register
#   a2: value to write
virtio_write:
  add   t0, a0, a1
  sw    a2, 0(t0)
  jr    ra

# virtio_ack_interrupt(virtio_base_addr) - Acks the interrupt for the device.
#
# Arguments
#   a0: device base address
virtio_ack_interrupt:
  push  ra

  li    a1, VIRTIO_MMIO_INTERRUPT_ACK
  li    a2, 1
  jal   virtio_write

  pop   ra
  jr    ra

.data

# Known input devices
virtio_input_device_keyboard: .string "virtio_keyboard"
virtio_input_device_mouse:    .string "virtio_mouse"
virtio_input_device_tablet:   .string "virtio_tablet"

# String buffer for parsing device names, etc
virtio_string_buffer: .string "                          "
