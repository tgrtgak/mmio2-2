# This file handles all of the system calls we are making available to user
# applications.

.include "const.s"
.include "util.s"

.global syscall_init
.global syscall

.set SYSCALL_COUNT, 41

# The maximum number of characters in our line buffer
.set SYSCALL_LINE_BUFFER_MAX, 256

# The maximum digits of precision when printing floating-point values
.set SYSCALL_PRINT_FLOATING_POINT_PRECISION, 8

syscall_init:
  jr    ra

syscall:
  push  ra

  # Vector the system call to various things
  # We don't have a stack right now, so we might want one of those
  li    t0, SYSCALL_COUNT
  bgt   a7, t0, _syscall_error_no_shift
  bltz  a7, _syscall_error_no_shift

  # Call the appropriate system call
  la    t0, _syscall_table
  sll   a7, a7, 2   # multiply by 4 (the size of the j instruction)
  add   t0, a7, t0  # add this offset to our table's base address
  jalr  t0          # just to that particular 'j' instruction below
  
  move  a0, zero
  j     _syscall_exit

_syscall_error:
  srl   a7, a7, 2
_syscall_error_no_shift:
  li    a0, -1
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
  j syscall_sbrk            # a7: 9
  j syscall_exit            # a7: 10
  j _syscall_error          # a7: 11
  j _syscall_error          # a7: 12
  j _syscall_error          # a7: 13
  j _syscall_error          # a7: 14
  j _syscall_error          # a7: 15
  j _syscall_error          # a7: 16
  j _syscall_error          # a7: 17
  j _syscall_error          # a7: 18
  j _syscall_error          # a7: 19
  j _syscall_error          # a7: 20
  j _syscall_error          # a7: 21
  j _syscall_error          # a7: 22
  j _syscall_error          # a7: 23
  j _syscall_error          # a7: 24
  j _syscall_error          # a7: 25
  j _syscall_error          # a7: 26
  j _syscall_error          # a7: 27
  j _syscall_error          # a7: 28
  j _syscall_error          # a7: 29
  j syscall_get_system_time # a7: 30
  j _syscall_error          # a7: 31
  j _syscall_error          # a7: 32
  j _syscall_error          # a7: 33
  j _syscall_error          # a7: 34
  j _syscall_error          # a7: 35
  j _syscall_error          # a7: 36
  j _syscall_error          # a7: 37
  j _syscall_error          # a7: 38
  j _syscall_error          # a7: 39
  j syscall_srand           # a7: 40
  j syscall_rand            # a7: 41

# syscall_dump_regs(): Prints out CPU information
syscall_dump_regs:
  jr    ra

# syscall_sbrk(): Increases the size of heap by value in a0
syscall_sbrk:
  push  ra

  pop   ra
  jr    ra

# syscall_print_integer(): Prints the integer in a0
syscall_print_integer:
  push  ra
  li    a1, 10
  jal   print_int
  pop   ra
  jr    ra

# syscall_print_float(): Prints the float in fa0
syscall_print_float:
  push  ra
  push  s0
  push  s1
  push  s2

  # Pull out IEEE fields

  # Get the exponent
  fmv.x.s  s0, fa0
  srl   s0, s0, 23
  li    t1, 0x100
  and   t0, s0, t1 # Get the sign bit
  andi  s0, s0, 0xff

  # Interpret the sign bit
  beqz  t0, _syscall_print_float_continue
  la    a0, syscall_print_float_sign
  jal   console_writez
_syscall_print_float_continue:

  # Get the mantissa
  fmv.x.s  s1, fa0
  li    t1, 0x7fffff
  and   s1, s1, t1
  li    t1, 1
  sll   t1, t1, 23
  or    s1, s1, t1  # mantissa = (val & 0x7fffff) || 0x800000

  # First, we check for the special values
  # Zero is when the mantissa is 0x800000 and exponent is 0
  bnez  s0, _syscall_print_float_check_nan
  li    t0, 0x800000
  bne   s1, t0, _syscall_print_float_check_nan

  # This value is 0.0
  li    s0, 0
  li    s1, 0
  j     _syscall_print_float_prepare

_syscall_print_float_check_nan:
  # Infinity is where the exponent is all 1s and mantissa is 0
  li    t0, 0xff
  bne   s0, t0, _syscall_print_float_parse

  # If the mantissa 0, it is INF
  beqz  s1, _syscall_print_float_inf

  # Otherwise, it is NaN
  la    a0, syscall_print_float_NaN
  jal   console_writez
  j     _syscall_print_float_exit

_syscall_print_float_inf:
  # Print INF
  la    a0, syscall_print_float_INF
  jal   console_writez
  j     _syscall_print_float_exit

_syscall_print_float_parse:
  # Now, we get the integer part and fractional part
  # And we will print their integers the normal way
  # We will ensure that the integer part is in s0
  # and the fractional part is in s1 by the time we hit
  # the _syscall_print_float_print section.

  # Subtract the bias
  addi  s0, s0, -127

  # If the exponent is less than -52, the number is too small
  li    t0, -23
  bge   s0, t0, _syscall_print_float_check_upper
  li    s0, 0 # 0.0
  li    s1, 0
  j     _syscall_print_float_prepare

