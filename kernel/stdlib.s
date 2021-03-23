.include "util.s"

.global memzero
.global memcpy
.global memset
.global strcpy
.global strlen
.global strncmp
.global strcmp
.global print
.global println
.global print_int
.global parse_int
.global print_int_padded

# Copies one buffer to another.
#
# Arguments
#   a0: address of destination buffer
#   a1: address of source buffer
#   a2: length of buffer
memcpy:
  # This is a bit slow... :)
  blez  a2, _memcpy_exit
  lbu   t0, 0(a1)
  sb    t0, 0(a0)
  add   a2, a2, -1
  add   a0, a0, 1
  add   a1, a1, 1
  j     memcpy

_memcpy_exit:
  jr    ra

# Overwrites the given buffer with the given byte.
#
# Arguments
#   a0: address of destination buffer
#   a1: byte value to use
#   a2: length of buffer
memset:
  # This is also a bit slow... :)
  blez  a2, _memset_exit
  sb    a1, 0(a0)
  add   a2, a2, -1
  add   a0, a0, 1
  j     memset

_memset_exit:
  jr    ra

# Zeroes (clears) the given buffer.
#
# Arguments
#   a0: address of destination buffer
#   a1: length of buffer
memzero:
  move  a2, a1
  move  a1, zero
  j     memset

# Copies one zero-terminated string to another.
#
# Arguments
#   a0: the address of the destination string
#   a1: the address of the source string
strcpy:
  push  ra
  push  s0

  # I'll just do this naively because I have a life to live.
  # Obviously you can do this without two traversals.
  # Get over yourself. :)

  # Get the length of the source string
  move  s0, a0
  move  a0, a1
  jal   strlen

  # memcpy() that length (plus 1)
  move  a2, a0
  add   a2, a2, 1
  move  a0, s0
  jal   memcpy

  pop   s0
  pop   ra
  jr    ra

# Determines the length of a zero-terminated string.
#
# Arguments
#   a0: the address of the string
#
# Returns
#   a0: The length of the string
strlen:
  move  t1, zero

_strlen_loop:
  lbu   t0, 0(a0)
  beqz  t0, _strlen_exit

  add   t1, t1, 1
  add   a0, a0, 1

  j     _strlen_loop

_strlen_exit:
  move  a0, t1
  jr    ra

# Determines if a string matches another up to a certain number of characters.
#
# Arguments
#   a0: The first string.
#   a1: The second string.
#   a2: The number of characters to check
#
# Returns
#   a0: <0: The first character that does not match has a lower value in a0
#           than a1.
#       =0: The strings are equal.
#       >0: The first character that does not match has a greater value in a0
#           than a1.
strncmp:
  # If we ran out of characters, then they are equal!
  bleu  a2, zero, _strncmp_equal

  # Check each character
  lbu   t0, 0(a0)
  lbu   t1, 0(a1)

  beq   t0, t1, _strncmp_continue

  # Subtract them to see how different they are
  sub   a0, t0, t1

  # Return that difference
  j     _strncmp_exit

_strncmp_continue:
  # Equal!

  # If they are both 0, then quit. We're done!
  beqz  t0, _strncmp_equal

  # Otherwise, continue
  add   a0, a0, 1
  add   a1, a1, 1
  add   a2, a2, -1
  j     strncmp

_strncmp_equal:
  li    a0, 0
  j     _strncmp_exit

_strncmp_exit:
  jr    ra

# Determines if a string matches another.
#
# Arguments
#   a0: The first string.
#   a1: The second string.
#
# Returns
#   a0: <0: The first character that does not match has a lower value in a0
#           than a1.
#       =0: The strings are equal.
#       >0: The first character that does not match has a greater value in a0
#           than a1.
strcmp:
  li    a2, -1
  j     strncmp

# Prints an integer
#
# Arguments
#   a0: The integer to print
#   a1: The numeric base
print_int:
  push  ra

  move  a2, zero
  jal   print_int_padded

  pop   ra
  jr    ra

# parse_int(str, radix): Parses the string and returns the given integer.
#
# Arguments
#   a0: The address of the string to parse.
#   a1: The expected radix of the integer.
#
# Returns
#   a0: The parsed integer
parse_int:
  push  s0
  push  s1

  # s0: 0 if positive, 1 if negative
  li    s0, 0

  # s1: Our accumulator (starts at 0)
  li    s1, 0

  # First, check if the first character is a negative.
  lbu   t0, 0(a0)
  li    t1, '-'
  bne   t0, t1, _parse_int_loop

  # Negative. Remember this.
  li    s0, 1
  add   a0, a0, 1

_parse_int_loop:
  # If the character is within 0-9, then get that value
  lbu   t0, 0(a0)
  li    t1, '9'
  bgtu  t0, t1, _parse_int_not_arabic
  li    t1, '0'
  bltu  t0, t1, _parse_int_not_arabic

  # It is 0-9, so subtract '0' from it
  sub   t0, t0, t1

  # Multiply our accumulator by the radix
  mul   s1, s1, a1

  # Add this to the accumulated number
  add   s1, s1, t0

  add   a0, a0, 1
  j     _parse_int_loop

