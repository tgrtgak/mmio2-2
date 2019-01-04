# This contains the stack memory. We only have a little bit!

.global stack_init
.global stack

.text

# stack_init(): Sets up and enables the stack.
stack_init:
  la    sp, stack
  jr    ra

.data

# Allocate a 4KiB stack.
# It is certainly bad if we use it all!!
# (We could protect the region around the stack later, if we want)
.balign 4096, 0
.fill 1024, 4, 0
stack:
