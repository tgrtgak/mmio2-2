# This file reads the FDT (Flattened Device Tree).

# Much of the documentation inscribed here is taken from the DeviceTree
# specification:
# https://github.com/devicetree-org/devicetree-specification/releases/tag/v0.2

.include "const.s"
.include "util.s"

.global fdt_read
.global fdt_get_virtio_base_addr
.global fdt_get_virtio_irq
.global fdt_get_virtio_count
.global fdt_get_clint_base_addr
.global fdt_get_plic_base_addr
.global fdt_get_cpu_timebase_frequency
.global fdt_get_memory_base_addr
.global fdt_get_memory_length
.global fdt_get_application_base_addr
.global fdt_get_application_length
.global fdt_get_framebuffer_base_addr
.global fdt_get_framebuffer_width
.global fdt_get_framebuffer_height
.global fdt_get_mmio_base_addr
.global fdt_get_mmio_length
.global fdt_get_mmio_count

# The magic number to look for
.set FDT_MAGIC,                 0xd00dfeed

# The amount of memory to check
.set FDT_CHECK_START,           MEM_BASE
.set FDT_CHECK_LENGTH,          0x10000

# A place to kinda look first. Hint! Hint! It's Here!
.set FDT_LOCATION_HINT,         MEM_BASE + 0x1040

# Structures (the following are offsets to fields)

# The FDT is a header followed by a "Memory Reservation Block" followed by two
# blocks providing the structure (layout) and strings (content) of the actual
# tree. Each item in the header is 32-bits and big-endian.

# FDT HEADER

# Magic number
.set FDT_HEADER_MAGIC,                0
# The size of the entire FDT in bytes
.set FDT_HEADER_SIZE,                 4
# The offset in bytes to the structure block
.set FDT_HEADER_OFFSET_STRUCTURE,     8
# The offset in bytes to the strings block
.set FDT_HEADER_OFFSET_STRINGS,       12
# The offset in bytes to the reserved memory
.set FDT_HEADER_OFFSET_MEM_RESV,      16
# The Device Tree version
.set FDT_HEADER_VERSION,              20
# The last compatible version
.set FDT_HEADER_LAST_COMPATIBLE,      24
# The physical ID of the system's boot CPU
.set FDT_HEADER_BOOT_CPUID,           28
# The size of the strings block
.set FDT_HEADER_SIZE_STRINGS,         32
# The size of the structure block
.set FDT_HEADER_SIZE_STRUCTURE,       36

# The Memory Reservation Block contains regions that are reserved by the system
# and cannot be used by the operating system.

# Each entry is denoted by a simple structure with 64-bit big-endian fields. The
# structure is aligned at an 8-byte alignment.

# MEMORY RESERVE ENTRY

# The address of the region
.set FDT_MEM_RESV_ENTRY_ADDRESS,      0
# The size of the region
.set FDT_MEM_RESV_ENTRY_SIZE,         8

# The Structure Block describes the structure and contents of the devicetree
# itself. It is composed of a sequence of tokens with data, as described below.
# These are organized as a linear tree structure, as described below.

# There are five (5) token types:

# FDT node identifiers

# Marks the beginning of a node's representation.
# It shall be followed by the node's unit name as extra data. The name is stored
# as a null-terminated string, and shall include the unit address (see
# section 2.2.1 of the spec), if any. The node name is followed by zeroed
# padding bytes, if necessary for alignment, and then the next token, which may
# be any token except FDT_END.
.set FDT_BEGIN_NODE,            1

# Marks the end of a node's representation. This token has no extra data; so it
# is followed immediately by the next token, which may be any token except
# FDT_PROP.
.set FDT_END_NODE,              2

# Marks the beginning of the representation of one property in the devicetree.
# It shall be followed by extra data describing the property. This data consists
# first of the property's length and name represented as the following C
# structure:
#
#    struct { uint32_t len; uint32_t nameoff; }
.set FDT_PROP,                  3

# The FDT_NOP token will be ignored by any program parsing the device tree. This
# token has no extra data; so it is followed immediately by the next token,
# which can be any valid token.
.set FDT_NOP,                   4

# Marks the end of the structure block.
.set FDT_END,                   9

# The Strings Block.

# Any name (like the names of nodes or "nameoff" in properties) is given as a
# 32-bit offset into the strings block. It is just a swarm of strings all
# concatenated together. Each string is zero-terminated.

.text

# fdt_read(): Reads the FDT and parses out important information.
fdt_read:
  push  ra

  # Look for the FDT table in well-known locations first
  li    a0, FDT_LOCATION_HINT
  li    a1, 8 * 8
  jal   fdt_scan

  li    t0, -1
  bne   a0, t0, _fdt_read_success

  # Find the FDT table by rigorously scanning memory
  li    a0, FDT_CHECK_START
  li    a1, FDT_CHECK_LENGTH
  jal   fdt_scan

  li    t0, -1
  beq   a0, t0, _fdt_read_error

_fdt_read_success:
  # Read headers
  jal   fdt_read_header

  # Read memory reservations
  jal   fdt_read_memory_reservation_block

  # Read device tree
  jal   fdt_read_nodes

  # Return success
  li    a0, 0
  j     _fdt_read_exit

_fdt_read_error:
  # Cannot find the FDT
  li    a0, -1
  j     _fdt_read_exit

_fdt_read_exit:
  pop   ra
  jr    ra

# fdt_get_cpu_timebase_frequency(): Returns the timer resolution in cycles per second.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The cycles per second of the CPU.
fdt_get_cpu_timebase_frequency:
  la    a0, fdt_cpu_timebase_frequency
  ld    a0, 0(a0)
  jr    ra

# fdt_get_virtio_base_addr(): Returns the address of the virtio MMIO region.
#
# Does not clobber any registers except a0.
#
# Arguments
#   a0: The index of the virtio device.
#
# Returns
#   a0: The address of the virtio MMIO region.
fdt_get_virtio_base_addr:
  push  s0
  sll   a0, a0, 3
  la    s0, fdt_virtio_base_addrs
  add   a0, a0, s0
  ld    a0, 0(a0)
  pop   s0
  jr    ra

# fdt_get_virtio_irq(): Returns the irq for the virtio device
#
# Does not clobber any registers except a0.
#
# Arguments
#   a0: The index of the virtio device.
#
# Returns
#   a0: The irq for the virtio device.
fdt_get_virtio_irq:
  push  s0
  sll   a0, a0, 3
  la    s0, fdt_virtio_irqs
  add   a0, a0, s0
  ld    a0, 0(a0)
  pop   s0
  jr    ra

# fdt_get_virtio_count(): Returns the number of virtio devices.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The number of virtio devices.
fdt_get_virtio_count:
  la    a0, fdt_virtio_count
  ld    a0, 0(a0)
  jr    ra

# fdt_get_mmio_base_addr(): Returns the address of the MMIO region.
#
# Does not clobber any registers except a0.
#
# Arguments
#   a0: The index of the mmio device.
#
# Returns
#   a0: The address of the MMIO region.
fdt_get_mmio_base_addr:
  push  s0
  sll   a0, a0, 3
  la    s0, fdt_mmio_base_addrs
  add   a0, a0, s0
  ld    a0, 0(a0)
  pop   s0
  jr    ra

# fdt_get_mmio_length(): Returns the length of the MMIO region.
#
# Does not clobber any registers except a0.
#
# Arguments
#   a0: The index of the mmio device.
#
# Returns
#   a0: The address of the MMIO region.
fdt_get_mmio_length:
  push  s0
  sll   a0, a0, 3
  la    s0, fdt_mmio_lengths
  add   a0, a0, s0
  ld    a0, 0(a0)
  pop   s0
  jr    ra

# fdt_get_mmio_count(): Returns the number of MMIO devices.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The number of MMIO devices.
fdt_get_mmio_count:
  la    a0, fdt_mmio_count
  ld    a0, 0(a0)
  jr    ra

# fdt_get_clint_base_addr(): Returns the address of the clint MMIO region.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The address of the clint MMIO region.
fdt_get_clint_base_addr:
  la    a0, fdt_clint_base_addr
  ld    a0, 0(a0)
  jr    ra

# fdt_get_plic_base_addr(): Returns the address of the plic MMIO region.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The address of the plic MMIO region.
fdt_get_plic_base_addr:
  la    a0, fdt_plic_base_addr
  ld    a0, 0(a0)
  jr    ra

# fdt_get_memory_base_addr(): Returns the address of RAM.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The address of RAM.
fdt_get_memory_base_addr:
  la    a0, fdt_memory_base_addr
  ld    a0, 0(a0)
  jr    ra