_parse_int_not_arabic:

  # Check if it is within a-z (or A-Z) instead
  lbu   t0, 0(a0)
  li    t1, 'z'
  bgtu  t0, t1, _parse_int_not_lower_alpha
  li    t1, 'a'
  bltu  t0, t1, _parse_int_not_lower_alpha

  # It is a-z, so subtract 'a' from it
  sub   t0, t0, t1

  # Multiply our accumulator by the radix
  mul   s1, s1, a1

  # Add this to the accumulated number
  add   s1, s1, t0
  # Add 10, for the 'a'
  add   s1, s1, 10

  add   a0, a0, 1
  j     _parse_int_loop

_parse_int_not_lower_alpha:

  # Check if it is within A-Z instead
  lbu   t0, 0(a0)
  li    t1, 'Z'
  bgtu  t0, t1, _parse_int_not_alpha
  li    t1, 'A'
  bltu  t0, t1, _parse_int_not_alpha

  # It is A-Z, so subtract 'A' from it
  sub   t0, t0, t1

  # Multiply our accumulator by the radix
  mul   s1, s1, a1

  # Add this to the accumulated number
  add   s1, s1, t0
  # Add 10, for the 'A'
  add   s1, s1, 10

  add   a0, a0, 1
  j     _parse_int_loop

_parse_int_not_alpha:
  # We could recover any errors... but we'll just quit for now.

_parse_int_break:
  # Was our original number negative?
  beqz  s0, _parse_int_exit

  li    t0, -1
  mul   s1, s1, t0

_parse_int_exit:
  # Return s1, our accumulator
  move  a0, s1

  pop   s1
  pop   s0
  jr    ra
# Prints an integer in binary/hexadecimal, padding the value with zeros to 32 or 64 bits
#
# Arguments
#   a0: The integer to print
#   a1: Radix
#   a2: Width to pad string 
print_int_padded:
  push  ra
  push  s0
  push  s1
  push  s2

  # Store a0 and a1 so that we have no side effects
  move  s1, a0
  move  s2, a1

  # Create a string (on the stack)
  add   sp, sp, -128

 # If the radix is 10 (decimal base)   
 # Remember if our number is negative   
  li    s0, 0   
  li    t0, 10   
  bne   a1, t0, _print_int_padded_render_string   
  slt   s0, a0, zero

_print_int_padded_render_string:
  # We will build our string from the right to the left.
  # (we will leave 1 byte a zero, to terminate the string, when the loop starts)
  add   t1, sp, 127
  sb    zero, 0(t1)

_print_int_padded_render_character:
  # Go to the next character in our string
  # Remember: we are moving left!
  add   t1, t1, -1

  # Determine the next digit (mod by radix)
  remu  t2, a0, a1

  # Lookup the character
  la    t3, str_print_int_lookup
  add   t3, t3, t2
  lbu   t4, 0(t3)
  
  # Write the character
  sb    t4, 0(t1)

  # Get the rest of the number (divide by radix)
  divu  a0, a0, a1

  # If our number is not 0, well, keep printing characters!
  bnez  a0, _print_int_padded_render_character

_print_int_padded_zeros:
  sub   t0, t1, sp          #t1 - sp was initially 127   
  li    t2, 127             #as we added characters, t1 decremented by 1, so their difference decremented by 1
  sub   t0, t2, t0          #so total number of chars is 127 - (t1's current value - sp) 

  sub   t0, a2, t0
_print_int_padded_zeros_loop:
  blez  t0, _print_int_padded_finalize_string
  add   t1, t1, -1
  li    t2, '0'
  sb    t2, 0(t1)

  add   t0, t0, -1
  j     _print_int_padded_zeros_loop

_print_int_padded_finalize_string:
  # Write out a '-' if the value was negative
  beqz  s0, _print_int_padded_finalize_hex_string
  add   t1, t1, -1
  li    t2, '-'
  sb    t2, 0(t1)

_print_int_padded_finalize_hex_string:
  li    t2, 16
  bne   a1, t2, _print_int_padded_finalize_binary_string

  add   t1, t1, -1
  li    t2, 'x'
  sb    t2, 0(t1)

  add   t1, t1, -1
  li    t2, '0'
  sb    t2, 0(t1)

  j     _print_int_padded_write_string

_print_int_padded_finalize_binary_string:
  li    t2, 2
  bne   a1, t2, _print_int_padded_write_string

  add   t1, t1, -1
  li    t2, 'b'
  sb    t2, 0(t1)

  add   t1, t1, -1
  li    t2, '0'
  sb    t2, 0(t1)

  # Print our string
_print_int_padded_write_string:
  move  a0, t1
  jal   console_writez

  # Deallocate our string
  add   sp, sp, 128

  move  a0, s1
  move  a1, s2

  pop   s2
  pop   s1
  pop   s0
  pop   ra
  jr    ra

# print(str)
print:
  j console_writez

# println(str)
println:
  push  ra
  jal   console_writez
  la    a0, str_print_newline
  jal   console_writez
  pop   ra
  jr    ra

.data
.balign 8, 0
  # Lookup table for print
str_print_int_lookup: .ascii "0123456789abcdefg"
str_print_newline:    .string "\n"
