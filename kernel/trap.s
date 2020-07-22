# This file has the code that sets up and handles processor exceptions and
# traps.

.include "const.s"
.include "util.s"

.global trap_init
.global trap_clear_interrupts
.global trap_enable_interrupts
.global trap

# Non-interrupt trap causes
.set TRAP_CAUSE_ECALL,     0x8 # An ecall instruction

# Interrupt trap causes
.set TRAP_CAUSE_E_EXT_INT, 0x8 # An environment interrupt
.set TRAP_CAUSE_S_EXT_INT, 0x9 # A supervisor interrupt

# trap_init(): Sets up the trap vector.
#
# This lets the processor know where trap handlers are.
trap_init:
  la    t0, trap
  csrw  stvec, t0
  jr    ra

# trap_clear_interrupts(): Clears pending interrupts.
trap_clear_interrupts:
  csrw  sip, zero
  jr    ra

# trap_enable_interrupts(): Enables interrupts.
#
# This will set SIE CSRs and enable interrupts to be resolved.
trap_enable_interrupts:
  csrr  t0, sie

  # Set SSIE (Enables software interrupts)
  li    t1, 0b10
  or    t0, t0, t1

  # Set SEIE (Enables external interrupts)
  li    t1, 0b1000000000
  or    t0, t0, t1

  csrw  sie, t0

  # Set SIE in SSTATUS
  csrr  t0, sstatus
  li    t1, 0b10
  or    t0, t0, t1
  csrw  sstatus, t0

  jr    ra

# trap_disable_interrupts(): Disables interrupts.
#
# This will set SIE CSRs and enable interrupts to be resolved.
trap_disable_interrupts:
  csrr  t0, sie

  # Clear SSIE (Enables software interrupts)
  li    t1, 0b10
  not   t1, t1
  and   t0, t0, t1

  # Clear SEIE (Enables external interrupts)
  li    t1, 0b1000000000
  not   t1, t1
  and   t0, t0, t1

  csrw  sie, t0

  # Clear SIE in SSTATUS
  csrr  t0, sstatus
  li    t1, 0b10
  not   t1, t1
  and   t0, t0, t1
  csrw  sstatus, t0

  jr    ra

# trap(): Is called by the processor when an exception or trap occurs.
trap:
  # First, let's establish a stack
  # We can swap the registers with CSRs
  # In this case, the stack pointer
  csrw  sscratch, sp
  
  # Load the kernel trap stack
  # Hmm. I wonder how RISC-V intends to allow the OS to denote the process ID.
  #      I assume that might be in SSTATUS or something along those lines?
  la    sp, trap_stack

  # Push all
  push  s0
  push  s1
  pushd

  # Gather hardware information about the trap in question
  csrr  s0, scause
  csrr  s1, sbadaddr

  # Determine if the trap was a system call
  li    t0, TRAP_CAUSE_ECALL
  bne   t0, s0, _trap_check_interrupt

  # Switch to the syscall stack
  # This allows us to have a hardware interrupt during the syscall.

  # Restore context
  popd
  pop   s1
  pop   s0

  # Switch to the kernel main thread stack
  la    sp, stack

  # Push all (again)
  push  s0
  push  s1
  pushd

  # Preserve user stack
  csrr  s0, sscratch
  push  s0

  # Make sure we return to the next instruction by adding 4 to the PC we
  # will jump to. "sret" will set PC to the value in SEPC which is set by the
  # cpu to the instruction that caused the trap.
  #
  # In this case, the instruction is the ECALL instruction. So we must move
  # the PC manually. (although, what happens if the ECALL is a compressed
  # instruction?? C.ECALL may mess this up???)
  csrr  s0, sepc
  add   s0, s0, 4
  push  s0

  # Perform the system call
  jal   syscall

  # We need to write our return values to the stack
  # This is tricky. The current contents of the stack is:
  # [userspace PC] 0x00(sp)
  # [userspace SP] 0x08(sp)
  # [userspace T6] 0x10(sp)
  # [userspace T5] 0x18(sp)
  # [userspace T4] 0x20(sp)
  # [userspace T3] 0x28(sp)
  # [userspace T2] 0x30(sp)
  # [userspace T1] 0x38(sp)
  # [userspace T0] 0x40(sp)
  # [userspace A3] 0x48(sp)
  # [userspace A2] 0x50(sp)
  # [userspace A1] 0x58(sp)
  # [userspace A0] 0x60(sp)
  # So, write a0 and a1 to overwrite the userspace's a0/a1
  sd    a0, 0x60(sp)
  sd    a1, 0x58(sp)

  # Disable interrupts
  jal   trap_disable_interrupts

  # Pull target PC
  pop   s0

  # Write it back
  csrw  sepc, s0

  # Pull user stack
  pop   s0

  # Write to scratch
  csrw  sscratch, s0

  # Exits the trap using the syscall stack
  j     _trap_exit

_trap_check_interrupt:
  # Determine if the trap was an interrupt
  srl   t0, s0, 63
  beqz  t0, _trap_unknown

  # Clear interrupt bit (highest bit)
  sll   s0, s0, 1
  srl   s0, s0, 1

  li    t0, TRAP_CAUSE_E_EXT_INT
  beq   t0, s0, _trap_interrupt

  li    t0, TRAP_CAUSE_S_EXT_INT
  beq   t0, s0, _trap_interrupt

  bne   t0, s0, _trap_unknown

_trap_interrupt:
  # Pass off to the IRQ handler
  jal   irq_resolve

  # Clear interrupts
  jal   trap_clear_interrupts

  j     _trap_exit

_trap_unknown:
  # Unexpected trap; abort()
  la    a0, str_trap_unknown
  jal   println

  la    a0, str_trap_unknown_cause
  jal   print
  csrr  s0, scause
  print_hex s0

  la    a0, str_trap_unknown_addr
  jal   print
  csrr  s0, sbadaddr
  print_hex s0

  la    a0, str_trap_unknown_pc
  jal   print
  csrr  s0, sepc
  print_hex s0

  la    a0, str_trap_unknown_status
  jal   print
  csrr  s0, sstatus
  print_hex s0

  jal   abort

_trap_exit:
  # Restore context
  popd
  pop   s1
  pop   s0

  # Restore the stack pointer
  csrr  sp, sscratch
  
  # Return to userspace (or supervisor, if nested)!
  sret

.data

str_trap_unknown:        .string "\n\nUnknown interrupt"
str_trap_unknown_cause:  .string "Cause: "
str_trap_unknown_addr:   .string "\nAddress: "
str_trap_unknown_pc:     .string "\nSEPC: "
str_trap_unknown_status: .string "\nSSTATUS: "
