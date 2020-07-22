# Randomly write some colors to the screen
# Probably should do something a bit more fancy than this
# Maybe do some patterns??

.text

# milliseconds before drawing next character
.set DELAY, 200

start:
  # Maximum loop
  li    s4, 100
  
  # Get an initial time
  li    a7, 30  # ecall(get_system_time)
  ecall
  move  s3, a0
  li    t0, DELAY
  add   s3, s3, t0
  
  # s3: the target time
_loop:
  li    a7, 30
  ecall
  bltu  a0, s3, _loop
  move  s3, a0
  li    t0, DELAY
  add   s3, s3, t0
  
  # set s0 to the col we want
  li    a0, 0
  li    a7, 41  # ecall(random_word)
  ecall
  li    t0, 36
  rem   s0, a0, t0

  # set s1 to the row we want
  li    a0, 0
  li    a7, 41
  ecall
  li    t0, 80
  rem   s1, a0, t0

  # get background color in s2
  li    a0, 0
  li    a7, 41
  ecall
  li    t0, 10
  rem   a0, a0, t0
  add   s2, a0, 40

  # move cursor
  li    a7, 4
  la    a0, str_escape
  ecall

  li    a7, 1
  move  a0, s0
  ecall

  li    a7, 4
  la    a0, str_semicolon
  ecall

  li    a7, 1
  move  a0, s1
  ecall

  li    a7, 4
  la    a0, str_H
  ecall

  # print colored block
  li    a7, 4
  la    a0, str_escape
  ecall

  li    a7, 1
  move  a0, s2
  ecall

  li    a7, 4
  la    a0, str_m
  ecall

  li    a7, 4
  la    a0, str_space
  ecall
  
  add   s4, s4, -1
  bltz  s4, _exit

  j _loop

_exit:
  # Power off the machine
  li    a7, 10
  ecall

# And here is all of the data (the... not code parts)
.data

str_semicolon:  .string ";"
str_H:          .string "H"
str_escape:     .string "\x1b["
str_m:          .string "m"
str_space:      .string " "

