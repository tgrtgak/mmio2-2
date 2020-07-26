# This wraps the framebuffer device.

# The framebuffer is a section of memory mapped to the display adapter. It
# controls what is on the screen.

.include "const.s"
.include "util.s"

.globl framebuffer_init
.globl framebuffer_map

# framebuffer_init(addr, width, height): Initializes the framebuffer device.
#
# Arguments
#   a0: The base address for the framebuffer.
#   a1: The width, in pixels, of the framebuffer.
#   a2: The height, in pixels, of the framebuffer.
framebuffer_init:
  # Retain all arguments
  la    t0, framebuffer_addr
  sd    a0, 0(t0)

  la    t0, framebuffer_width
  sd    a1, 0(t0)

  la    t0, framebuffer_height
  sd    a2, 0(t0)

  # Calculate the length of the framebuffer
  # Each pixel is a8r8g8b8 (32-bits)
  move  t0, a1
  mul   t0, t0, a2
  sll   t0, t0, 2   # t0 = width * height * 4

  # Store it
  la    t1, framebuffer_length
  sd    t0, 0(t1)

  jr    ra

# framebuffer_map(root_page_table): Maps the framebuffer to the address space.
#
# Arguments:
#   a0: The root page table address.
framebuffer_map:
  push  ra

  # Map the framebuffer to userspace.
  # a0 is already the root page table address
  # a1 will be the physical address of the framebuffer
  la    t0, framebuffer_addr
  ld    a1, 0(t0)
  # We will map the framebuffer to this userspace virtual address
  li    a2, 0x90000000
  # The number of bytes is the length
  la    t0, framebuffer_length
  ld    a3, 0(t0)
  # It will be read-writable to userspace
  li    a4, PTE_USER | PTE_READ | PTE_WRITE
  # Engage
  jal   paging_map_range

  pop   ra
  jr    ra

.data

framebuffer_length:     .dword 0
framebuffer_width:      .dword 0
framebuffer_height:     .dword 0
framebuffer_addr:       .dword 0