# fdt_get_memory_length(): Returns the amount of RAM available.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The address of the virtio MMIO region.
fdt_get_memory_length:
  la    a0, fdt_memory_length
  ld    a0, 0(a0)
  jr    ra

# fdt_get_application_base_addr(): Returns the application binary address.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The address of the application binary to run.
fdt_get_application_base_addr:
  la    a0, fdt_application_start
  ld    a0, 0(a0)
  jr    ra

# fdt_get_application_length(): Returns the application binary size.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The size of the application binary.
fdt_get_application_length:
  push  t0
  la    a0, fdt_application_end
  ld    t0, 0(a0)
  la    a0, fdt_application_start
  ld    a0, 0(a0)
  sub   a0, t0, a0
  pop   t0
  jr    ra

# fdt_get_framebuffer_base_addr(): Returns the framebuffer base address.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The address of the framebuffer.
fdt_get_framebuffer_base_addr:
  la    a0, fdt_framebuffer_base_addr
  ld    a0, 0(a0)
  jr    ra

# fdt_get_framebuffer_width(): Returns the framebuffer width.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The width in pixels of the framebuffer.
fdt_get_framebuffer_width:
  la    a0, fdt_framebuffer_width
  ld    a0, 0(a0)
  jr    ra

# fdt_get_framebuffer_height(): Returns the framebuffer height.
#
# Does not clobber any registers except a0.
#
# Returns
#   a0: The height in pixels of the framebuffer.
fdt_get_framebuffer_height:
  la    a0, fdt_framebuffer_height
  ld    a0, 0(a0)
  jr    ra

# fdt_scan(): Scans RAM for the FDT header (which should be early in RAM)
#
# In the TinyEmu emulator, it is at 0x1040, but it could technically be just
# about anywhere (but aligned to a word boundary, hopefully)
#
# Arguments
#   a0: Starting position
#   a1: Length of region to check
#
# Returns
#   a0: The address of the FDT or -1 if not found.
fdt_scan:
  push  ra
  push  s0
  push  s1
  push  s2

  move  s0, a0
  add   s1, s0, a1
  li    s2, FDT_MAGIC

  move  a0, s2
  jal   toBE32
  move  s2, a0

  # Default result is it is not found
  li    a0, -1

_fdt_scan_check:
  # Exit if we haven't found it by now
  bgeu  s0, s1, _fdt_scan_exit

  # Pull a word and check against the Magic number.
  lwu   t0, 0(s0)

  # Is it that number? Good. Go to "found"
  beq   t0, s2, _fdt_scan_found

  # Check the next word in memory
  add   s0, s0, 4
  j     _fdt_scan_check

_fdt_scan_found:
  # Return s0, the address of the magic number
  move  a0, s0
  j     _fdt_scan_exit

_fdt_scan_exit:
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# fdt_read_header(header_ptr)
#
# Arguments
#   a0: The pointer to the FDT header.
fdt_read_header:
  push  ra
  push  s0

  move  s0, a0

  # Retain the header address
  la    t0, fdt_header_ptr
  sd    s0, 0(t0)

  # Read the size of the FDT
  lwu   a0, FDT_HEADER_SIZE(s0)
  jal   toBE32
  la    t0, fdt_size
  sd    a0, 0(t0)

  # Read the memory reservation block offset
  lwu   a0, FDT_HEADER_OFFSET_MEM_RESV(s0)
  jal   toBE32
  add   a0, a0, s0
  la    t0, fdt_mem_rsrv_ptr
  sd    a0, 0(t0)

  # Read the structure offset
  lwu   a0, FDT_HEADER_OFFSET_STRUCTURE(s0)
  jal   toBE32
  add   a0, a0, s0
  la    t0, fdt_structure_ptr
  sd    a0, 0(t0)

  # Read the structure length
  lwu   a0, FDT_HEADER_SIZE_STRUCTURE(s0)
  jal   toBE32
  la    t0, fdt_structure_length
  sd    a0, 0(t0)

  # Read the strings offset
  lwu   a0, FDT_HEADER_OFFSET_STRINGS(s0)
  jal   toBE32
  add   a0, a0, s0
  la    t0, fdt_strings_ptr
  sd    a0, 0(t0)

  # Read the strings length
  lwu   a0, FDT_HEADER_SIZE_STRINGS(s0)
  jal   toBE32
  la    t0, fdt_strings_length
  sd    a0, 0(t0)

  pop   s0
  pop   ra
  jr    ra

