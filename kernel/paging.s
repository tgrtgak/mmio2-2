# This file manages virtual memory and paging.

.include "const.s"
.include "util.s"

.global paging_init
.global paging_map
.global paging_map_range
.global paging_install
.global paging_get_root
.global paging_vaddr_to_paddr

.text

# paging_init(): Instantiates virtual memory for the system.
paging_init:
  push ra
  push s0

  # We will get rid of the initial page table we have for a more versatile one.

  # First, we create a new root page table.
  jal   paging_create_root
  move  s0, a0

  # s0: Our root page table

  # Now, we want to map in kernel space.
  # The kernel memory space starts at MEM_BASE.

  # For our kernel itself, we should map in from our _start to _end (and point
  # to memory base)
  # (TODO: do we have to adjust for weird memory bases where the kernel doesn't
  # start at byte 0?)

  # What is interesting is that we will allocate pages as we map the kernel
  # into memory. Which means, we need to map those pages in as well. Egads!

  # That means, we have to map in our kernel... repeatedly... until nothing
  # changes.

  # Another interesting dilemma is the mapping in of page tables as we create
  # them. One elegant solution is to use a self-referencing page table. This is
  # a particular design where you map the last PTE of your root table to itself.

  # A self-referencing page table means that the root page table has a well-
  # known address: 0xfffffffffffffc00 (for 4K page size). All other page tables
  # are off of that one. By taking that last branch on the root table, you
  # effectively shorten the route through the translation.

  # What is the page table that handles a certain virtual address? Well, shift
  # it to the right the page level offset (9) and then throw in a 0xff1 in the
  # root level index and that will just be that!

  # The trade off is that you lose an entire section of your virtual address
  # space. But that's mostly ok. you have lots and mostly we've decided to put
  # kernel into high memory, which means we're losing tons of space for the
  # negative addresses trick (because sign extension is fun.)

  # Unfortunately, RISC-V cannot do this. It determines a PTE that points to a
  # secondary level (inode) by seeing if the READ or EXECUTE bits are set. If
  # so, it considers this PTE to point to an actual page. So, a PTE cannot refer
  # to both a secondary level and the physical page at the same time.

  # That means we need a RAM mapping at all times. When we allocate a page from
  # the page allocator, we need to craft a virtual address from the RAM device
  # range. I don't like this that much. And guess what? We still burn the same
  # amount of virtual address space.

  # We just need the RAM mapping at entry 512 to be a superpage of all RAM. A
  # superpage is when you have a leaf pointer in one of the intermediate levels
  # of the table. So, instead of using all 4 levels of the page table, which
  # would point to a 4KiB page, you are only using 3 levels or less. For three
  # levels, that would be a 2 MiB page. Two levels is a 1 GiB page. A superpage
  # off of the root, as we will do here, is a 512 GiB page, which the RISC-V
  # specification has made up the word "terapage" for. I seriously don't know
  # what that means and now you, reader, don't either.

  # Let's just add that mapping now.
  # It might be better to do something more constrained to RAM (perhaps
  # in kmain after reading the memory base and size from the FDT)
  # You just take 0x0 and add some flags to it and map it to the last entry:
  li    t0, PTE_VALID | PTE_GLOBAL | PTE_READ | PTE_WRITE
  li    t1, PTE_SIZE * 511
  add   t1, s0, t1
  sd    t0, 0(t1)

  # Determine our kernel size
  # (it will be _end - _start)
  la    t0, _start
  la    t1, _end
  sub   t0, t1, t0

  jal   fdt_get_memory_base_addr

  move  a1, a0
  move  a0, s0
  la    a2, _start
  move  a3, t0
  li    a4, PTE_GLOBAL | PTE_READ | PTE_WRITE | PTE_EXECUTE
  jal   paging_map_range

  # We will also want to map in our virtio MMIO space (as non-execute)
  # so we can print to the screen and read input using our console driver.
  jal   fdt_get_virtio_base_addr
  move  a1, a0        # virtio_base is the physical address
  move  a0, s0        # our root page table
  li    a2, MEM_BASE  #
  add   a2, a1, a2    # Map it to MEM_BASE + virtio_base
  li    a3, PAGE_SIZE # For just a single page
  li    a4, PTE_GLOBAL | PTE_READ | PTE_WRITE
  jal   paging_map_range

  # We need the HTIF range as well
  li    a1, 0x40008000 # HTIF_BASE
  move  a0, s0         # our root page table
  li    a2, MEM_BASE   #
  add   a2, a1, a2     # Map it to MEM_BASE + HTIF_BASE
  li    a3, PAGE_SIZE  # For just a single page
  li    a4, PTE_GLOBAL | PTE_READ | PTE_WRITE
  jal   paging_map_range

  # Map in our allocated pages (and hope we don't allocate any more!)
  # We haven't freed at this point... so we just allocate a page and use that
  # to get the page boundary.

  # That gave us the amount of bytes allocated for our
  # page tables so far.

  # The starting address is _end
  la    a2, _end
  # When we subtract _start and add memory base, we get a physical address.
  la    t0, _start
  sub   a1, a2, t0
  jal   fdt_get_memory_base_addr
  add   a1, a1, a0

  # Get the next available page.
  # And subtract that from this address.
  jal   memory_alloc_page
  move  t0, a0
  jal   fdt_get_memory_base_addr
  add   t0, t0, a0
  sub   a3, t0, a1

  # Using our root page table
  move  a0, s0
  li    a4, PTE_GLOBAL | PTE_READ | PTE_WRITE | PTE_EXECUTE
  jal   paging_map_range

  move  a0, s0

  pop   s0
  pop   ra
  jr    ra

