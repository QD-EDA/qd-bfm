# Array 242 reconciliation

Snapshot: 2026-10-10 15:29 MDT (`DAN-DESKTOP`, checked with `squeue`).

## Completed tasks

Tasks 242_1–4 have `runner_exit=124`, the configured 3500-second timeout. The runner logs do not contain a terminal BFM result. Trace-enabled tasks 1–3 reached cycles 25,700, 25,600, and 25,500 respectively; their sampled trace records contain no `reset_n=0` samples. Task 4 had trace disabled and its `sim.log` has no cycle markers, so its simulation progress cannot be read from that file. All four resource logs report peak RSS near 1.86 GB.

These runs used QD source `708e51cd304422f367a61064449c5617fc97fec6`, Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, seed 1, and `--force-first-rand-dma-reset`. They did not pass a fixed reset delay. They therefore do not test the cycle-relative reset window and do not establish a BFM pass or failure.

Selected raw logs, task stdout, status, source revisions, tool hashes, and a local SHA256 manifest are preserved under `completed-runs/`. The 368 MB compiled `.vvp` and other build products were not copied; the source and tool identities are retained.

## Still running

At the snapshot, tasks 242_5 (no-trace-2) and 242_6 (no-trace-3) were running on `DAN-DESKTOP`, each with the one-hour Slurm limit. Their output directories were live and were not copied or changed. No array tasks were cancelled or resubmitted.

## Next action

Wait for 242_5/6 to finish and classify their runner status and logs. If they also time out, move to a fresh, trace-enabled fixed-delay run for the cycle-relative reset question; the existing A/B array only compares VPI presence without that reset window.
