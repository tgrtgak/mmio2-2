# This implements the virtio keyboard driver

# Here, we again want to read from the 'write' queue much like in the
# console.s driver (which handles printing text to the screen.)

.include "const.s"
.include "util.s"

.globl keyboard_init
.globl keyboard_read
.globl keyboard_read_line
.globl keyboard_loop
.globl keyboard_map

# The keyboard buffer size in bytes
.set KEYBOARD_BUFFER_SIZE,    64

# Some keycodes
.set KEYBOARD_CODE_BACKSPACE, 0x08
.set KEYBOARD_CODE_SHIFT,     0x10
.set KEYBOARD_CODE_CONTROL,   0x11
.set KEYBOARD_CODE_ALT,       0x12
.set KEYBOARD_CODE_CAPSLOCK,  0x14

# The keyboard events we care about
.set VIRTIO_INPUT_EV_SYN,     0x00
.set VIRTIO_INPUT_EV_KEY,     0x01

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

  # Create a buffer descriptor (event)
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
  la    t0, keyboard_event_queue_len
  sd    s1, 0(t0)

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
  add   s4, s4, KEYBOARD_BUFFER_SIZE # Go to the next buffer address

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

  pop   s3
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# keyboard_map(root_page_table): Maps in keyboard memory to userspace.
#
# Arguments:
#   a0: The root page table address.
keyboard_map:
  push  ra
  push  s0
  push  s1

  # s0 will retain the root page table
  move  s0, a0

  # We will compute the physical address of the keyboard state table
  la    s1, keyboard_state
  la    t0, _start
  sub   s1, s1, t0
  jal   fdt_get_memory_base_addr
  add   s1, s1, a0

  # Move root table address and physical address of keyboard state to arguments
  move  a0, s0
  move  a1, s1
  # We will map the table to this userspace virtual address:
  li    a2, 0x80000000
  # It will be accessible to userspace and readonly
  li    a3, PTE_USER | PTE_READ
  # Engage
  jal   paging_map

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# keyboard_create_event_buffer(desc_addr, buffer_addr): Creates event buffer.
#
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
  move  a0, s0
  li    a1, KEYBOARD_BUFFER_SIZE
  jal   virtio_descriptor_set_length

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
  push  s3

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

  # Get the number of buffers: count
  la    t0, keyboard_event_queue_len
  ld    t0, 0(t0)

  # Get the index into the ring buffer: real_index = (index % count)
  rem   t0, s1, t0

  # Get the effective address of that buffer: buffers[real_index]
  # t1: buffer = keyboard_event_queue + (real_index * KEYBOARD_BUFFER_SIZE)
  li    t1, KEYBOARD_BUFFER_SIZE
  mul   t0, t1, t0
  la    t1, keyboard_event_queue
  add   t1, t1, t0

  # Read from the buffer

  # A keyboard event is:
  # | 16 bits | 16 bits | 32 bits |
  # |  type   | keycode |  value  |

  # Read 64 bits
  ld    t0, 0(t1)

  # Read the event type
  li    t1, 0xffff
  and   t1, t0, t1
  li    t2, VIRTIO_INPUT_EV_KEY
  bne   t1, t2, _keyboard_read_loop_continue

  # This is a keyboard event.
  # Read the key code
  srl   t0, t0, 16
  li    t1, 0xffff
  and   t2, t0, t1

  # Read whether or not the key is down
  srl   t1, t0, 16

  # t1: keystate (0: released, 1: down)
  # t2: keycode

  # If keystate is something greater than 1 (strange), skip it
  li    t0, 0x1
  bgt   t1, t0, _keyboard_read_loop_continue

  # If they keycode is greater than 255, skip it
  li    t0, 0xff
  bgt   t2, t0, _keyboard_read_loop_continue

  # Save the keystate to the keystate bitmap
  la    t0, keyboard_state
  add   t0, t0, t2
  sb    t1, 0(t0)

  # If the key is an 'up' then skip the next part
  beqz  t1, _keyboard_read_loop_continue

  # If we have a line buffer active, write to it
  la    t0, keyboard_line_buffer
  ld    s3, 0(t0)
  beqz  s3, _keyboard_read_loop_continue

  # If the buffer is empty, do not write to it
  la    t0, keyboard_line_buffer_len
  ld    t0, 0(t0)
  beqz  t0, _keyboard_read_loop_continue

  # Skip if the character is not printable (translate returns 0x0)
  move  a0, t2
  jal   keyboard_translate
  beqz  a0, _keyboard_read_loop_continue

  # Write to the buffer
  sb    a0, 0(s3)

  # Decrement the buffer size
  la    t0, keyboard_line_buffer_len
  ld    t1, 0(t0)
  add   t1, t1, -1
  sd    t1, 0(t0)

  # Increment the buffer
  add   s3, s3, 1
  la    t0, keyboard_line_buffer
  sd    s3, 0(t0)

_keyboard_read_loop_continue:

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
  pop   s3
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# keyboard_read_line(buffer, max): Returns characters until it sees a newline.
#
# Arguments
#   a0: The buffer to read into.
#   a1: The maximum number of characters to read.
keyboard_read_line:
  push  ra
  push  s0
  push  s1

  # Keep track of the buffer and size
  move  s0, a0
  move  s1, a1

  # Zero buffer
  move  a0, s0
  move  a1, s1
  jal   memzero

  # Set the buffer size
  la    t0, keyboard_line_buffer_len
  sd    s1, 0(t0)

  # Set the buffer
  la    t0, keyboard_line_buffer
  sd    s0, 0(t0)

  # Wait until the buffer updates
_keyboard_read_line_loop:
  lbu   t0, 0(s0)
  beqz  t0, _keyboard_read_line_loop

  # Print out character
  move  a0, s0
  li    a1, 1
  jal   console_write

  # Decrement our buffer length so far
  add   s1, s1, -1

  # Bail if we have exhausted our buffer
  beqz  s1, _keyboard_read_line_exit

  # If character is a newline, exit
  lbu   t0, 0(s0)
  li    t1, '\n'
  beq   t0, t1, _keyboard_read_line_found_newline

  # Increment the buffer
  add   s0, s0, 1

  j _keyboard_read_line_loop

_keyboard_read_line_found_newline:
  # Replace newline with null terminator
  li    t0, 0
  sb    t0, 0(s0)

  # Continue to exit

_keyboard_read_line_exit:
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# keyboard_translate(code): Yields the ASCII character for the given code
#
# Will respect the current key state. If shift is down, the code will be a
# capitalized letter. If the key is a number, it will translate to the US
# keyboard layout.
#
# Arguments
#   a0: The key code to translate.
keyboard_translate:
  la    t0, keyboard_state
  li    t1, KEYBOARD_CODE_SHIFT
  add   t0, t0, t1
  lbu   t1, 0(t0)

  bnez  t1, _keyboard_translate_use_shift

  la    t0, keyboard_translation_table
  j _keyboard_translate_load

_keyboard_translate_use_shift:
  la    t0, keyboard_translation_shift

_keyboard_translate_load:
  add   t0, t0, a0
  lbu   a0, 0(t0)

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

# The address to write a character into
keyboard_line_buffer:       .dword 0

# The current length of that buffer
keyboard_line_buffer_len:   .dword 0

keyboard_translation_table: .fill  0x0d, 1, 0
                            .byte  '\n'            # Enter (0x0d)
                            .fill  0x12, 1, 0
                            .byte  ' '             # Space (0x20)
                            .fill  0x0f, 1, 0
                            .ascii "0123456789"    # Numerics (0x30..0x39)
                            .fill  0x07, 1, 0
                            .ascii "abcdefghijklm" # Alphas (0x41..0x5a)
                            .ascii "nopqrstuvwxyz"
                            .fill  0x05, 1, 0
                            .ascii "0123456789*+"  # Numpad (0x60..0x6f)
                            .fill  0x01, 1, 0
                            .ascii "-./"
                            .fill  0x4a, 1, 0
                            .ascii ";=,-./`"       # Symbols 1 (0xba..0xc0)
                            .fill  0x1a, 1, 0
                            .ascii "[\\]'"         # Symbols 2 (0xdb..0xde)

keyboard_translation_shift: .fill  0x0d, 1, 0
                            .byte  '\n'            # Enter (0x0d)
                            .fill  0x12, 1, 0
                            .byte  ' '             # Space (0x20)
                            .fill  0x0f, 1, 0
                            .ascii ")!@#$%^&*("    # Numerics (0x30..0x39)
                            .fill  0x07, 1, 0
                            .ascii "ABCDEFGHIJKLM" # Alphas (0x41..0x5a)
                            .ascii "NOPQRSTUVWXYZ"
                            .fill  0x05, 1, 0
                            .ascii "0123456789*+"  # Numpad (0x60..0x6f)
                            .fill  0x01, 1, 0
                            .ascii "-./"
                            .fill  0x4a, 1, 0
                            .ascii ":+<_>?~"       # Symbols 1 (0xba..0xc0)
                            .fill  0x1a, 1, 0
                            .ascii "{|}\""         # Symbols 2 (0xdb..0xde)

.balign 8, 0
# VirtIO base address
keyboard_virtio_addr:      .dword  0

# VirtIO event queue
# This will be split up into a bunch of buffers
.balign 4096, 0
keyboard_event_queue:      .fill   1024, 1, 0
                           .fill   1024, 1, 0
keyboard_event_queue_len:  .dword  0

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

# The keyboard state will be a page in memory mapped to userspace
# It will be a bytemap of all keycodes. A '1' when they are pressed.
.balign 4096, 0
keyboard_state:            .fill   1024, 1, 0
.balign 4096, 0
