# `smoke_test_dma` timeout — Slurm array 280 task 0

The pinned top-level firmware runner compiled and started under published
Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, but the 7,000-second
process timeout stopped it before any testcase pass/fail marker. Its untraced
simulator log ends mid-line during the `CPTRA_FLOW_STATUS` ready-for-fuses
poll, so that log alone does not identify where the timed-out run stopped.
The traced follow-up (job 289) shows the poll deasserting after one read,
`BootGo` being written, and ROM execution beginning. It also timed out after
7,000 seconds, with the final trace in the firmware's 512-word payload setup
loop before the AHB FIFO transfer. Its full artifacts are in
[`trace-smoke-timeout/`](../trace-smoke-timeout/).

| Item | Evidence |
| --- | --- |
| Slurm job | 280, array task 0; per-test timeout exit `124` |
| QD-BFM snapshot | `72d965adc2d7e9bfdbadaa3348add9781319bd1c` |
| Caliptra RTL | `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` |
| Adams Bridge | `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` |
| Icarus / UVM | `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` / `78c06547a2a0a29b3dc9dcafae62b75b2ff61544` |
| Peak RSS | 1,859,644 KiB; request 3 GiB |
| Runner options | `--fast-trng --fast-boot-data-preload --quiet-firmware` |

The untraced log contains reset release, fuse writes, and entry into
flow-status polling. It contains no `* TESTCASE PASSED`, `TESTCASE FAILED`, or
explicit fatal/assertion. The separate traced log confirms progress beyond
that poll, but neither run reached a testcase result.

Artifacts include the final simulator log, compile log, resource report,
Slurm output, runner status, source revisions, and binary hashes. The compiled
VVP image is omitted; its hash is retained separately.
