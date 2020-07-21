# Handles programmable interrupt requests (IRQs)

# The interrupt controller typical to a RISC-V machine is the PLIC
# (Platform-Level Interrupt Controller) which has documentation here:
# https://github.com/riscv/riscv-plic-spec/blob/master/riscv-plic.adoc

# This lets us wire up these interrupt requests to the interrupt pins on the
# CPU where they can be handled by the native traps.

.include "const.s"
.include "util.s"

.global irq_init
.global irq_register
.global irq_resolve

.set PLIC_INTERRUPT_ENABLE_BASE, 0x002000
.set PLIC_INTERRUPT_HART_BASE,   0x200000

.text

# irq_init(plic_base_addr): Initializes the IRQ handler
#
# Arguments
#   a0: plic_base_addr: The base address of the interrupt controller
irq_init:
  la    t0, plic_base_addr
  sd    a0, 0(t0)
  jr    ra

# irq_register(index, handler)
#
# Arguments:
#   a0: index - The IRQ to register
#   a1: handler - The address of the function to call to handle the request
irq_register:
  la    t0, plic_handlers
  sll   a0, a0, 3
  add   t0, t0, a0
  sd    a1, 0(t0)
  jr    ra

irq_resolve:
  push ra
  push s0

_irq_resolve_loop:

  # Look for unresolved signals and dispatch them
  la    t0, plic_base_addr
  ld    t0, 0(t0)
  li    t1, PLIC_INTERRUPT_HART_BASE
  add   t0, t0, t1
  lw    s0, 4(t0) # Read word at PLIC_MMIO[HART+4]

  # s0: The IRQ issued
  beqz  s0, _irq_resolve_exit
  
  # Determine the IRQ handler
  sll   t1, s0, 3
  la    t0, plic_handlers
  add   t0, t0, t1
  ld    t0, 0(t0)

  beqz  t0, _irq_resolve_ack
  li    t1, 10
  bge   s0, t1, _irq_resolve_ack

  # Call that handler
  jalr  t0

_irq_resolve_ack:

  # Resolve irq
  la    t0, plic_base_addr
  ld    t0, 0(t0)
  li    t1, PLIC_INTERRUPT_HART_BASE
  add   t0, t0, t1
  sw    s0, 4(t0) # Write IRQ back to PLIC_MMIO[HART+4]

  j     _irq_resolve_loop

_irq_resolve_exit:
  
  pop   s0
  pop   ra
  jr    ra

.data

plic_base_addr:       .dword 0
plic_handlers:        .dword 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