_syscall_print_float_check_upper:
  # If the exponent is greater or equal than 52, the number is too large
  # So, we just make the fractional unit 0
  li    t0, 23
  blt   s0, t0, _syscall_print_float_check_positive
  move  t0, s1
  li    t1, 23
  sub   t1, s0, t1
  sll   s0, t0, t1  # intPart = mantissa << (exp - 23)
  li    s1, 0 # xxx.0
  j     _syscall_print_float_prepare

_syscall_print_float_check_positive:
  # When the exponent is positive or zero, we can calculate the integer and
  # fractional values the normal way.
  bltz  s0, _syscall_print_float_smallest
  move  t0, s1
  li    t1, 23
  sub   t1, t1, s0
  srl   t2, t0, t1  # intPart = mantissa >> (23 - exp)

  addi  t0, s0, 1
  sll   t0, s1, t0
  li    t1, 0xffffff
  and   s1, t0, t1  # fracPart = (mantissa << (exp + 1)) & 0xffffff

  move  s0, t2
  j     _syscall_print_float_prepare

_syscall_print_float_smallest:
  # When the exponent is negative, the integer component is 0 and the value is
  # very small.

  li    t0, 0xffffff
  and   t0, s1, t0
  add   t1, s0, 1
  neg   t1, t1
  srl   s1, t0, t1 # fracPart = (mantissa & 0xffffff) >> (-(exp + 1))
  li    s0, 0      # intPart = 0
  j     _syscall_print_float_prepare

_syscall_print_float_prepare:
  # Adjust to a 64-bit IEEE mantissa
  sll   s1, s1, 29

  # Now, jump to the generic print implementation
  move  a0, s0
  move  a1, s1
  jal   syscall_print_floating_point

_syscall_print_float_exit:
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# syscall_print_double(): Prints the double in fa0
syscall_print_double:
  push  ra
  push  s0
  push  s1
  push  s2

  # Pull out IEEE fields

  # Get the exponent
  fmv.x.d  s0, fa0
  srl   s0, s0, 52
  li    t1, 0x800
  and   t0, s0, t1 # Get the sign bit
  andi  s0, s0, 0x7ff

  # Interpret the sign bit
  beqz  t0, _syscall_print_double_continue
  la    a0, syscall_print_float_sign
  jal   console_writez
_syscall_print_double_continue:

  # Get the mantissa
  fmv.x.d  s1, fa0
  sll   s1, s1, 12
  srl   s1, s1, 12
  li    t1, 1
  sll   t1, t1, 52
  or    s1, s1, t1  # mantissa = ((val << 12) >> 12) || 0x10000000000000

  # First, we check for the special values
  # Zero is when the mantissa is 0x10000000000000 and exponent is 0
  bnez  s0, _syscall_print_double_check_nan
  li    t0, 0x10000000000000
  bne   s1, t0, _syscall_print_double_check_nan

  # This value is 0.0
  li    s0, 0
  li    s1, 0
  j     _syscall_print_double_prepare

_syscall_print_double_check_nan:
  # Infinity is where the exponent is all 1s and mantissa is 0
  li    t0, 0x7ff
  bne   s0, t0, _syscall_print_double_parse

  # If the mantissa 0, it is INF
  beqz  s1, _syscall_print_double_inf

  # Otherwise, it is NaN
  la    a0, syscall_print_float_NaN
  jal   console_writez
  j     _syscall_print_double_exit

_syscall_print_double_inf:
  # Print INF
  la    a0, syscall_print_float_INF
  jal   console_writez
  j     _syscall_print_double_exit

_syscall_print_double_parse:
  # Now, we get the integer part and fractional part
  # And we will print their integers the normal way
  # We will ensure that the integer part is in s0
  # and the fractional part is in s1 by the time we hit
  # the _syscall_print_double_print section.

  # Subtract the bias
  addi  s0, s0, -1023

  # If the exponent is less than -52, the number is too small
  li    t0, -52
  bge   s0, t0, _syscall_print_double_check_upper
  li    s0, 0 # 0.0
  li    s1, 0
  j     _syscall_print_double_prepare

_syscall_print_double_check_upper:
  # If the exponent is greater or equal than 52, the number is too large
  # So, we just make the fractional unit 0
  li    t0, 52
  blt   s0, t0, _syscall_print_double_check_positive
  move  t0, s1
  li    t1, 52
  sub   t1, s0, t1
  sll   s0, t0, t1  # intPart = mantissa << (exp - 52)
  li    s1, 0 # xxx.0
  j     _syscall_print_double_prepare