# fdt_read_memory_reservation_block(): Reads the memory reservation block and
#   pulls out information about reserved memory regions.
fdt_read_memory_reservation_block:
  push  ra
  push  s0
  push  s1

  # Recover the memory reservation block address
  la    t0, fdt_mem_rsrv_ptr
  ld    s0, 0(t0)

  # We will read each entry until our pointer surpasses the FDT.
  la    t0, fdt_header_ptr
  ld    t1, 0(t0)
  la    t0, fdt_size
  ld    s1, 0(t0)
  add   s1, s1, t1

_fdt_read_memory_reservation_block_entry:
  # Quit if we've run out of memory to read
  bgeu  s0, s1, _fdt_read_memory_reservation_block_exit

  # Read offset and length (big endian)
  ld    t0, 0(s0)
  ld    t1, 8(s0)

  # Quit if t0 and t1 are 0
  add   t2, t0, t1
  beqz  t2, _fdt_read_memory_reservation_block_exit

  move  a0, t0
  jal   toBE64
  move  t0, a0

  move  a0, t1
  jal   toBE64
  move  t1, a0

  # TODO: Do something with the region (t0, t0 + t1)

  # Go to next entry
  add   s0, s0, 16

  j     _fdt_read_memory_reservation_block_entry

_fdt_read_memory_reservation_block_exit:
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# fdt_read_nodes(): Reads the actual device tree.
fdt_read_nodes:
  push  ra
  push  s0
  push  s1
  push  s2
  push  s3

  # s0: The current pointer into the FDT table
  # s1: The address of the end of the FDT tables
  # s2: The offset to the strings table
  # s3: The most recent node name

  # Get pointer of structure block
  la    t0, fdt_structure_ptr
  ld    s0, 0(t0)

  # We will read each entry until our pointer surpasses the FDT.
  la    t0, fdt_header_ptr
  ld    t1, 0(t0)
  la    t0, fdt_size
  ld    s1, 0(t0)
  add   s1, s1, t1

  # Also get the strings ptr
  la    t0, fdt_strings_ptr
  ld    s2, 0(t0)

_fdt_read_nodes_entry:
  # Quit if we've run out of memory to read
  bgeu  s0, s1, _fdt_read_nodes_exit

  lwu   a0, 0(s0)
  jal   toBE32

  li    t0, FDT_BEGIN_NODE
  beq   a0, t0, _fdt_read_nodes_entry_begin_node

  li    t0, FDT_PROP
  beq   a0, t0, _fdt_read_nodes_entry_property

  li    t0, FDT_END_NODE
  beq   a0, t0, _fdt_read_nodes_entry_end_node

  li    t0, FDT_END
  beq   a0, t0, _fdt_read_nodes_entry_end

  # Unknown node or NOP
  j     _fdt_read_nodes_entry_continue

_fdt_read_nodes_entry_begin_node:
  # Read name as extra data
  add   s0, s0, 4
  move  s3, s0
  move  a0, s0
  jal   strlen
  add   s0, s0, a0
  align32 s0

  # Go back up to the top
  j     _fdt_read_nodes_entry

_fdt_read_nodes_entry_property:
  # Gather name and offset
  add   s0, s0, 4
  lwu   a0, 4(s0)
  jal   toBE32
  move  t1, a0
  add   t1, t1, s2

  # Retrieve value length
  lwu   a0, 0(s0)
  jal   toBE32
  move  t0, a0

  move  a0, s3    # a0: The pointer to the node name
  move  a1, t1    # a1: The pointer to the property name
  move  a2, s0    #
  add   a2, a2, 8 # a2: The pointer to the property value
  move  a3, t0    # a3: The property value length

  # Consume the value, and the length/name struct
  add   s0, s0, t0
  add   s0, s0, 8

  # Keep our pointer aligned
  align32 s0

  jal   fdt_parse_property

  # Go back up to the top
  j     _fdt_read_nodes_entry

_fdt_read_nodes_entry_end_node:
  j     _fdt_read_nodes_entry_continue

_fdt_read_nodes_entry_end:
  # Quit the loop. We're done.
  j     _fdt_read_nodes_exit

_fdt_read_nodes_entry_continue:
  # Go to next node
  add   s0, s0, 4
  j     _fdt_read_nodes_entry

_fdt_read_nodes_exit:
  pop   s3
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# fdt_parse_property(node_name_ptr, property_name_ptr, property_value,
#                    property_size): Parses the given property. Some of them
#   are important and we will just capture that info.
#
# Arguments
#   a0: The address of the node name.
#   a1: The address of the property name.
#   a2: The address of the property value.
#   a3: The length of the property value.
fdt_parse_property:
  push  ra
  push  s0
  push  s1
  push  s2
  push  s3

  # Retain arguments
  move  s0, a0
  move  s1, a1
  move  s2, a2
  move  s3, a3

  # We are looking for the memory region, kernel region, application binary
  # region, and the virtio MMIO range.

  # Check for root ("") nodes
  move  a0, s0
  la    a1, str_fdt_check_node_root
  li    a2, 1
  jal   strncmp
  beqz  a0, _fdt_parse_property_root

  move  a0, s0
  la    a1, str_fdt_check_node_chosen
  li    a2, 7
  jal   strncmp
  beqz  a0, _fdt_parse_property_chosen

  # Check for "virtio" nodes
  move  a0, s0
  la    a1, str_fdt_check_node_virtio
  li    a2, 7
  jal   strncmp
  beqz  a0, _fdt_parse_property_virtio

  # Check for "clint" nodes
  move  a0, s0
  la    a1, str_fdt_check_node_clint
  li    a2, 6
  jal   strncmp
  beqz  a0, _fdt_parse_property_clint

  # Check for "plic" nodes
  move  a0, s0
  la    a1, str_fdt_check_node_plic
  li    a2, 5
  jal   strncmp
  beqz  a0, _fdt_parse_property_plic

  # Check for "cpus" nodes
  move  a0, s0
  la    a1, str_fdt_check_node_cpus
  li    a2, 5
  jal   strncmp
  beqz  a0, _fdt_parse_property_cpus

  # Check for "memory" nodes
  move  a0, s0
  la    a1, str_fdt_check_node_memory
  li    a2, 7
  jal   strncmp
  beqz  a0, _fdt_parse_property_memory

  # Check for "framebuffer" nodes
  move  a0, s0
  la    a1, str_fdt_check_node_framebuffer
  li    a2, 12
  jal   strncmp
  beqz  a0, _fdt_parse_property_framebuffer

  # Check for "mmio" nodes
  move  a0, s0
  la    a1, str_fdt_check_node_mmio
  li    a2, 12
  jal   strncmp
  beqz  a0, _fdt_parse_property_mmio

  j     _fdt_parse_property_exit

_fdt_parse_property_root:
  # Look for '#address-cells'
  move  a0, s1
  la    a1, str_fdt_check_prop_address_cells
  li    a2, 9
  jal   strncmp
  beqz  a0, _fdt_parse_property_root_address_cells

  # Look for '#size-cells'
  move  a0, s1
  la    a1, str_fdt_check_prop_size_cells
  li    a2, 9
  jal   strncmp
  beqz  a0, _fdt_parse_property_root_size_cells

  j _fdt_parse_property_exit

_fdt_parse_property_root_address_cells:

  lwu   a0, 0(s2)
  jal   toBE32
  la    t0, fdt_address_cells
  sw    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_root_size_cells:

  lwu   a0, 0(s2)
  jal   toBE32
  la    t0, fdt_size_cells
  sw    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_chosen:

  # Check for the memory size "riscv,kernel-start"
  move  a0, s1
  la    a1, str_fdt_check_prop_kernel_start
  li    a2, 19
  jal   strncmp
  beqz  a0, _fdt_parse_property_chosen_kernel_start

  # Check for the memory size "riscv,kernel-end"
  move  a0, s1
  la    a1, str_fdt_check_prop_kernel_end
  li    a2, 17
  jal   strncmp
  beqz  a0, _fdt_parse_property_chosen_kernel_end

  j _fdt_parse_property_exit

