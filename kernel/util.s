# This file contains common macros and such.

.macro push register
  addi  sp, sp, -8
  sd    \register, 0(sp)
.endm

.macro pop  register
  ld    \register, 0(sp)
  addi  sp, sp, 8
.endm

.macro pushd
  push  ra
  push  a0
  push  a1
  push  a2
  push  a3
  push  t0
  push  t1
  push  t2
  push  t3
  push  t4
  push  t5
  push  t6
.endm

.macro popd
  pop   t6
  pop   t5
  pop   t4
  pop   t3
  pop   t2
  pop   t1
  pop   t0
  pop   a3
  pop   a2
  pop   a1
  pop   a0
  pop   ra
.endm

.macro print_dec register
  pushd

  move  a0, \register
  li    a1, 10

  jal   print_int

  popd
.endm

.macro print_hex register
  pushd

  move  a0, \register
  li    a1, 16

  jal   print_int

  popd
.endm

.macro print_bin register
  pushd

  move  a0, \register
  li    a1, 2

  jal   print_int

  popd
.endm

# Aligns a register to a 64-bit (8 byte) boundary
.macro align64 register
  add \register, \register, 7
  and \register, \register, -8
.endm

# Aligns a register to a 32-bit (4 byte) boundary
.macro align32 register
  add \register, \register, 3
  and \register, \register, -4
.endm

# Aligns a register to a 16-bit (2 byte) boundary
.macro align16 register
  add \register, \register, 1
  and \register, \register, -2
.endm

# Aligns a register to the page size
.macro alignPage register
  push  t0
  li    t0, PAGE_SIZE
  add   t0, t0, -1
  add   \register, \register, t0 # REG = REG + (PAGE_SIZE-1)
  not   t0, t0
  and   \register, \register, t0 # REG = REG & (-PAGE_SIZE)
  pop   t0
.endm

# Aligns a register to the page size
.macro alignPageDown register
  push  t0
  li    t0, PAGE_SIZE
  add   t0, t0, -1
  not   t0, t0
  and   \register, \register, t0 # REG = REG & (-PAGE_SIZE)
  pop   t0
.endm
