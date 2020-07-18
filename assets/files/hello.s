# Hello World

# Welcome to the RISC-V Assembler and Workable, Rewritable System.
# We call it RAWRS. It's a dinosaur thing.

# It lets you play around with RISC-V assembly language and hopefully learn a
# little bit about computers along the way.

# Press the "Run" button at the top right to see what this program does and
# then return to look at the code!

# Here's some code (which historically we refer to as 'text', neat!)
.text

  # Say hello! using an environment call
  li    a0, 4
  la    a1, str_hello
  ecall

  # Power off the machine
  li    a0, 10
  ecall


# And here is all of the data (the... not code parts)
.data

str_hello:    .string   "Hello!"