_fdt_parse_property_chosen_kernel_start:

  # Read a 64-bit value

  ld    a0, 0(s2)
  jal   toBE64
  la    t0, fdt_application_start
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_chosen_kernel_end:

  # Read a 64-bit value
  ld    a0, 0(s2)
  jal   toBE64
  la    t0, fdt_application_end
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_virtio:
  # Check for the "reg" property
  move  a0, s1
  la    a1, str_fdt_check_prop_reg
  li    a2, 4
  jal   strncmp
  bnez  a0, _fdt_parse_property_virtio_irq

  # Pull the 'reg' value which is a <base, length> pair
  # The <base> part has a number of bytes given by "#address-cells" x 2
  # And the <length> part has "#size-cells" x 2 number of bytes

  # Get the number of address cells
  la    t1, fdt_address_cells
  ld    t1, 0(t1)

  # Read address
  lwu   a0, 0(s2)
  jal   toBE32
  li    t2, 1
  beq   t1, t2, _fdt_parse_property_virtio_addr_commit

  # 64-bit address
  move  t2, a0
  lwu   a0, 4(s2)
  jal   toBE32
  sll   t2, t2, 32
  add   a0, a0, t2

  # We ignore the size, for now

_fdt_parse_property_virtio_addr_commit:
  # Retrieve the next index
  la    t0, fdt_virtio_count
  ld    t1, 0(t0)

  # Multiply by 8 and add to the base address
  sll   t1, t1, 3
  la    t0, fdt_virtio_base_addrs
  add   t0, t0, t1
  sd    a0, 0(t0)

  # Increment fdt_virtio_count (restoring it first)
  la    t0, fdt_virtio_count
  srl   t1, t1, 3
  add   t1, t1, 1
  sd    t1, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_virtio_irq:
  # Check for the "interrupts-extended" property
  move  a0, s1
  la    a1, str_fdt_check_prop_interrupts_ex
  li    a2, 20
  jal   strncmp
  bnez  a0, _fdt_parse_property_exit

  # This is a tuple of 2 32-bit values
  # The first 32-bit value is the plic identifier
  # The second 32-bit value is the device IRQ

  # Get PLIC ID
  lwu   a0, 0(s2)
  jal   toBE32

  # Get IRQ
  lwu   a0, 4(s2)
  jal   toBE32

  # Write the IRQ
  la    t0, fdt_virtio_irq_count
  ld    t1, 0(t0)
  sll   t1, t1, 3
  la    t0, fdt_virtio_irqs
  add   t0, t0, t1
  sd    a0, 0(t0)

  # Increment the irq count
  la    t0, fdt_virtio_irq_count
  ld    t1, 0(t0)
  add   t1, t1, 1
  sd    t1, 0(t0)

  # Done
  j _fdt_parse_property_exit

_fdt_parse_property_clint:
  # Skip if we already know the base address
  la    t0, fdt_clint_base_addr
  ld    t0, 0(t0)
  bnez  t0, _fdt_parse_property_exit

  # Get the address by parsing the string
  move  a0, s0
  add   a0, a0, 6
  li    a1, 16
  jal   parse_int
  la    t0, fdt_clint_base_addr
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_plic:
  # Skip if we already know the base address
  la    t0, fdt_plic_base_addr
  ld    t0, 0(t0)
  bnez  t0, _fdt_parse_property_exit

  # Check for the "reg" property
  move  a0, s1
  la    a1, str_fdt_check_prop_reg
  li    a2, 4
  jal   strncmp
  bnez  a0, _fdt_parse_property_exit

  # Pull the 'reg' value which is a <base, length> pair
  # The <base> part has a number of bytes given by "#address-cells" x 2
  # And the <length> part has "#size-cells" x 2 number of bytes

  # Get the number of address cells
  la    t1, fdt_address_cells
  ld    t1, 0(t1)

  # Read address
  lwu   a0, 0(s2)
  jal   toBE32
  li    t2, 1
  beq   t1, t2, _fdt_parse_property_plic_addr_commit

  # 64-bit address
  move  t2, a0
  lwu   a0, 4(s2)
  jal   toBE32
  sll   t2, t2, 32
  add   a0, a0, t2

  # We ignore the size, for now

_fdt_parse_property_plic_addr_commit:

  # Write the base address
  la    t0, fdt_plic_base_addr
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_cpus:
  # Check for the cpus "timebase-frequency" property
  move  a0, s1
  la    a1, str_fdt_check_prop_timebase_freq
  li    a2, 19
  jal   strncmp
  bnez  a0, _fdt_parse_property_exit

  # Parse the field, a LE32 word
  lwu   a0, 0(s2)
  jal   toBE32
  la    t0, fdt_cpu_timebase_frequency
  sw    a0, 0(t0)

  j     _fdt_parse_property_exit