# paging_map(phys_addr, virtual_addr): Maps the given physical address to the
#   given virtual address.
#
# Arguments
#   a0: The root page table address
#   a1: The physical address within the system memory to map.
#   a2: The virtual address to map it to.
#   a3: Flags.
paging_map:
  # Just call paging_map_range with a length of 1
  move  a4, a3
  li    a3, 1
  j     paging_map_range

# paging_map_range(phys_addr, virtual_addr): Maps the given physical address to
#   the given virtual address for the entire span given.
#
# If the physical and virtual address have different offsets relative to the
# page size, they will lose the relationship and their mapping will be
# significantly different on a different machine.
#
# Arguments
#   a0: The root page table address
#   a1: The physical address within the system memory to map.
#   a2: The virtual address to map it to.
#   a3: The number of bytes to map.
#   a4: Flags.
paging_map_range:
  push  ra
  push  s0
  push  s1
  push  s2
  push  s3
  push  s4
  push  s5
  push  s6
  push  s7
  push  s8

  # Retain arguments
  move  s5, a1
  move  s6, a2
  move  s7, a3

  move  s0, a4

  # Here. We. Go.

  # First, make sure our flags are appropriate. They all fit within a byte.
  and   s0, s0, 0xff

  # Get the number of pages we need
  # Align the number of bytes to map to the page boundary
  alignPage s7
  # Get the number of pages by dividing by PAGE_SIZE
  srli  s7, s7, PAGE_OFFSET

  # We need to walk the page table and allocate entries as we need them.
  # When we hit a leaf, we generate the appropriate entry and mark the
  # appropriate flags.

  # We keep track of our PPN position, and by virtue of that know which level
  # we should be on. Our architecture is using 4 page levels, so we will have
  # four for loops. (Tongue twister on top of everything else! Egads!)

  # Get our starting PPN by first rounding down our starting address
  alignPageDown s6
  # And we only have a 48-bit system, so mask that away
  li    t0, 1
  sll   t0, t0, 48
  add   t0, t0, -1
  and   s6, s6, t0
  # Same thing as before, divide by PAGE_SIZE
  srli  s6, s6, PAGE_OFFSET

  # We must similarly shift our physical address down.
  alignPageDown s5
  # Yet again, divide by PAGE_SIZE
  srli  s5, s5, PAGE_OFFSET

  # Keep track of our root table
  move  s4, a0

  # TODO: do intermediate pages need PTE_GLOBAL??

_paging_map_range_level_4:

  # s4: A pointer to the root table.
  # Goal: find s3, the pointer to the 3rd level table.

  # Go to the entry in our root table
  # If no entry exists, create an intermediate PDPT
  # Supply that to level 3, and onward we go!

  srl   t0, s6, PAGE_LEVEL_OFFSET * 3
  and   t0, t0, (PAGE_LEVEL_PTE_SIZE - 1)
  sll   t0, t0, 3
  add   t0, s4, t0
  ld    t0, 0(t0)
  and   t1, t0, PTE_VALID
  beqz  t1, _paging_map_range_level_4_alloc_pdpt

  # Get a pointer to the existing PDPT
  srl   t0, t0, PTE_PPN_OFFSET
  sll   t0, t0, PAGE_OFFSET
  li    t1, MEM_BASE
  add   s3, t1, t0

  j _paging_map_range_level_3

_paging_map_range_level_4_alloc_pdpt:
  #la    a0, str_paging_alloc_3
  #jal   print

  # Allocate a page
  jal   memory_alloc_page
  move  s3, a0

  # Compute its physical address
  jal   fdt_get_memory_base_addr
  add   s3, a0, s3

  # Write entry
  srl   t1, s3, PAGE_OFFSET               # compute PPN of new page
  sll   t1, t1, PTE_PPN_OFFSET            # get the new PTE
  or    t1, t1, PTE_VALID | PTE_USER      # mark it valid

  srl   t0, s6, PAGE_LEVEL_OFFSET * 3
  and   t0, t0, (PAGE_LEVEL_PTE_SIZE - 1)
  sll   t0, t0, 3
  add   t0, s4, t0
  sd    t1, 0(t0)                         # store the entry

  # Adjust to virtual pointer
  li    t0, MEM_BASE
  add   s3, s3, t0

  # Zero page
  move  a0, s3
  li    a1, PAGE_SIZE
  jal   memzero

  j _paging_map_range_level_3

_paging_map_range_level_3:
  # s3: A pointer to the 3rd level table.
  # Goal: find s2, the pointer to the 2nd level table.

  # Go to the entry in our 3rd level table.
  # If no entry exists, create an intermediate PDPT
  # Supply that to level 2, and onward we go!

  srl   t0, s6, PAGE_LEVEL_OFFSET * 2
  and   t0, t0, (PAGE_LEVEL_PTE_SIZE - 1)
  sll   t0, t0, 3
  add   t0, s3, t0
  ld    t0, 0(t0)
  and   t1, t0, PTE_VALID
  beqz  t1, _paging_map_range_level_3_alloc_pdpt

  # Get a pointer to the existing PDPT
  srl   t0, t0, PTE_PPN_OFFSET
  sll   t0, t0, PAGE_OFFSET
  li    t1, MEM_BASE
  add   s2, t1, t0

  j _paging_map_range_level_2

_paging_map_range_level_3_alloc_pdpt:
  #la    a0, str_paging_alloc_2
  #jal   print

  # Allocate a page
  jal   memory_alloc_page
  move  s2, a0

  # Compute its physical address
  jal   fdt_get_memory_base_addr
  add   s2, a0, s2

  # Write entry
  srl   t1, s2, PAGE_OFFSET               # compute PPN of new page
  sll   t1, t1, PTE_PPN_OFFSET            # get the new PTE
  or    t1, t1, PTE_VALID | PTE_USER      # mark it valid

  srl   t0, s6, PAGE_LEVEL_OFFSET * 2
  and   t0, t0, (PAGE_LEVEL_PTE_SIZE - 1)
  sll   t0, t0, 3
  add   t0, s3, t0
  sd    t1, 0(t0)                         # store the entry

  # Adjust to virtual pointer
  li    t0, MEM_BASE
  add   s2, s2, t0

  # Zero page
  move  a0, s2
  li    a1, PAGE_SIZE
  jal   memzero

  j _paging_map_range_level_2

_paging_map_range_level_2:

  # s2: A pointer to the 2nd level table.
  # Goal: find s1, the pointer to the 1st level table.

  # Go to the entry in our 2nd level table.
  # If no entry exists, create an intermediate PDPT
  # Supply that to level 1, and onward we go!

  srl   t0, s6, PAGE_LEVEL_OFFSET * 1
  and   t0, t0, (PAGE_LEVEL_PTE_SIZE - 1)
  sll   t0, t0, 3
  add   t0, s2, t0
  ld    t0, 0(t0)
  and   t1, t0, PTE_VALID
  beqz  t1, _paging_map_range_level_2_alloc_pdpt

  # Get a pointer to the existing PDPT
  srl   t0, t0, PTE_PPN_OFFSET
  sll   t0, t0, PAGE_OFFSET
  li    t1, MEM_BASE
  add   s1, t1, t0

  j _paging_map_range_level_1

_paging_map_range_level_2_alloc_pdpt:
  #la    a0, str_paging_alloc_1
  #jal   print

  # Allocate a page
  jal   memory_alloc_page
  move  s1, a0

  # Compute its physical address
  jal   fdt_get_memory_base_addr
  add   s1, a0, s1

  # Write entry
  srl   t1, s1, PAGE_OFFSET               # compute PPN of new page
  sll   t1, t1, PTE_PPN_OFFSET            # get the new PTE
  or    t1, t1, PTE_VALID | PTE_USER      # mark it valid

  srl   t0, s6, PAGE_LEVEL_OFFSET * 1
  and   t0, t0, (PAGE_LEVEL_PTE_SIZE - 1)
  sll   t0, t0, 3
  add   t0, s2, t0
  sd    t1, 0(t0)                         # store the entry

  # Adjust to virtual pointer
  li    t0, MEM_BASE
  add   s1, s1, t0

  # Zero page
  move  a0, s1
  li    a1, PAGE_SIZE
  jal   memzero

  j _paging_map_range_level_1

_paging_map_range_level_1:

  # s1: A pointer to the 1st level table.
  # Goal: write the PTE (Page Table Entry)

  # Is this page table entry already used? Is it marked 'VALID'?
  # If so, we should error out.
  and   t0, s6, (PAGE_LEVEL_PTE_SIZE - 1)
  sll   t0, t0, 3
  add   t0, s1, t0
  ld    t0, 0(t0)
  and   t1, t0, PTE_VALID
  beqz  t1, _paging_map_range_level_1_write_entry

  # already exists???
  la    a0, str_paging_error
  jal   print

  j _paging_map_range_exit

_paging_map_range_level_1_write_entry:
  # Craft entry
  sll   t1, s5, PTE_PPN_OFFSET            # get the new PTE
  or    t1, t1, PTE_VALID                 # mark it valid
  or    t1, t1, s0                        # give it requested flags

  # Write entry
  and   t0, s6, (PAGE_LEVEL_PTE_SIZE - 1)
  sll   t0, t0, 3
  add   t0, s1, t0
  sd    t1, 0(t0)                         # store the entry

  # Consume one of the pages we need to map
  add   s7, s7, -1

  # Did we map the last page? Are we done?
  blez  s7, _paging_map_range_exit

  # Increment our PPN of interest
  add   s6, s6, 1
  add   s5, s5, 1

  # We leave whenever we exhaust our current page directory.

  # Exit if we completed every page we needed for this level.
  # Go back to level 2 if our current PPN is aligned.
  li    t0, PAGE_LEVEL_PTE_SIZE
  add   t0, t0, -1
  and   t0, s6, t0
  beqz  t0, _paging_map_range_level_2_done

  # Loop while we are still making use of this page table
  j _paging_map_range_level_1

_paging_map_range_level_2_done:
  # We leave whenever we exhaust our current page directory.
  li    t0, PAGE_LEVEL_PTE_SIZE
  sll   t0, t0, PAGE_LEVEL_OFFSET
  add   t0, t0, -1
  and   t0, s6, t0
  beqz  t0, _paging_map_range_level_3_done

  j _paging_map_range_level_2

_paging_map_range_level_3_done:
  # We leave whenever we exhaust our current page directory.
  li    t0, PAGE_LEVEL_PTE_SIZE
  sll   t0, t0, PAGE_LEVEL_OFFSET * 2
  add   t0, t0, -1
  and   t0, s6, t0
  beqz  t0, _paging_map_range_level_4_done

  j _paging_map_range_level_3

_paging_map_range_level_4_done:
  # We leave whenever we exhaust virtual memory.
  li    t0, PAGE_LEVEL_PTE_SIZE
  sll   t0, t0, PAGE_LEVEL_OFFSET * 3
  add   t0, t0, -1
  and   t0, s6, t0
  beqz  t0, _paging_map_range_exit

  j _paging_map_range_level_4

_paging_map_range_exit:
  # Phew!
  pop   s8
  pop   s7
  pop   s6
  pop   s5
  pop   s4
  pop   s3
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# paging_create_root(): Creates a new PDPT (Page Directory Page Table) and
#   returns it.
#
# Returns
#   a0: The address of a zeroed PDPT.
paging_create_root:
  push  ra
  push  s0

  #la    a0, str_paging_alloc_4
  #jal   print

  # Allocate a page
  jal   memory_alloc_page
  move  s0, a0

  # Get its current virtual address (mind blowing stuff, here)
  jal   fdt_get_memory_base_addr
  add   s0, a0, s0
  
  li    a0, MEM_BASE
  add   s0, a0, s0

  # Initialize it by zeroing it
  move  a0, s0
  ld    t0, 0(s0)
  li    a1, PAGE_SIZE
  jal   memzero

  # Return it
  move  a0, s0

  pop   s0
  pop   ra
  jr    ra

# paging_install(root_pdpt_ptr): Installs the given root page table.
#
# Arguments
#   a0: The address of the root page directory page table (PDPT) to install.
paging_install:
  # Get the physical address of this page table by subtracting the memory base
  li    t0, MEM_BASE
  sub   a0, a0, t0

  # Set the PDPT
  srli  a0, a0, PAGE_OFFSET
  li    t0, SATP_SV48
  or    a0, a0, t0
  # AHH Let's hope this works :) :) :)
  csrw  satp, a0

  # If it didn't work, we didn't get here. Because everything is now on fire.
  # (We probably trapped to M-Mode on a page fault or worse)

  # However, if we got here. Whew! We did it. Our entire concept of memory is
  # now different.
  jr    ra

# paging_get_root(): Returns the virtual address for the root page table.
#
# Returns
#   a0: The virtual address of the root page table
paging_get_root:
  # Get the current root page table
  csrr  t0, satp
  li    t1, 0x3fffff
  and   t0, t0, t1          # mask 22 bits to get PPN of root page table
  sll   t0, t0, PAGE_OFFSET # get physical address of root page table
  li    t1, MEM_BASE
  add   a0, t0, t1          # get virtual address of root page table
  jr    ra

# paging_vaddr_to_paddr(vaddr): Returns the physical address pointed to be the
#   given virtual address.
#
# Guess what would be trivial if we had the ability to create self-referential
# page tables?? Oh well, RISC-V.
#
# Arguments
#   a0: The virtual address to translate.
#
# Returns
#   a0: The physical address this virtual address maps to, or -1 if none.
paging_vaddr_to_paddr:
  # Get the current root page table
  csrr  t0, satp
  li    t1, 0x3fffff
  and   t0, t0, t1          # mask 22 bits to get PPN of root page table
  sll   t0, t0, PAGE_OFFSET # get physical address of root page table
  li    t1, MEM_BASE
  add   t0, t0, t1          # get virtual address of root page table

  # Break up the virtual address and walk the page tables ourselves
  li    t3, 3 # counter
_paging_vaddr_to_paddr_loop:
  srl   t1, a0, PAGE_OFFSET             # throw out the offset bits
  li    t2, PAGE_LEVEL_OFFSET
  mul   t2, t2, t3
  srl   t1, t1, t2                      # throw out the other levels for now
  and   t1, t1, (PAGE_LEVEL_PTE_SIZE-1) # get the level index
  sll   t1, t1, PTE_SIZE_LOG_2          # get offset into table
  add   t1, t1, t0                      # get address in table
  move  t5, t1
  ld    t1, 0(t1)                       # get PTE
  and   t2, t1, PTE_READ | PTE_EXECUTE  # check if this is a leaf pointer
  srl   t1, t1, PTE_PPN_OFFSET          # get PPN
  sll   t1, t1, PAGE_OFFSET             # physical address of next level/leaf
  bnez  t2, _paging_vaddr_to_paddr_loop_exit # leaf pointer
  li    t2, MEM_BASE
  add   t0, t1, t2                      # virtual address of next level/leaf

  add   t3, t3, -1
  bgez  t3, _paging_vaddr_to_paddr_loop

_paging_vaddr_to_paddr_loop_exit:
  # t1: The physical address of the memory
  # t3: The level we were on

  # we need to add the offset back
  li    t0, 1
  li    t2, PAGE_OFFSET # we, at least, want the page offset
  sll   t0, t0, t2
  li    t2, PAGE_LEVEL_OFFSET # and we want each level we didn't use
  mul   t2, t2, t3
  sll   t0, t0, t2

  add   t0, t0, -1            # create a mask
  and   a0, a0, t0            # and get the offset
  add   a0, a0, t1            # add it to our current paddr

  jr    ra
  
.data
.balign 8, 0

str_paging_error:   .string "Paging: Error: Attempt to remap an existing page."

str_paging_alloc_4: .string "alloc 4\n"
str_paging_alloc_3: .string "alloc 3\n"
str_paging_alloc_2: .string "alloc 2\n"
str_paging_alloc_1: .string "alloc 1\n"
str_paging_mapped:  .string "mapped page\n"
