# This file has the code that sets up and handles processor exceptions and
# traps.

.include "const.s"
.include "util.s"

.global trap_init
.global trap

.set TRAP_CAUSE_ECALL,    8

# trap_init(): Sets up the trap vector.
#
# This lets the processor know where trap handlers are.
trap_init:
  la    t0, trap
  csrw  stvec, t0
  jr    ra

# trap(): Is called by the processor when an exception or trap occurs.
trap:
  # First, let's establish a stack
  # We can swap the registers with CSRs
  # In this case, the stack pointer
  csrw sscratch, sp
  
  # Load the kernel stack
  # Hmm. I wonder how RISC-V intends to allow the OS to denote the process ID.
  #      I assume that might be in SSTATUS or something along those lines?
  la    sp, stack

  # Push all
  push  s0
  push  s1
  push  s2
  pushd

  # Gather hardware information about the trap in question
  csrr  s0, scause
  csrr  s1, sbadaddr
  csrr  s2, sepc

  # Determine if the trap was a system call
  li    t0, TRAP_CAUSE_ECALL
  bne   t0, s0, _trap_unknown

  # Make sure we return to the next instruction by adding 4 to the PC we
  # will jump to. "sret" will set PC to the value in SEPC and s2 currently
  # holds the value of SEPC, which is the instruction that caused the trap.
  # In this case, the instruction is the ECALL instruction. So we must move
  # the PC manually. (although, what happens if the ECALL is a compressed
  # instruction?? C.ECALL may mess this up???)
  add   s2, s2, 4
  csrw  sepc, s2

  # Perform the system call
  jal   syscall
  j     _trap_exit

_trap_unknown:
  # Unexpected trap; abort()
  jal   abort

_trap_exit:
  # Restore context
  move  s0, a0
  move  s1, a1
  popd
  move  a0, s0
  move  a1, s1
  pop   s2
  pop   s1
  pop   s0

  # Restore the stack pointer
  csrr  sp, sscratch
  
  # Return to userspace!
  sret