_fdt_parse_property_memory:
  # Check for the memory size "reg"
  move  a0, s1
  la    a1, str_fdt_check_prop_reg
  li    a2, 4
  jal   strncmp
  bnez  a0, _fdt_parse_property_memory_addr

  # Pull the 'reg' value which is a <base, length> pair
  # The <base> part has a number of bytes given by "#address-cells"
  # And the <length> part has "#size-cells" number of bytes

  # Skip address cells
  move  t0, s2
  la    t1, fdt_address_cells
  ld    t1, 0(t1)
  sll   t1, t1, 1
  add   t0, t0, t1

  # Get the number of size cells
  la    t1, fdt_size_cells
  ld    t1, 0(t1)

  # Read size
  lwu   a0, 0(t0)
  jal   toBE32
  li    t2, 1
  beq   t1, t2, _fdt_parse_property_memory_size_commit

  # 64-bit size
  move  t2, a0
  lwu   a0, 4(t0)
  jal   toBE32
  sll   t2, t2, 32
  add   a0, a0, t2

  j _fdt_parse_property_memory_size_commit

_fdt_parse_property_memory_size_commit:
  la    t0, fdt_memory_length
  sw    a0, 0(t0)

_fdt_parse_property_memory_reg_size_done:

_fdt_parse_property_memory_addr:

  # Skip if we already know the base address
  la    t0, fdt_memory_base_addr
  ld    t0, 0(t0)
  bnez  t0, _fdt_parse_property_exit

  # Get the address by parsing the string
  move  a0, s0
  add   a0, a0, 7
  li    a1, 16
  jal   parse_int
  la    t0, fdt_memory_base_addr
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_mmio:
  # Check for the "reg" property
  move  a0, s1
  la    a1, str_fdt_check_prop_reg
  li    a2, 4
  jal   strncmp
  beqz  a0, _fdt_parse_property_mmio_addr

_fdt_parse_property_mmio_addr:

  # Pull the 'reg' value which is a <base, length> pair
  # The <base> part has a number of bytes given by "#address-cells" x 2
  # And the <length> part has "#size-cells" x 2 number of bytes

  # Get the number of address cells
  la    t1, fdt_address_cells
  ld    t1, 0(t1)

  # Read address
  lwu   a0, 0(s2)
  jal   toBE32
  li    t2, 1
  addi  s2, s2, 4
  beq   t1, t2, _fdt_parse_property_mmio_addr_commit

  # 64-bit address
  move  t2, a0
  lwu   a0, 0(s2)
  jal   toBE32
  sll   t2, t2, 32
  add   a0, a0, t2
  addi  s2, s2, 4

_fdt_parse_property_mmio_addr_commit:

  # Write the base address to the mmio device array
  # And increment the mmio device count
  # TODO: do not store if the fdt_mmio_count hits the maximum
  la    t0, fdt_mmio_base_addrs
  la    t1, fdt_mmio_count
  ld    t2, 0(t1)
  sll   t2, t2, 3
  add   t0, t0, t2
  srl   t2, t2, 3
  sd    a0, 0(t0)

  # Get the number of size cells
  la    t1, fdt_size_cells
  ld    t1, 0(t1)

  # Read size
  lwu   a0, 0(s2)
  jal   toBE32
  li    t2, 1
  addi  s2, s2, 4
  beq   t1, t2, _fdt_parse_property_mmio_length_commit

  # 64-bit size
  move  t2, a0
  lwu   a0, 0(s2)
  jal   toBE32
  sll   t2, t2, 32
  add   a0, a0, t2
  addi  s2, s2, 4

_fdt_parse_property_mmio_length_commit:
  # Write the length to the mmio device array
  # And increment the mmio device count
  # TODO: do not store if the fdt_mmio_count hits the maximum
  la    t0, fdt_mmio_lengths
  la    t1, fdt_mmio_count
  ld    t2, 0(t1)
  sll   t2, t2, 3
  add   t0, t0, t2
  srl   t2, t2, 3
  addi  t2, t2, 1
  sd    t2, 0(t1)
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_framebuffer:
  # Check for the "reg" property
  move  a0, s1
  la    a1, str_fdt_check_prop_reg
  li    a2, 4
  jal   strncmp
  beqz  a0, _fdt_parse_property_framebuffer_addr

  # Check for the "width" property
  move  a0, s1
  la    a1, str_fdt_check_prop_width
  li    a2, 6
  jal   strncmp
  beqz  a0, _fdt_parse_property_framebuffer_width

  # Check for the "height" property
  move  a0, s1
  la    a1, str_fdt_check_prop_height
  li    a2, 7
  jal   strncmp
  beqz  a0, _fdt_parse_property_framebuffer_height

  j _fdt_parse_property_exit

