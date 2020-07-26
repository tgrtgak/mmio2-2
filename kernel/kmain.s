# This includes the boot initialization and the poweroff (exit) routines.

.include "const.s"
.include "util.s"

.global kmain
.global abort
.global exit

.set HTIF_BASE,   (MEM_BASE + 0x40008000)

.text

# kmain(): The main function of our kernel.
#
# The stuff in start.s happened first, but this is truly the runtime
# initialization of the kernel proper.
kmain:
  # establish a stack
  jal   stack_init

  # establish traps
  jal   trap_init

  li s9, 0

  # Read the FDT
  jal   fdt_read

  # Initialize Interrupt Controller
  jal   fdt_get_plic_base_addr
  li    t0, MEM_BASE
  add   a0, a0, t0
  jal   irq_init

  # The age-old question of the chicken or egg:
  # What comes first, your memory manager, or your ability to print
  # strings? Tricky.

  # Initialize the virtio devices
  jal   fdt_get_virtio_count
  move  s1, a0
  li    s0, 0

_kmain_virtio_init_loop:
  move  a0, s0
  jal   fdt_get_virtio_irq
  move  a1, a0
  move  a0, s0
  jal   fdt_get_virtio_base_addr
  li    t0, MEM_BASE
  add   a0, a0, t0
  jal   virtio_init

  add   s0, s0, 1
  bne   s0, s1, _kmain_virtio_init_loop

  # Initialize the memory mapper

  # Get the memory size
  jal   fdt_get_memory_length

  # Pass that along to the memory manager
  jal   memory_init

  # Now we can build our virtual memory
  # This will create our base-case kernel page table

  # When we create application page tables, we copy this one, mostly, since it
  # contains all of the "global" page table entries. Global entries are those
  # that exist in all memory spaces.

  # Since the data structure is a tree, we can point to existing page table
  # directories that already exist, particularly if we start having more than
  # one application.
  jal   paging_init
  move  s0, a0
  jal   fdt_get_memory_base_addr
  move  a0, s0
  jal   paging_install
  jal   fdt_get_memory_base_addr

  # Initialize the Real-Time Clock (via the CLINT)
  # Get the CLINT MMIO Address
  jal   fdt_get_clint_base_addr
  li    t0, MEM_BASE
  add   a0, a0, t0
  jal   rtc_init

  # Create a userspace page table
  # (Optional)

  # Get the root page table
  # s0: The root page table address
  jal   paging_get_root
  move  s0, a0

  # Map in keyboard driver memory
  move  a0, s0
  jal   keyboard_map

  # Initialize the framebuffer device
  jal   fdt_get_framebuffer_base_addr
  move  s1, a0
  jal   fdt_get_framebuffer_width
  move  s2, a0
  jal   fdt_get_framebuffer_height
  move  s3, a0

  move  a0, s1
  move  a1, s2
  move  a2, s3
  jal   framebuffer_init

  # Map in framebuffer
  move  a0, s0
  jal   framebuffer_map

  # Map in user stack
  move  a0, s0
  jal   stack_map

  # Clear/Enable interrupts
  jal trap_clear_interrupts
  jal trap_enable_interrupts

  # Load the application
  jal   fdt_get_application_base_addr
  li    t0, MEM_BASE
  add   a0, a0, t0
  move  a1, s0
  jal   elf_load

  # Execute the application

  # a0: The virtual address of the first instruction of our program

  # Set SRET destination to this program address
  csrw  sepc, a0

  # Zero every register
  move  x0,  zero
  move  x1,  zero
  move  x2,  zero
  move  x3,  zero
  move  x4,  zero
  move  x5,  zero
  move  x6,  zero
  move  x7,  zero
  move  x8,  zero
  move  x9,  zero
  move  x10, zero
  move  x11, zero
  move  x12, zero
  move  x13, zero
  move  x14, zero
  move  x15, zero
  move  x16, zero
  move  x17, zero
  move  x18, zero
  move  x19, zero
  move  x20, zero
  move  x21, zero
  move  x22, zero
  move  x23, zero
  move  x24, zero
  move  x25, zero
  move  x26, zero
  move  x27, zero
  move  x28, zero
  move  x29, zero
  move  x30, zero
  move  x31, zero

  # Switch to application stack
  li    sp, 0x100000000

  # sret to userspace!
  sret

  # We shouldn't get to this point :)
  j     exit

exit:
  # We write htif_tohost to be 0x80000000
  # And htif_fromhost to 1
  li    s11, HTIF_BASE

  # HTIF_TO_LOW
  li    s10, 0x0001
  sw    s10, 0(s11)
  # HTIF_TO_HIGH
  li    s10, 0x0000
  sw    s10, 4(s11)

  # The machine should power off as we get here.
  # It will loop exit just in case.
  j     exit

# Halt the CPU after some kind of unexpected problem.
abort:
  # Yanno... just... exit.
  j     exit

.data
.balign 8, 0

str_booting: .string "Booting...\n"
