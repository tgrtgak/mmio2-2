# This file maps in MMIO plugin devices

.include "const.s"
.include "util.s"

.global mmio_map

# mmio_map(root page table, base address, length)
mmio_map:
  push  ra
  push  s0

  # Retain the length
  move  s0, a2

  # a0 is the root page table
  # a1 is the base address
  # a2 will be the virtual address, which is the same as the base
  move  a2, a1
  # a3 is the length
  move  a3, s0
  # a4 is the flags
  li    a4, PTE_USER | PTE_READ | PTE_WRITE
  # Engage
  jal   paging_map_range

  pop   s0
  pop   ra
  jr    ra
