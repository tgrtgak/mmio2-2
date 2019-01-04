# This file wraps access to the Real-Time Clock (RTC) through the Core Local
# Interruptor (CLINT) device.

# The FDT table will provide us with the address of the CLINT MMIO registers.
# Since the Real-Time Clock is such an expensive piece of hardware to multiplex
# (that is, to provide uniform access to multiple components concurrently) the
# RTC is accessed indirectly via a memory-mapped register.

.include "const.s"
.include "util.s"

.global rtc_get
.global rtc_init

.text

rtc_get:

rtc_init:

.data
.balign 8, 0

rtc_clint_base_addr:  .dword  0
