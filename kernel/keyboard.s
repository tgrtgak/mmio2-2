# This implements the virtio keyboard driver

# Here, we again want to read from the 'write' queue much like in the
# console.s driver (which handles printing text to the screen.)

.include "const.s"
.include "util.s"

.globl keyboard_init
.globl keyboard_read
.globl keyboard_loop

.text

# Initializes the keyboard device
#
# Arguments
#   a0: The virtio device address
keyboard_init:
  push  ra
  push  s0
  push  s1
  push  s2
  push  s3

  move  s0, a0

  # Register the irq handler
  move  a0, a1
  la    a1, keyboard_irq_resolve
  jal   irq_register

  # Retain the virtio address of this device
  la    t0, keyboard_virtio_addr
  sd    s0, 0(t0)

  # Get the number of entries in the event queue

  # Select the first queue (event queue)
  move  a0, s0
  li    a1, 0
  jal   virtio_queue_select

  # Create a buffer descriptor (write)
  la    a0, keyboard_event_descriptor
  jal   keyboard_descriptor_init

  # Create the available list (event)
  la    a0, keyboard_event_available
  jal   virtio_available_init

  # Set the available list
  move  a0, s0
  la    a1, keyboard_event_available
  jal   virtio_queue_set_available

  # Create the used list (event)
  la    a0, keyboard_event_used
  jal   virtio_used_init

  # Set the used list
  move  a0, s0
  la    a1, keyboard_event_used
  jal   virtio_queue_set_used

  # Read value (number of entries in queue)
  move  a0, s0
  jal   virtio_queue_size
  move  s1, a0

  # We need to allocate those buffers
  # s1: The number of entries in the queue
  # s2: The current address of the buffer descriptor
  # s3: counter
  # s4: The address of the buffer
  la    s2, keyboard_event_descriptor
  li    s3, 0
  la    s4, keyboard_event_queue

_keyboard_init_buffer_allocation_loop:
  move  a0, s2
  move  a1, s4
  jal   keyboard_create_event_buffer

  # Add buffers to available list
  la    t0, keyboard_event_available
  add   t0, t0, 4  # Navigate to the buffer list
  add   t0, t0, s3 
  add   t0, t0, s3 # Navigate to buffers[s3] (each is 2 bytes)
  sh    s3, 0(t0)  # keyboard_event_available->buffers[s3] = s3

  add   s3, s3, 1  # Increment counter
  add   s2, s2, 16 # Each buffer descriptor header is 16 bytes
  add   s4, s4, 64 # Each buffer is 64 bytes

  # Loop until we allocated the same number of buffers as the device's queue
  bne   s3, s1, _keyboard_init_buffer_allocation_loop

  # Update available index and report the buffers
  la    t0, keyboard_event_available
  sh    s1, 2(t0)

  # Set the descriptor for this queue
  move  a0, s0
  la    a1, keyboard_event_descriptor
  jal   virtio_queue_set_descriptor

  # Queue is ready (event)
  move  a0, s0
  jal   virtio_queue_ready

  # Notify device of change
  move  a0, s0 # keyboard_virtio_addr
  li    a1, 0  # queue 0 (event queue)
  jal   virtio_queue_notify

  # TODO: status queue
_foo:
#j _foo

  pop   s3
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Arguments:
#   a0: descriptor address
#   a1: buffer address
keyboard_create_event_buffer:
  push  ra
  push  s0
  push  s1

  move  s0, a0
  move  s1, a1

  # Allow the device to write to this buffer
  move  a0, s0
  li    a1, 0x1
  jal   virtio_descriptor_set_write

  # Store the buffer address  
  move  a0, s0
  move  a1, s1
  jal   virtio_descriptor_set_address

  # Update the buffer length
  move  t0, s1
  li    t1, 64
  sw    t1, 8(t0)

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# Arguments
#   a0: descriptor address
keyboard_descriptor_init:
  push  ra
  push  s0

  # Keep track of the descriptor address
  move  s0, a0

  # Load the queue descriptor (zero it)
  jal   virtio_descriptor_init

  pop   s0
  pop   ra
  jr    ra

keyboard_read:
  push  ra
  push  s0
  push  s1
  push  s2

  # We keep looping until we have read every buffer
_keyboard_read_query_loop:

  # read used index
  la    t0, keyboard_event_used
  lh    s2, 2(t0)

  # and the last index we read last time
  la    t0, keyboard_last_index
  ld    s1, 0(t0)

  # If they are the same, no new data
  beq   s1, s2, _keyboard_read_exit

  # Get the difference
  # The new index will always be larger
  sub   s0, s2, s1

  # s0: The number of buffers to read
  # s1: The index of the buffer to read
  # s2: The index of the next buffer in the used list

  # Look at the buffers from last_index to used_index
_keyboard_read_loop:

  # Read the buffer at that index
  # s1: index of the buffer
  print_hex s1

  add   s1, s1, 1
  add   s0, s0, -1
  bnez  s0, _keyboard_read_loop

  # Increment avail by the buffers read
  la    t0, keyboard_last_index
  ld    s1, 0(t0)
  sub   s0, s2, s1
  la    t0, keyboard_event_available
  lhu   t1, 2(t0)
  add   t1, t1, s0
  sh    t1, 2(t0)

  # Save last index as the used index
  la    t1, keyboard_last_index
  sd    s2, 0(t1)

  # Look back to catch any other buffers
  j     _keyboard_read_query_loop

_keyboard_read_exit:
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

keyboard_irq_resolve:
  push  ra

  # Read
  jal   keyboard_read

  # ACK the interrupt
  la    a0, keyboard_virtio_addr
  ld    a0, 0(a0)
  jal   virtio_ack_interrupt

  pop   ra
  jr    ra

.data

.balign 8, 0
# VirtIO base address
keyboard_virtio_addr:      .dword  0

# VirtIO event queue
# This will be split up into a bunch of buffers
.balign 4096, 0
keyboard_event_queue:      .fill   1024, 1, 0
                           .fill   1024, 1, 0
keyboard_event_queue_len:  .word   1024

# VirtIO queue descriptors (event)
.balign 4096, 0
keyboard_event_descriptor: .fill   16, 1, 0
                           .fill   16, 1, 0

.balign 4096, 0
keyboard_event_available:  .fill   10, 1, 0

.balign 4096, 0
keyboard_event_used:       .fill   22, 1, 0

.balign 4096, 0
keyboard_last_index:       .dword  0
