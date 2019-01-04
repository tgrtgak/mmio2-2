# The entrypoint (first instruction) for the boot loader and kernel.

.include "const.s"

.global start

.text

# start(): Gets up from power on to a workable state
start:
  # We need to set up a paging structure for the rest of the boot
  # That is, we need to load the kernel

  # Our kernel will be in high memory (0xffff8000_00000000)

  # That address is due to the virtual memory space being 48-bits. All addresses
  # referring to the kernel will be 'negative' in that their first bits are 1.

  # This is nice because all userspace addresses can be 'positive' to quickly
  # distinguish them, but also, both userspace and kernel space can make use of
  # sign-extending immediates when acting upon its memory space. This is called a
  # 'kernel' memory model in systems like Linux.
  la    t0, boot_pdpt
  srli  t0, t0, PAGE_OFFSET
  li    t1, SATP_SV48
  or    t0, t0, t1
  csrw  satp, t0

  # We then need to go to 'supervisor' mode
  csrr  t0, mstatus
  li    t1, MSTATUS_MPP_CLEAR
  and   t0, t0, t1
  li    t1, MODE_SUPERVISOR
  sll   t1, t1, MSTATUS_MPP_OFFSET
  or    t0, t0, t1

  # Also, we want to set the SUM bit in mstatus. This lets supervisor mode
  # read USER-mode pages. (for system calls and such)
  li    t1, 1
  sll   t1, t1, MSTATUS_SUM_OFFSET
  or    t0, t0, t1
  csrw  mstatus, t0

  # All traps happen in 'supervisor' mode and not machine mode
  li    t0, -1
  csrw  mideleg, t0
  csrw  medeleg, t0

  # Calculate the address of 'kmain'
  li    t0, KERN_BASE
  la    t1, kmain
  la    t2, start
  sub   t1, t1, t2  # addr = kmain - start
  add   t1, t1, t0  # addr = addr  + KERN_BASE
  csrw  mepc, t1

  # "Return" to Supervisor mode (call kmain)
  mret

# Page Directory Page Table (PDPT) for the kernel

# We just need the simple stuff to map in our kernel memory space.

# It is really fun to have a self-referencing page table. And it makes lots
# of stuff a bit easier, honestly. But, RISC-V can't properly do it since PTEs
# (Page Table Entries) cannot both point to tables (inodes) AND leaves (actual
# physical pages)
.balign(4096 * 4)
boot_pdpt:
  # Lots of empty space for unmapped entries
  .space (PTE_SIZE * 256) # 256 empty entries!

  # Entry for 0xffff800000000000
  # This points to our kernel's code and data
  # (which is at physical address 0x80000000)
  # This is a super page, which means it maps the entire 512 GiB range to the
  # kernel. (which is all of RAM)

  # We are mapping 0xffff800000000000 -> physical 0x00000000 (where RAM starts)
  .dword (0x00000000 >> PAGE_OFFSET << PTE_PPN_OFFSET) + (PTE_VALID | PTE_EXECUTE | PTE_WRITE | PTE_READ | PTE_GLOBAL)

  .space (PTE_SIZE * 254) # Lots of empty entries

  # Another mapping of the system memory
  .dword (0x00000000 >> PAGE_OFFSET << PTE_PPN_OFFSET) + (PTE_VALID | PTE_WRITE | PTE_READ | PTE_GLOBAL)
