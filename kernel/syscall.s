# This file handles all of the system calls we are making available to user
# applications.

.include "const.s"
.include "util.s"

.global syscall_init
.global syscall

.set SYSCALL_COUNT, 41

# The maximum number of characters in our line buffer
.set SYSCALL_LINE_BUFFER_MAX, 256

syscall_init:
  jr    ra

syscall:
  push  ra

  # Vector the system call to various things
  # We don't have a stack right now, so we might want one of those
  li    t0, SYSCALL_COUNT
  bgt   a7, t0, _syscall_error

  # Call the appropriate system call
  la    t0, _syscall_table
  sll   a7, a7, 2   # multiply by 4 (the size of the j instruction)
  add   t0, a7, t0  # add this offset to our table's base address
  jalr  t0          # just to that particular 'j' instruction below

  j     _syscall_exit

_syscall_error:
  j     _syscall_exit

_syscall_exit:
  pop   ra
  jr    ra

# A jump table. This is a trick to make selecting these system calls a bit
# easier. It is kind of like what C switch statements turn into. Kinda.
_syscall_table:
  j syscall_dump_regs       # a7: 0
  j syscall_print_integer   # a7: 1
  j syscall_print_float     # a7: 2
  j syscall_print_double    # a7: 3
  j syscall_print_string    # a7: 4
  j syscall_read_integer    # a7: 5
  j syscall_read_float      # a7: 6
  j syscall_read_double     # a7: 7
  j syscall_read_string     # a7: 8
  jr ra                     # a7: 9
  j syscall_exit            # a7: 10
  jr ra                     # a7: 11
  jr ra                     # a7: 12
  jr ra                     # a7: 13
  jr ra                     # a7: 14
  jr ra                     # a7: 15
  jr ra                     # a7: 16
  jr ra                     # a7: 17
  jr ra                     # a7: 18
  jr ra                     # a7: 19
  jr ra                     # a7: 20
  jr ra                     # a7: 21
  jr ra                     # a7: 22
  jr ra                     # a7: 23
  jr ra                     # a7: 24
  jr ra                     # a7: 25
  jr ra                     # a7: 26
  jr ra                     # a7: 27
  jr ra                     # a7: 28
  jr ra                     # a7: 29
  j syscall_get_system_time # a7: 30
  jr ra                     # a7: 31
  jr ra                     # a7: 32
  jr ra                     # a7: 33
  jr ra                     # a7: 34
  jr ra                     # a7: 35
  jr ra                     # a7: 36
  jr ra                     # a7: 37
  jr ra                     # a7: 38
  jr ra                     # a7: 39
  j syscall_srand           # a7: 40
  j syscall_rand            # a7: 41

# syscall_dump_regs(): Prints out CPU information
syscall_dump_regs:
  jr    ra

# syscall_print_integer(): Prints the integer in a0
syscall_print_integer:
  push  ra
  li    a1, 10
  jal   print_int
  pop   ra
  jr    ra

# syscall_print_float(): Prints the float in f0
syscall_print_float:
  jr    ra

# syscall_print_double(): Prints the double in f0
syscall_print_double:
  jr    ra

# syscall_print_string(): Prints the zero-terminated string in a0
syscall_print_string:
  push  ra
  jal   console_writez
  pop   ra
  jr    ra

# syscall_read_integer(): Reads input until a newline and parses integer to a0
syscall_read_integer:
  push  ra

  # Read the string
  la    a0, syscall_line_buffer
  li    a1, SYSCALL_LINE_BUFFER_MAX
  jal   syscall_read_string

  # And then parse the integer
  la    a0, syscall_line_buffer
  li    a1, 10
  jal   parse_int

  # parse_int(...) returns the integer in a0, so we will too
  pop   ra
  jr    ra

# syscall_read_float(): Reads input until a newline and parses float to f0
syscall_read_float:
  jr    ra

# syscall_read_double(): Reads input until a newline and parses double to f0
syscall_read_double:
  jr    ra

# syscall_read_string(): Reads input until a newline and writes to memory at a0
syscall_read_string:
  push  ra
  push  s0
  push  s1

  move  s0, a0
  move  s1, a1

  # Enable interrupts (allows keyboard events to trigger)
  jal   trap_enable_interrupts

  # Read the line
  move  a0, s0
  move  a1, s1
  jal   keyboard_read_line

  pop   s1
  pop   s0
  pop   ra
  jr    ra

syscall_exit:
  jal   exit

syscall_get_system_time:
  push  ra
  push  s0

  jal   rtc_get_mtime
  move  s0, a0
  # The resolution of the TinyEmu simulator is
  # 10Mhz, therefore if we divide by ten we get
  # microseconds, and milliseconds dividing by
  # 10000.

  # We can query that from the "cpus/timebase-frequency" in the FDT
  jal   fdt_get_cpu_timebase_frequency
  # a0: The cycles per second of the CPU
  # s0: The total cycles executed so far
  li    t0, 1000
  divu  a0, a0, t0  # give me the cycles per millisecond of the CPU
  div   a0, s0, a0  # give me the total milliseconds of boot time

  pop   s0
  pop   ra
  jr    ra

syscall_srand:
  push  ra
  jal   random_set_seed
  pop   ra
  jr    ra

syscall_rand:
  push  ra
  jal   random_get_word
  pop   ra
  jr    ra

.data

  syscall_line_buffer: .fill SYSCALL_LINE_BUFFER_MAX + 1, 1, 0
