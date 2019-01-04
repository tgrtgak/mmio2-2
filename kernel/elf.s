# This file reads ELF headers and loads an application.

# This will let our kernel read in assembly or C or anything else, really.

.include "const.s"
.include "util.s"

.global elf_load

.set ELF_MAGIC,             0x464c457f
.set ELF_CLASS_64,          0x2
.set ELF_ENDIAN_LITTLE,     0x1
.set ELF_ISA_RISCV,         0xf3

.set ELF_PROGRAM_TYPE_LOAD, 0x1

# elf_load(): Loads an ELF binary at the given location.
#
# Arguments
#   a0: Address of application binary to load
#   a1: The root page table to map in the application.
#
# Returns
#   a0: The address of the entrypoint for the program. (or -1 if it failed
#       to load)
elf_load:
  push  ra
  push  s0
  push  s1
  push  s2

  move  s0, a0
  move  s2, a1

  # Check the ELF header for the right type of program
  jal   elf_validate
  bnez  a0, _elf_load_error

  # The ELF header validates correctly!
  # This means: We have a 64-bit, little-endian RISC-V program targetting UNIX

  # s1: Get the entrypoint from the ELF header
  ld    s1, 0x18(s0)

  # Load each program segment
  # This is assuming the program's binary is continuous in physical memory.
  move  a0, s0       # the physical address of the program
  jal   paging_vaddr_to_paddr
  move  a3, a0
  ld    a0, 0x20(s0)
  add   a0, a0, s0   # program header address
  lhu   a1, 0x38(s0) # program header entry count
  lhu   a2, 0x36(s0) # program header entry size
  move  a4, s2       # the root page table to map these into
  jal   elf_load_segments

  # Get the program vaddr to load to and its size
  # (a0: vaddr, a1: size)

  # Return the entrypoint
  move  a0, s1
  j     _elf_load_exit

_elf_load_error:
  la    a0, str_elf_error
  jal   console_writez

  la    a0, str_elf_load_error
  jal   console_writez

  # Return -1
  li    a0, -1

_elf_load_exit:

  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# elf_validate(): Looks at the ELF header and determines if we can run it.
#
# Arguments
#   a0: Address of application binary to load
#
# Returns
#   a0: 0, if successful, -1 if not
elf_validate:
  push  ra

  # Read header: MAGIC bytes (should be ELF_MAGIC)
  lwu   t0, 0x0(a0)
  li    t1, ELF_MAGIC
  bne   t0, t1, _elf_validate_magic_error

  # Read header: Class bytes (should be ELF_CLASS_64)
  lbu   t0, 0x4(a0)
  li    t1, ELF_CLASS_64
  bne   t0, t1, _elf_validate_class_error

  # Read header: Endianness (should be ELF_ENDIAN_LITTLE)
  lbu   t0, 0x5(a0)
  li    t1, ELF_ENDIAN_LITTLE
  bne   t0, t1, _elf_validate_endianness_error

  # Read header: ABI (should be 0)
  lbu   t0, 0x07(a0)
  bnez  t0, _elf_validate_abi_error

  # Read header: Architecture (should be ELF_ISA_RISCV)
  lhu   t0, 0x12(a0)
  li    t1, ELF_ISA_RISCV
  bne   t0, t1, _elf_validate_isa_error

  li    a0, 0
  j     _elf_validate_exit

_elf_validate_magic_error:
  la    a0, str_elf_error
  jal   console_writez

  la    a0, str_elf_magic_invalid
  jal   console_writez

  j     _elf_validate_error_exit

_elf_validate_class_error:
  la    a0, str_elf_error
  jal   console_writez

  la    a0, str_elf_class_invalid
  jal   console_writez

  j     _elf_validate_error_exit

_elf_validate_endianness_error:
  la    a0, str_elf_error
  jal   console_writez

  la    a0, str_elf_endianness_invalid
  jal   console_writez

  j     _elf_validate_error_exit

_elf_validate_abi_error:
  la    a0, str_elf_error
  jal   console_writez

  la    a0, str_elf_abi_invalid
  jal   console_writez

  j     _elf_validate_error_exit

_elf_validate_isa_error:
  la    a0, str_elf_error
  jal   console_writez

  la    a0, str_elf_isa_invalid
  jal   console_writez

  j     _elf_validate_error_exit

_elf_validate_error_exit:

  li    a0, -1

_elf_validate_exit:

  pop   ra
  jr    ra

# elf_load_segments(program_header_ptr, count, size): Loads all applicable
#   program segments into memory and maps them to userspace.
#
# Arguments
#   a0: The address of the program header list.
#   a1: The number of program headers.
#   a2: The size of each program header entry. (the list stride length)
#   a3: The physical address of the binary
#   a4: The root page table to map each segment into
elf_load_segments:
  push  ra
  push  s0
  push  s1
  push  s2
  push  s3
  push  s4

  move  s0, a0
  move  s1, a1
  move  s2, a2
  move  s3, a3
  move  s4, a4

_elf_load_segments_loop:
  # For each program entry that is a LOAD type, we will map that memory into
  # our userspace environment.
  
  lwu   t0, 0x00(s0)
  li    t1, ELF_PROGRAM_TYPE_LOAD
  bne   t0, t1, _elf_load_segments_continue

  # Get the offset in our ELF file for this segment
  ld    a0, 0x08(s0)
  add   a3, s3, a0  # Get the physical address we want to map

  # And the target virtual address
  ld    a1, 0x10(s0)

  # And the size of the segment
  ld    t0, 0x28(s0)

  # Copy ELF binary data from offset to destination
  # Create page mapping from vaddr to destination
  move  a2, a1
  move  a1, a3
  move  a0, s4
  move  a3, t0
  li    a4, PTE_USER | PTE_READ | PTE_EXECUTE | PTE_WRITE
  jal   paging_map_range

  #la    a0, str_elf_debug
  #jal   console_writez

  #la    a0, str_elf_debug_load_segment
  #jal   console_writez

_elf_load_segments_continue:

  add   s0, s0, s2
  add   s1, s1, -1
  bgtz  s1, _elf_load_segments_loop

_elf_load_segments_exit:

  pop   s4
  pop   s3
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

.data
.balign 8, 0
  # Base error string
  str_elf_error:              .string "ELF: Error: "

  # Load Errors
  str_elf_load_error:         .string "Could not load the application\n"

  # Validation Errors
  str_elf_magic_invalid:      .string "Magic number is invalid\n"
  str_elf_abi_invalid:        .string "ABI not System-V\n"
  str_elf_class_invalid:      .string "We do not support 32-bit programs\n"
  str_elf_endianness_invalid: .string "We do not support 32-bit programs\n"
  str_elf_isa_invalid:        .string "Not targetting a RISC-V ISA.\n"

  # Base debug string
  str_elf_debug:              .string "ELF: Debug: "

  # Debug strings
  str_elf_debug_load_segment: .string "Loading segment\n"
