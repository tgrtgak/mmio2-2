# Asking For Input

# Welcome to the RISC-V Assembler and Workable, Rewritable System.
# We call it RAWRS. It's a dinosaur thing.

# It lets you play around with RISC-V assembly language and hopefully learn a
# little bit about computers along the way.

# Press the "Run" button at the top right to see what this program does and
# then return to look at the code!

# Here's some code (which historically we refer to as 'text', neat!)
.text

  # Ask a question using an environment call
  li    a7, 4
  la    a0, str_greet
  ecall
  
  # Read string
  li    a7, 8
  la    a0, str_buffer
  li    a1, 255
  ecall
  
  # Say hello! using an environment call
  li    a7, 4
  la    a0, str_hello
  ecall
  
  # Print out that string
  li    a7, 4
  la    a0, str_buffer
  ecall
  
  # Say hello! using an environment call
  li    a7, 4
  la    a0, str_hello_end
  ecall

  # Ask another question using an environment call
  li    a7, 4
  la    a0, str_ask_age
  ecall
  
  # Read integer
  li    a7, 5
  ecall
  
  move  s0, a0

  # Print newline
  li    a7, 4
  la    a0, str_newline
  ecall
  
  # Print integer
  li    a7, 1
  move  a0, s0
  ecall
  
  li    t0, 10
  blt   s0, t0, _respond0
  
  li    t0, 20
  blt   s0, t0, _respond1
  
  li    t0, 30
  blt   s0, t0, _respond2
  
  li    t0, 40
  blt   s0, t0, _respond3
  
  j _respond4
  
_respond0:
  li    a7, 4
  la    a0, str_respond_0
  ecall
  
  j _exit
  
_respond1:
  li    a7, 4
  la    a0, str_respond_1
  ecall
  
  j _exit
  
_respond2:
  li    a7, 4
  la    a0, str_respond_2
  ecall
  
  j _exit
  
_respond3:
  li    a7, 4
  la    a0, str_respond_3
  ecall
  
  j _exit
  
_respond4:
  li    a7, 4
  la    a0, str_respond_4
  ecall
  
_exit:

  # Power off the machine
  li    a7, 10
  ecall


# And here is all of the data (the... not code parts)
.data

str_greet:      .string     "Greetings, what is your name?\n\n > "
str_hello:      .string     "\nHello, "
str_hello_end:  .string     "!\n\n"
str_buffer:     .fill       256, 1, 0
str_newline:    .string     "\n"
str_ask_age:    .string     "How old are you?\n\n > "
str_respond_0:  .string     "?! Your reading level is impressive!!"
str_respond_1:  .string     ", eh? Stay in school!"
str_respond_2:  .string     "!! Wow! So adult!"
str_respond_3:  .string     "!!!! SO OLD!!!"
str_respond_4:  .string     ". Nice to meet you."

