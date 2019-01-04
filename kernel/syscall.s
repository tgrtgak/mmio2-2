# This file handles all of the system calls we are making available to user
# applications.

.include "const.s"
.include "util.s"

.global syscall_init
.global syscall

.set SYSCALL_COUNT,   41

syscall_init:
  jr    ra

syscall:
  push  ra

  # Vector the system call to various things
  # We don't have a stack right now, so we might want one of those
  li    t0, SYSCALL_COUNT
  bgt   a0, t0, _syscall_error

  # Call the appropriate system call
  la    t0, _syscall_table
  sll   a0, a0, 2   # multiply by 4 (the size of the j instruction)
  add   t0, a0, t0  # add this offset to our table's base address
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
  j syscall_dump_regs       # a0: 0
  j syscall_print_integer   # a0: 1
  j syscall_print_float     # a0: 2
  j syscall_print_double    # a0: 3
  j syscall_print_string    # a0: 4
  jr ra                     # a0: 5
  jr ra                     # a0: 6
  jr ra                     # a0: 7
  jr ra                     # a0: 8
  jr ra                     # a0: 9
  j syscall_exit            # a0: 10
  jr ra                     # a0: 11
  jr ra                     # a0: 12
  jr ra                     # a0: 13
  jr ra                     # a0: 14
  jr ra                     # a0: 15
  jr ra                     # a0: 16
  jr ra                     # a0: 17
  jr ra                     # a0: 18
  jr ra                     # a0: 19
  jr ra                     # a0: 20
  jr ra                     # a0: 21
  jr ra                     # a0: 22
  jr ra                     # a0: 23
  jr ra                     # a0: 24
  jr ra                     # a0: 25
  jr ra                     # a0: 26
  jr ra                     # a0: 27
  jr ra                     # a0: 28
  jr ra                     # a0: 29
  j syscall_get_system_time # a0: 30
  jr ra                     # a0: 31
  jr ra                     # a0: 32
  jr ra                     # a0: 33
  jr ra                     # a0: 34
  jr ra                     # a0: 35
  jr ra                     # a0: 36
  jr ra                     # a0: 37
  jr ra                     # a0: 38
  jr ra                     # a0: 39
  j syscall_srand           # a0: 40
  j syscall_rand            # a0: 41

# syscall_dump_regs(): Prints out CPU information
syscall_dump_regs:
  jr    ra

# syscall_print_integer(): Prints the integer in a1
syscall_print_integer:
  push  ra
  move  a0, a1
  li    a1, 10
  jal   print_int
  pop   ra
  jr    ra

# syscall_print_float(): Prints the float in a1
syscall_print_float:
  jr    ra

# syscall_print_double(): Prints the double in a1
syscall_print_double:
  jr    ra

# syscall_print_string(): Prints the zero-terminated string in a1
syscall_print_string:
  push  ra
  move  a0, a1
  jal   console_writez
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
  move  a0, a1
  jal   random_set_seed
  pop   ra
  jr    ra

syscall_rand:
  push  ra
  move  a0, a1
  jal   random_get_word
  pop   ra
  jr    ra
