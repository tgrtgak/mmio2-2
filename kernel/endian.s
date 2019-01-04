# This file has routines for swapping endianness.

.include "const.s"
.include "util.s"

.global toBE64
.global toBE32
.global toBE16

.text

# Naive :) in order to reduce the register usage.

# toBE64(a0): Reverses the byte order of a 64-bit value in a0.
#
# Will not clobber anything but a0.
#
# Arguments:
#   a0: The 64-bit number to reverse.
#
# Returns
#   a0: The updated value.
toBE64:
  push  s0
  push  s1
  push  s2
  push  s3

  # Retain the original number
  move  s0, a0

  # Swap outer bytes
  sll   s0, s0, 56      # Shift left 56
  li    s1, 0xff00000000000000
  and   s2, s1, s0      # Mask out first byte

  move  s0, a0
  srl   s0, s0, 56
  li    s1, 0xff
  and   s1, s1, s0      # Mask out last byte
  or    s3, s2, s1      # Craft our output

  # Swap inner bytes
  move  s0, a0
  sll   s0, s0, 40
  li    s1, 0xff000000000000
  and   s2, s1, s0

  move  s0, a0
  srl   s0, s0, 40
  li    s1, 0xff00
  and   s1, s1, s0
  or    s2, s1, s2
  or    s3, s3, s2

  # Swap inner-er bytes
  move  s0, a0
  sll   s0, s0, 24
  li    s1, 0xff0000000000
  and   s2, s1, s0

  move  s0, a0
  srl   s0, s0, 24
  li    s1, 0xff0000
  and   s1, s1, s0
  or    s2, s1, s2
  or    s3, s3, s2

  # Swap inner-est bytes
  move  s0, a0
  sll   s0, s0, 8
  li    s1, 0xff00000000
  and   s2, s1, s0

  move  s0, a0
  srl   s0, s0, 8
  li    s1, 0xff000000
  and   s1, s1, s0
  or    s2, s1, s2
  or    s3, s3, s2

  # Return answer
  move  a0, s3

  pop   s3
  pop   s2
  pop   s1
  pop   s0
  jr    ra

# toBE32(a0): Reverses the byte order of a 32-bit value in a0.
#
# Will not clobber anything but a0.
#
# Arguments:
#   a0: The 32-bit number to reverse.
#
# Returns
#   a0: The updated value.
toBE32:
  push  s0
  push  s1
  push  s2
  push  s3

  # Retain the original number
  move  s0, a0

  # Swap outer bytes
  sll   s0, s0, 24      # Shift left 24
  li    s1, 0xff000000
  and   s2, s1, s0      # Mask out first byte

  move  s0, a0
  srl   s0, s0, 24
  li    s1, 0xff
  and   s1, s1, s0      # Mask out last byte
  or    s3, s2, s1      # Craft our output

  # Swap inner bytes
  move  s0, a0
  sll   s0, s0, 8
  li    s1, 0xff0000
  and   s2, s1, s0

  move  s0, a0
  srl   s0, s0, 8
  li    s1, 0xff00
  and   s1, s1, s0
  or    s2, s1, s2
  or    s3, s3, s2

  # Return answer
  move  a0, s3

  pop   s3
  pop   s2
  pop   s1
  pop   s0
  jr    ra

# toBE16(a0): Reverses the byte order of a 16-bit value in a0.
#
# Will not clobber anything but a0.
#
# Arguments:
#   a0: The 16-bit number to reverse.
#
# Returns
#   a0: The updated value.
toBE16:
  push  s0
  push  s1

  move  s0, a0
  sll   s0, s0, 8
  li    s1, 0xff00
  and   s0, s0, s1
  srl   a0, a0, 8
  and   a0, a0, 0xff
  or    a0, a0, s0

  pop   s1
  pop   s0
  jr    ra
