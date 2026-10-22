# Verilator 2-state result: `jtag_tap_mbox`

The runner result is FAIL, not TIMEOUT. The case's configured simulator cap was
15,212 seconds, but the simulator exited 1 after 11,181.286 seconds and the
runner completed after 11,183.665 seconds. The simulator log ends with the
testbench assertion `Hit max cycle count (20000000) .. stopping`, followed by
`Verilog $stop` and `Aborting...`. There is no PASS/FAIL testcase marker or
final firmware mcycle, so mcycle is recorded as NA. The original c339 result
for this case was TIMEOUT with progress unknown.

The firmware log shows the ROM-to-TAP mailbox flow and stops after `FW:
Writing 32 bytes to mailbox`. The configured timeout command appearing in the
resource record is not the stop reason: measured simulation wall time is more
than 4,000 seconds below that limit, and the simulator's exit 1 plus explicit
max-cycle assertion account for the FAIL result.

Job 1372 task 3 used the pinned model SHA-256
`b6ee29ade1b17547c4b31692ed9a0b48e22031c4551604fd9dc250a81e01ae79`, QD-BFM
commit `dd6d43d5416006a9e77f2458e8df2a5a754f86c7`, and the runner/source files
archived with this result. All copied files pass `remote.SHA256SUMS`.
