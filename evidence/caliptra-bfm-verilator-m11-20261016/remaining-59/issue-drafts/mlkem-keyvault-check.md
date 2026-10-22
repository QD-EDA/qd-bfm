# Draft: top-level MLKEM key-vault check fails during firmware tests

**Status:** Local review draft only; not posted. The focused trace captures the failing byte and last tracked write; the monitor mapping or intervening write behavior remains unresolved.

In the focused Verilator 5.052 run with the official M10b overlay and assertions, `smoke_test_mlkem_locked_api` (`ab4697d02ef4acc9`) failed `KV_MLKEM_CHECK0` at 12,012,000 ps / cycle 120116. The trace identifies slot 2, dword 0, byte 0: actual `0x29`, expected `0x00`. Its last tracked slot-2 write was at cycle 53597, dword `0x00000000`. Firmware logged “Received expected success for MLKEM sharedkey write from KV” at 11,905,000 ps, before the failed byte check. See [the focused trace](../diagnostics/m11b-focused-traces-20261017-06/raw/job-2090/results/ab4697d02ef4acc9/sim.log).

The trace confirms the comparison failure and the values it compared, but does not prove whether a later write was missed or whether slot/byte selection differs from the firmware’s intended entry. Please confirm the expected slot-2 write sequence and whether the monitor’s byte ordering and sample point match it. The row’s c339 baseline remains unverified. No RTL or testbench assertion was changed.
