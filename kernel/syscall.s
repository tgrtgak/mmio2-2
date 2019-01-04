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
  nop                       # a0: 5
  nop                       # a0: 6
  nop                       # a0: 7
  nop                       # a0: 8
  nop                       # a0: 9
  j syscall_exit            # a0: 10
  nop                       # a0: 11
  nop                       # a0: 12
  nop                       # a0: 13
  nop                       # a0: 14
  nop                       # a0: 15
  nop                       # a0: 16
  nop                       # a0: 17
  nop                       # a0: 18
  nop                       # a0: 19
  nop                       # a0: 20
  nop                       # a0: 21
  nop                       # a0: 22
  nop                       # a0: 23
  nop                       # a0: 24
  nop                       # a0: 25
  nop                       # a0: 26
  nop                       # a0: 27
  nop                       # a0: 28
  nop                       # a0: 29
  nop                       # a0: 30
  nop                       # a0: 31
  nop                       # a0: 32
  nop                       # a0: 33
  nop                       # a0: 34
  nop                       # a0: 35
  nop                       # a0: 36
  nop                       # a0: 37
  nop                       # a0: 38
  nop                       # a0: 39
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