_syscall_print_double_check_positive:
  # When the exponent is positive or zero, we can calculate the integer and
  # fractional values the normal way.
  bltz  s0, _syscall_print_double_smallest
  move  t0, s1
  li    t1, 52
  sub   t1, t1, s0
  srl   t2, t0, t1  # intPart = mantissa >> (52 - exp)

  addi  t0, s0, 1
  sll   t0, s1, t0
  li    t1, 0x1fffffffffffff
  and   s1, t0, t1  # fracPart = (mantissa << (exp + 1)) & 0x1fffffffffffff

  move  s0, t2
  j     _syscall_print_double_prepare

_syscall_print_double_smallest:
  # When the exponent is negative, the integer component is 0 and the value is
  # very small.

  li    t0, 0x1fffffffffffff
  and   t0, s1, t0
  add   t1, s0, 1
  neg   t1, t1
  srl   s1, t0, t1 # fracPart = (mantissa & 0x1fffffffffffff) >> (-(exp + 1))
  li    s0, 0      # intPart = 0
  j     _syscall_print_double_prepare

_syscall_print_double_prepare:
  move  a0, s0
  move  a1, s1
  jal   syscall_print_floating_point

_syscall_print_double_exit:
  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# syscall_print_floating_point(): Prints a generic floating point value
# a0: The integer part
# a1: The 64-bit IEEE mantissa (53 bits)
syscall_print_floating_point:
  push  ra
  push  s0
  push  s1
  push  s2

  move  s0, a0
  move  s1, a1

  # Pull out digits of the fractional part that's in s1 (up to X digits)
  li    s2, 0
_syscall_print_floating_point_fractional_loop:
  li    t0, SYSCALL_PRINT_FLOATING_POINT_PRECISION
  beq   s2, t0, _syscall_print_floating_point_fractional_loop_exit
  li    t0, 10
  mul   s1, s1, t0  # fracPart *= 10
  srl   t0, s1, 53
  andi  t0, t0, 0x0f
  la    t1, syscall_print_floating_point_buffer
  add   t1, t1, s2
  sb    t0, 0(t1)
  addi  s2, s2, 1
  li    t0, 0x1fffffffffffff
  and   s1, s1, t0 # fracPart &= 0x1fffffffffffff
  j     _syscall_print_floating_point_fractional_loop
_syscall_print_floating_point_fractional_loop_exit:

  # Round up last digit
  addi  s2, s2, -1
  la    t1, syscall_print_floating_point_buffer
  add   t1, t1, s2
  lb    t0, 0(t1)
  li    t1, 5
  blt   t0, t1, _syscall_print_floating_point_truncate

  # Round the second to last digit up to the first
_syscall_print_floating_point_round:
  add   s2, s2, -1
  la    t1, syscall_print_floating_point_buffer
  add   t1, t1, s2
  lb    t0, 0(t1)
  addi  t0, t0, 1
  li    t2, 10
  bne   t0, t2, _syscall_print_floating_point_round_exit
  sb    zero, 0(t1)
  beqz  s2, _syscall_print_floating_point_round_int
  j     _syscall_print_floating_point_round

_syscall_print_floating_point_round_int:
  addi  s0, s0, 1 # We increment the integer count. We rounded 0.9 to 1.0 here.
  addi  s2, s2, 1 # We will keep the buffer around for a fractional "0"
  li    t0, 0

_syscall_print_floating_point_round_exit:
  sb    t0, 0(t1)
  add   s2, s2, 1
  j     _syscall_print_floating_point_print

_syscall_print_floating_point_truncate:
  # Now, we truncate any ending zeros
  la    t1, syscall_print_floating_point_buffer
  add   t1, t1, s2
  lb    t0, 0(t1)
  bnez  t0, _syscall_print_floating_point_print
  addi  s2, s2, -1
  bnez  s2, _syscall_print_floating_point_truncate
  addi  s2, s2, 1

_syscall_print_floating_point_print:
  # Print the integer part provided in s0
  move  a0, s0
  li    a1, 10
  jal   print_int

  # Followed by the delimiter (a '.' perhaps)
  la    a0, syscall_print_float_delim
  jal   console_writez

  # Up to 's2' number of digits, print the fractional buffer
  li    s0, 0
_syscall_print_floating_point_print_fractional:
  beqz  s2, _syscall_print_floating_point_exit
  la    t0, syscall_print_floating_point_buffer
  add   t0, t0, s0
  lbu   a0, 0(t0)
  li    a1, 10
  jal   print_int
  addi  s2, s2, -1
  addi  s0, s0, 1
  j     _syscall_print_floating_point_print_fractional

_syscall_print_floating_point_exit:
  pop   s2
  pop   s1
  pop   s0
  pop   ra
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

  # parse_int(...) returns the integer in a0, so we will automatically, too
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
  syscall_print_float_NaN: .asciz "NaN"
  syscall_print_float_INF: .asciz "INF"
  syscall_print_float_sign: .asciz "-"
  syscall_print_float_delim: .asciz "."
  syscall_print_floating_point_buffer: .fill SYSCALL_PRINT_FLOATING_POINT_PRECISION + 1, 1, 0
