# This contains the stack memory. We only have a little bit!

.include "const.s"
.include "util.s"

.global stack_init
.global stack_map

# Stack memory pointers
.global stack
.global trap_stack

.text

# stack_init(): Sets up and enables the stack.
stack_init:
  la    sp, stack
  jr    ra

# stack_map(root_page_table): Maps in the application stack.
#
# Arguments:
#   a0: The root page table address.
stack_map:
  push  ra
  push  s0
  push  s1

  # s0 will retain the root page table
  move  s0, a0

  # We will compute the physical address of the stack
  la    s1, app_stack
  la    t0, _start
  sub   s1, s1, t0
  jal   fdt_get_memory_base_addr
  add   s1, s1, a0

  # Move root table address and physical address of stack to arguments
  move  a0, s0
  move  a1, s1
  # We will map the stack to this userspace virtual address:
  li    a2, 0xfffff000
  # It will be accessible to userspace and readonly
  li    a3, PTE_USER | PTE_READ | PTE_WRITE
  # Engage
  jal   paging_map

  pop   s1
  pop   s0
  pop   ra
  jr    ra

.data

# Allocate a 4KiB trap stack.
# It is certainly bad if we use it all!!
# (We could protect the region around the stack later, if we want)
.balign 4096, 0
.fill 1024, 4, 0
trap_stack:

# Allocate a 4KiB syscall stack.
# It is still certainly bad if we use it all!!
.balign 4096, 0
.fill 1024, 4, 0
stack:

# Allocate a 4KiB user stack.
# It is still certainly bad if we use it all!!
.balign 4096, 0
.fill 1024, 4, 0
app_stack:
