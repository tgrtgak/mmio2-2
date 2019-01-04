# This file contains constants that affect the nature of the kernel.

# This is the virtual address of RAM.
.set MEM_BASE,            0xffffff8000000000

# This is the virtual address of the kernel.
.set KERN_MEM_BASE,       0xffff800000000000
.set KERN_BASE,           0xffff800080000000

# These are various fields in the 'mstatus' CSR (Control and Status Registers)

# The MPRV (Modify-PRiVilege) when clear will not perform address translation.
.set MSTATUS_MPRV,        (1 << 17)

.set MSTATUS_SUM_OFFSET,  18
.set MSTATUS_MPP_OFFSET,  11
.set MSTATUS_MPP_CLEAR,   ~(0b11 <<  MSTATUS_MPP_OFFSET)

# The different modes
.set MODE_MACHINE,        0b00
.set MODE_SUPERVISOR,     0b01
.set MODE_USER,           0b11

# The page offset
.set PAGE_OFFSET,         12

# The page size
.set PAGE_SIZE,           4096

# The satp register value (for 48-bit address space)
.set SATP_SV48,           0x9000000000000000

# The size of a Page Table Entry (PTE) in bytes
.set PTE_SIZE,            8
.set PTE_SIZE_LOG_2,      3

# The bit offset of the PPN (Physical Page Number) within a PTE
.set PTE_PPN_OFFSET,      10

# The page level offset, or number of bits in virtual address for each level.
.set PAGE_LEVEL_OFFSET,   9

# The number of page table entries
.set PAGE_LEVEL_PTE_SIZE, (PAGE_SIZE / PTE_SIZE)

# The flag that sets a PTE to be valid
.set PTE_VALID,           0b00000001

# The flag that sets a PTE to be readable
.set PTE_READ,            0b00000010

# The flag that sets a PTE to be writable
.set PTE_WRITE,           0b00000100

# The flag that sets a PTE to be executable
.set PTE_EXECUTE,         0b00001000

# The flag that sets a PTE to be available to USER mode
.set PTE_USER,            0b00010000

# The flag that sets a PTE to be a global page (available in all address spaces)
.set PTE_GLOBAL,          0b00100000

# The flag that indicates a PTE refers to memory that has been accessed.
.set PTE_ACCESSED,        0b01000000

# The flag that indicates a PTE refers to a dirty (modified) page.
.set PTE_DIRTY,           0b10000000
