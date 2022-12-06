# This is a simple looping function intended to demonstrate the functionality of the keyboard simulator plugin

# The keyboard simulator's register addresses may change, but for now the following addresses are assigned for its use:
# 0xffff0000 : The keyboard simulator's write flag. Whenever a keystroke is read in the keyboard space (the bottom text box), this is set to 1.
# 0xffff0004 : The keyboard simulator's output. When a keystroke is read in the keyboard space, the character code typed is stored here
# 0xffff0008 : The keyboard simulator's read flag. The read flag needs to be set before the display reads from its source register.
# 0xffff000c : The keyboard simulator's input. When this register is written to, if the read flag is set, the value is interpreted as a character code and displayed in the top text box.

# Due to way RAWRs works, infinite looping is not functional in the traditional sense. 
# To make use of this example function, step through each line with the step button. 
# As you step, make note of how the registers process the commands, and what values are stored where.
# Using the step function will properly utilize the loops in place, enabling you to (very slowly), mirror
# what you type in the bottom text box to the top.

# Hint: you can also refresh the display by typing a character and then clicking the run
# button, but again, you must press the button each time you wish to display a typed character.

.text

_loop_one:

# Loop until the flag indicating a write to the keyboard space is set
li      s1, 0xffff0000
lw      s2, 0(s1)
beqz    s2, _loop_one

# When the flag is set, load the value written to the keyboard space
li      s3, 0xffff0004
lw      s4, 0(s3)

# Set the write flag to 1
li      s5, 1
li      s6, 0xffff0008
sw      s5, 0(s6)

# Pass the value of s4 (the character code typed) to the display register
li      s7, 0xffff000c
sw      s4, 0(s7)

# Resume the loop from the beginning
j       _loop_one

# Power off
li 		a7, 10
ecall