_fdt_parse_property_framebuffer_width:

  # Pull the 'width' value which is a simple 32-bit word.
  lwu   a0, 0(s2)
  jal   toBE32

  # Write the value
  la    t0, fdt_framebuffer_width
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_framebuffer_height:

  # Pull the 'height' value which is a simple 32-bit word.
  lwu   a0, 0(s2)
  jal   toBE32

  # Write the value
  la    t0, fdt_framebuffer_height
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_framebuffer_addr:

  # Pull the 'reg' value which is a <base, length> pair
  # The <base> part has a number of bytes given by "#address-cells" x 2
  # And the <length> part has "#size-cells" x 2 number of bytes

  # Get the number of address cells
  la    t1, fdt_address_cells
  ld    t1, 0(t1)

  # Read address
  lwu   a0, 0(s2)
  jal   toBE32
  li    t2, 1
  beq   t1, t2, _fdt_parse_property_framebuffer_addr_commit

  # 64-bit address
  move  t2, a0
  lwu   a0, 4(s2)
  jal   toBE32
  sll   t2, t2, 32
  add   a0, a0, t2

_fdt_parse_property_framebuffer_addr_commit:
  # Write the base address
  la    t0, fdt_framebuffer_base_addr
  sd    a0, 0(t0)

  j _fdt_parse_property_exit

_fdt_parse_property_exit:
  pop   s3
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

.data

# Retain certain information discovered within the FDT

# FDT Header Information:
fdt_header_ptr:                   .dword  0
fdt_size:                         .dword  0
fdt_mem_rsrv_ptr:                 .dword  0
fdt_structure_ptr:                .dword  0
fdt_structure_length:             .dword  0
fdt_strings_ptr:                  .dword  0
fdt_strings_length:               .dword  0

# FDT base properties
fdt_address_cells:                .dword  2
fdt_size_cells:                   .dword  1
fdt_cpu_timebase_frequency:       .dword  0

# FDT regions of interest:
fdt_virtio_base_addrs:            .dword  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
fdt_virtio_irqs:                  .dword  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
fdt_virtio_irq_count:             .dword  0
fdt_virtio_count:                 .dword  0
fdt_clint_base_addr:              .dword  0
fdt_plic_base_addr:               .dword  0
fdt_framebuffer_base_addr:        .dword  0
fdt_memory_base_addr:             .dword  0
fdt_memory_length:                .dword  0
fdt_application_start:            .dword  0
fdt_application_end:              .dword  0
fdt_mmio_base_addrs:              .dword  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
fdt_mmio_lengths:                 .dword  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
fdt_mmio_count:                   .dword  0

# FDT properties of interest:
fdt_framebuffer_width:            .dword  0
fdt_framebuffer_height:           .dword  0

# FDT node names to check for
str_fdt_check_node_root:          .string ""
str_fdt_check_node_memory:        .string "memory@"
str_fdt_check_node_framebuffer:   .string "framebuffer@"
str_fdt_check_node_mmio:          .string "mmio@"
str_fdt_check_node_cpus:          .string "cpus"
str_fdt_check_node_virtio:        .string "virtio@"
str_fdt_check_node_clint:         .string "clint@"
str_fdt_check_node_chosen:        .string "chosen"
str_fdt_check_node_plic:          .string "plic@"

# FDT property names to check for
str_fdt_check_prop_reg:           .string "reg"
str_fdt_check_prop_width:         .string "width"
str_fdt_check_prop_height:        .string "height"
str_fdt_check_prop_timebase_freq: .string "timebase-frequency"
str_fdt_check_prop_address_cells: .string "#address-cells"
str_fdt_check_prop_size_cells:    .string "#size-cells"
str_fdt_check_prop_kernel_start:  .string "riscv,kernel-start"
str_fdt_check_prop_kernel_end:    .string "riscv,kernel-end"
str_fdt_check_prop_plic:          .string "riscv,plic0"
str_fdt_check_prop_interrupts_ex: .string "interrupts-extended"
