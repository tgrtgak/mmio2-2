# This file wraps access to the Real-Time Clock (RTC) through the Core Local
# Interruptor (CLINT) device.

# The FDT table will provide us with the address of the CLINT MMIO registers.
# Since the Real-Time Clock is such an expensive piece of hardware to multiplex
# (that is, to provide uniform access to multiple components concurrently) the
# RTC is accessed indirectly via a memory-mapped register.

# The registers in question are MTIME (time since boot) and MTIMECMP (for timers)

.include "const.s"
.include "util.s"

.global rtc_init
.global rtc_get_mtime

.set CLINT_MTIMECMP_HI_OFFSET,  0x4004
.set CLINT_MTIMECMP_LO_OFFSET,  0x4000
.set CLINT_MTIME_HI_OFFSET,     0xbffc
.set CLINT_MTIME_LO_OFFSET,     0xbff8

.text

# Initializes the RTC device
#
# Arguments
#   a0: clint base address
rtc_init:
  # Retain the address
  la    t0, rtc_clint_base_addr
  sd    a0, 0(t0)

  jr    ra

# Gets the 64-bit system time
rtc_get_mtime:
  # Read from LO and HIGH word offsets
  la    t1, rtc_clint_base_addr
  ld    t1, 0(t1)
  li    t0, CLINT_MTIME_HI_OFFSET
  add   t0, t0, t1
  lwu   a0, 0(t0)
  sll   a0, a0, 32  # shift to make room for LO

  # Read from LO word
  li    t0, CLINT_MTIME_LO_OFFSET
  add   t0, t0, t1
  lwu   t0, 0(t0)
  or    a0, a0, t0

  jr    ra

.data
.balign 8, 0

rtc_clint_base_addr:  .dword  0
