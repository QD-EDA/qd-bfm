# M8: Verilator for Caliptra top-level firmware

Built the current stable Verilator release from the official `v5.052` source
tag (commit `ea338be98e1e838d3518809ce8899f85a009963c`) on DAN-DESKTOP. The
installed binary is `/home/dsell/toolchains/verilator-5.052/bin/verilator`;
the Debian `/usr/bin/verilator` remains 5.032.

Slurm job 1295 used 4 CPUs, 8 GiB, and a 2-hour limit. The build finished in
2m25s with exit status 0 and peak RSS 947,584 KiB. The installed binary reports
`Verilator 5.052 2026-09-05 rev v5.052`; SHA-256 is recorded in
[`verilator.sha256`](verilator.sha256). `make` emitted two harmless jobserver
warnings while its nested make reset `-j1`; no compiler errors occurred. The
full log was also triaged by ask-intern and checked against the log locally.

The release recognizes `--fourstate`, but its own source warns that the mode
is not yet supported. A 6-line probe compiled with the flag, then failed at
runtime because the assigned X was lost. The compile warning and failed run are
retained as `fourstate-stable-compile.log` and `fourstate-stable-sim.log`. The
experimental comparison will use the current development implementation
separately; this stable flag is not a functioning four-state simulator.
The [Verilator 5.052 language documentation](https://verilator.org/guide/latest/languages.html)
also describes the stable simulator as mostly two-state.

Build script, submission, source revision, host/tool versions, resource report,
and full build logs are retained in this directory. After the evidence was
committed, the disposable source and probe build trees were removed from the
Slurm run directory, freeing 2,044,669,252 bytes. The installed toolchain is a
protected shared input and remains in place; details are in [`cleanup.txt`](cleanup.txt).

Sources: [Verilator 5.052 release announcement](https://github.com/verilator/verilator-announce/issues/85),
[Verilator four-state development PR #7176](https://github.com/verilator/verilator/pull/7176).

## Caliptra top-level model

The `caliptra_top_tb` model builds from QD-BFM commit `dd6d43d` with the existing
runner's timescale prefix and JTAG listen-port change, plus a filelist that
uses the QD-BFM wrapper and its 15 BFM sources. No firmware test logic or pass
criteria changed. The build evidence is in
[`top-build-1311-checker-success`](top-build-1311-checker-success/README.md).

On the six c339-PASS cases, stable Verilator 5.052 passed all six with exact
final mcycle matches. Per-case speedup was 202.57–245.50x (mean 222.61x; total
wall-time ratio 221.18x). The full three-mode table is
[`six-three-way-comparison.tsv`](six-three-way-comparison.tsv). The experimental
four-state model build failed on an X-valued FIFO array select before any case
ran, so all six experimental outcomes are marked BUILD_BLOCKED.

## Thirty Icarus-timeout tests

All 30 Verilator 2-state rows are terminal: 27 PASS, two FAIL, and one TIMEOUT.
One FAIL row has a testbench PASS marker and simulator exit 0, but two expected
`error=0x1` strings trigger the existing runner's `BAD` classifier; it remains
FAIL without changing the criteria. `jtag_tap_mbox` exited 1 on the testbench's
20,000,000-cycle assertion after 11,181.286 seconds, with no final mcycle.
`cptra_ss_test_rom` reached its 6,873-second cap with no pass/fail marker or
mcycle. The complete per-test record is in
[`verilator-30-timeout-results.tsv`](verilator-30-timeout-results.tsv).
The corrected c339 AXI read/write baseline reruns both reached their 7,628s
caps with progress heartbeats; raw runner exit 137 is preserved in the task
evidence.

## Recommendation for all 271 top-level tests

Use stable Verilator 5.052 with the existing `--timing` wrapper as the
throughput trial for all 271 tests, retaining the current pass checks and
per-test timeouts. Keep Icarus for block-level UVM and as the four-state
reference. Triage the two FAIL rows and one TIMEOUT in the 30-test subset before
claiming full compatibility; the 271-test cohort was not run. The measured
202.57–245.50x speedup applies to the six matched cases only; do not project
that rate onto every test. The experimental four-state prototype cannot build
this top model; its array, queue, and scheduler coverage gaps are detailed in
[`experimental-xsim-20261015`](experimental-xsim-20261015/README.md).

## M7 carry-overs

The `butterfly_top_tb` VVP event-wait assertion was filed as
[iverilog-uvm issue #596](https://github.com/dsellerbrock/iverilog-uvm/issues/596)
with a reduced reproducer and `from-caliptra-dv` label. The 22 compile/filelist
blockers were triaged; none is confirmed as an Icarus compiler gap. The VeeR
interface diagnostic remains unconfirmed. Details are in the
[M7 triage record](../caliptra-bfm-m7-rebaseline-20261014/compiler-gap-triage-20261015/README.md).
