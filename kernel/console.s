# The VirtIO console character device driver.

# The Console VirtIO driver in TinyEMU expects queue 0 to be the write queue
# and queue 1 to be the read queue.
#
# This can be confusing. It is from the host's perspective. We write to queue
# 1, which will be read by the emulator and fed to the terminal. We read from
# queue 0.
#
# We are only going to have a single descriptor for each direction. That is,
# a single queue for read and a single queue for write. Again, *we* write to
# the read queue (device-perspective.) Each queue having just a single buffer.

# Although, we probably want at least two buffers...

# The TinyEmu console device wants queues of at least 8 to 16 entries. Normally
# you would ask the host how big the ring buffers and queues are but we will
# just presume because our dynamic memory abilities are fairly weak. :)

.include "const.s"
.include "util.s"

.globl console_init
.globl console_writez
.globl console_write
.globl console_read

.text

# Initializes the console device
#
# Arguments
#   a0: The virtio device address.
#   a1: The irq for this
console_init:
  push  ra
  push  s0

  move  s0, a0

  # Register irq handler
  move  a0, a1
  la    a1, console_irq_resolve
  jal   irq_register

  # Retain the virtio address of this console
  la    t0, console_virtio_addr
  sd    s0, 0(t0)

  # Select the first queue (write queue)
  move  a0, s0
  li    a1, 0
  jal   virtio_queue_select

  # Create a buffer descriptor (write)
  la    a0, console_write_descriptor
  la    a1, console_write_queue
  jal   console_descriptor_init

  # Allow the device to write to this buffer
  la    a0, console_write_descriptor
  li    a1, 0x1
  jal   virtio_descriptor_set_write

  # Set the descriptor
  move  a0, s0
  la    a1, console_write_descriptor
  jal   virtio_queue_set_descriptor

  # Create the available list (write)
  la    a0, console_write_available
  jal   virtio_available_init

  # Set the available list
  move  a0, s0
  la    a1, console_write_available
  jal   virtio_queue_set_available

  # Create the used list (write)
  la    a0, console_write_used
  jal   virtio_used_init

  # Set the used list
  move  a0, s0
  la    a1, console_write_used
  jal   virtio_queue_set_used

  # Queue is ready (write)
  move  a0, s0
  jal   virtio_queue_ready

  # Select the second queue (read queue)
  move  a0, s0
  li    a1, 1
  jal   virtio_queue_select

  # Create a descriptor (read)
  la    a0, console_read_descriptor
  la    a1, console_read_queue
  jal   console_descriptor_init

  # Set the descriptor
  move  a0, s0
  la    a1, console_read_descriptor
  jal   virtio_queue_set_descriptor

  # Create the available list (read)
  la    a0, console_read_available
  jal   virtio_available_init

  # Set the available list
  move  a0, s0
  la    a1, console_read_available
  jal   virtio_queue_set_available

  # Create the used list (read)
  la    a0, console_read_used
  jal   virtio_used_init

  # Set the used list
  move  a0, s0
  la    a1, console_read_used
  jal   virtio_queue_set_used

  # Queue is ready (read)
  move  a0, s0
  jal   virtio_queue_ready

  pop   s0
  pop   ra
  jr    ra

# Writes to the console a zero-terminated string.
#
# Arguments
#   a0: string to write
console_writez:
  push  ra
  push  s0

  # Retain a0
  move  s0, a0

  # Get the length of the string
  jal   strlen
  
  # Call the proper function
  move  a1, a0 # a1 is the length of the string
  move  a0, s0 # a0 is the original string adress
  jal   console_write

  pop   s0
  pop   ra
  
  jr    ra

# Writes to the console the given string.
#
# Arguments
#   a0: string to write
#   a1: length of string
console_write:
  push  ra
  push  s0
  push  s1

  move  s1, a1
  move  a2, a1
  move  a1, a0

  # Get the virtio address of this console
  la    t0, console_virtio_addr
  ld    s0, 0(t0)

  # Write the data to the read queue
  la    a0, console_read_queue
_console_write_strcpy:
  blez  a2, _console_write_strcpy_done
  lbu   t0, 0(a1)
  sb    t0, 0(a0)
  add   a2, a2, -1
  add   a0, a0, 1
  add   a1, a1, 1
  # Also append a carriage return with a newline
  li    t1, '\n'
  bne   t0, t1, _console_write_strcpy
  li    t0, '\r'
  sb    t0, 0(a0)
  add   a0, a0, 1
  add   s1, s1, 1 # Increment the buffer size
  j     _console_write_strcpy
_console_write_strcpy_done:

  # Update the buffer length
  la    t0, console_read_descriptor
  sw    s1, 8(t0)

  # Add buffer to available list
  la    t0, console_read_available
  sh    zero, 4(t0)

  # Update available index to point to following one
  la    t0, console_read_available
  lhu   t1, 2(t0)
  add   t1, t1, 1
  sh    t1, 2(t0)

  # Notify device of change
  move  a0, s0 # console_virtio_addr
  li    a1, 1  # queue 1 (read queue)
  jal   virtio_queue_notify

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Reads console input to the given buffer.
#
# Arguments
#   a0: address of the buffer
#   a1: maximum length of string
console_read:
  push  ra
  push  s0

  # Get the virtio address of this console
  la    t0, console_virtio_addr
  ld    s0, 0(t0)

  # Check for updates (you'll want an interrupt, usually)
  # (particularly, the length of the buffer)

  # Wait until queue notifies it has data

  # Read the data

  # Reset queue/buffer

  # Loop back until we meet the conditions

  pop   s0
  pop   ra
  jr    ra

# Arguments
#   a0: descriptor address
#   a1: buffer address
console_descriptor_init:
  push  ra
  push  s0
  push  s1

  # Keep track of the descriptor address
  move  s0, a0
  move  s1, a1

  # Load the queue descriptor (zero it)
  jal   virtio_descriptor_init

  # Store the buffer address  
  move  a0, s0
  move  a1, s1
  jal   virtio_descriptor_set_address

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# console_irq() - Handles the console notify irq.
console_irq_resolve:
  push  ra

  # ACK the interrupt
  la    a0, console_virtio_addr
  ld    a0, 0(a0)
  jal   virtio_ack_interrupt

  pop   ra
  jr    ra

.data

.balign 8, 0
# VirtIO base address
console_virtio_addr:      .dword  0

# VirtIO write queue
.balign 4096, 0
console_write_queue:      .fill   1024, 1, 0
                          .fill   1024, 1, 0
console_write_queue_len:  .word   1024

# VirtIO read queue
.balign 4096, 0
console_read_queue:       .fill   1024, 1, 0
                          .fill   1024, 1, 0
console_read_queue_len:   .word   1024

# VirtIO queue descriptors (write)
.balign 4096, 0
console_write_descriptor: .fill   16, 1, 0
                          .fill   16, 1, 0

.balign 4096, 0
console_write_available:  .fill   10, 1, 0

.balign 4096, 0
console_write_used:       .fill   22, 1, 0

# VirtIO queue descriptors (read)
.balign 4096, 0
console_read_descriptor:  .fill   16, 1, 0
                          .fill   16, 1, 0

.balign 4096, 0
console_read_available:   .fill   10, 1, 0

.balign 4096, 0
console_read_used:        .fill   22, 1, 0

.balign 4096, 0
