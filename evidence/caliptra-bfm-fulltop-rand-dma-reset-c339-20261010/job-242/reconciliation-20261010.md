# Array 242 reconciliation

Snapshot: 2026-10-10 15:29 MDT (`DAN-DESKTOP`, checked with `squeue`).

## Completed tasks

Tasks 242_1–4 have `runner_exit=124`, the configured 3500-second timeout. The runner logs do not contain a terminal BFM result. Trace-enabled tasks 1–3 reached cycles 25,700, 25,600, and 25,500 respectively; their sampled trace records contain no `reset_n=0` samples. Task 4 had trace disabled and its `sim.log` has no cycle markers, so its simulation progress cannot be read from that file. All four resource logs report peak RSS near 1.86 GB.

These runs used QD source `708e51cd304422f367a61064449c5617fc97fec6`, Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, seed 1, and `--force-first-rand-dma-reset`. They did not pass a fixed reset delay. They therefore do not test the cycle-relative reset window and do not establish a BFM pass or failure.

Selected raw logs, task stdout, status, source revisions, tool hashes, and a local SHA256 manifest are preserved under `completed-runs/`. The 368 MB compiled `.vvp` and other build products were not copied; the source and tool identities are retained.

## Tasks 242_5/6 completion (2026-10-10 16:25 MDT)

Both no-trace controls finished with `runner_exit=124` after the configured 3500-second timeout. Their resource logs report peak RSS of 1,859,920 and 1,859,960 KB. The runner logs are empty and no-trace simulation logs contain only startup warnings, so these tasks provide no reset-cycle trace or terminal BFM result. The warning text alone does not establish a cause. Selected raw logs and source/tool identities are preserved in `completed-runs/no-trace-2/` and `completed-runs/no-trace-3/`; compiled products were not copied. The local SHA256 manifest covers the selected logs for all six completed tasks.

No array tasks were cancelled or resubmitted. All six tasks ended by timeout: the three traced runs reached roughly 25.5k cycles without sampled reset assertion; the three untraced runs have no cycle markers. The array therefore does not answer the fixed-delay reset question.

## Comparison with job 240 (2026-10-10 15:52 MDT)

Job 240's `source-revisions.txt` matches task 242_1 for QD, runner SHA256, trace source SHA256, Icarus, UVM, Caliptra RTL, Adams-Bridge, and JTAG-VPI identities. Job 240 additionally used `--rand-dma-reset-delay-cycles 2822`; its `result.json` records compile and firmware exit 0, simulator exit -11, cycle 100 as the last trace sample, and no reset assertion. This isolates the fixed-delay run path as the changed condition, but one crash does not establish a reproducible cause.

The six array outcomes do not change that interpretation: they omitted the fixed-delay option, and all reached the wrapper timeout. Next diagnostic is a fresh isolated run with the same pinned inputs and the 2822-cycle delay, preserving VPI tracing and a core dump if available. A repeat crash would support reproducibility; a different result would require inspecting the newly captured terminal trace before changing BFM code.
