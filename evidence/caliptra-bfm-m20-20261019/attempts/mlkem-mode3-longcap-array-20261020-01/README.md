# ML-KEM rows 85 and 100: 3,600-second operation-3 reruns

Fresh two-row array uses the exact source snapshot, operation-3 helper, and setup runner from array 3273. It changes only run-local ML-KEM setup and the per-row runner cap from 1,800 to 3,600 seconds. Rows 85 and 100 are the only targets because row 84 already passed.

Each task requests 1 CPU / 2 GiB, with at most two concurrent tasks. Per-task source snapshots are extracted independently from the archived snapshot to avoid shared extraction races. Both Caliptra/Adams Bridge pins and c339 tool binaries are rechecked before simulation. No RTL, firmware, vectors, authored sequences, assertions, or pass criteria change.

Terminal task archives and remote SHA-256 sidecars will be copied and verified here before deleting the remote run tree.

Submitted as Slurm array 3281 at 2026-10-20 02:40:19 UTC, throttle 2. Both tasks failed immediately before compile because the source snapshot omitted the three separately staged helper files and the script only compared, but did not install, them. `raw/preflight-3281/` preserves the scheduler state and both log files; local logs match remote SHA-256 values. This is an invalid setup attempt and does not update row verdicts. A corrected fresh array stages those files into each task source before compilation.

After archiving both preflight logs and confirming no tasks remained queued or running, the 1,462,532-byte remote run tree for invalid array 3281 was removed.
