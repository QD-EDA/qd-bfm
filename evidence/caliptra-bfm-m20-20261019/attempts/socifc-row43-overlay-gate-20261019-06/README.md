# SoC-IFC row 43 overlay gate, retry 6

One-row gate for the expanded sequence-method compatibility overlay. Retry 5/job 3245 failed before the harness because its source archive had not been extracted into `source/`; this retry extracts the archive and verifies the pinned M15 runner and row manifest before `sbatch`.

The overlay supplies explicit `void` returns to `create_seqs`, `randomize_seqs`, and `create_and_randomize_seqs` across the generated sequence include tree. Source pin and c339 compiler are unchanged. Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds. One-row gate before any other row uses the updated overlay.

Source-tree preflight passed after extraction and hash verification. Job 3246 completed the 1,800-second-capped runner in 53.481 seconds, but the row remained BLOCKED before simulation. Archive `raw/job-3246_43.tar.gz` SHA-256: `5078a38ef43df5353e6344b5002406f8fe0e39bf3c19094882ba1066e7185136`.

The compile log reports eight 32,768-value aligned-length bins dropped, eight 2^32-value generic-wire byte bins dropped, a trailing empty `$psprintf` argument, and unsupported wide coverage bins for the random key, field entropy, and UDS seed; `iverilog` was then killed at the 2 GiB allocation (compile exit 137, peak RSS about 2.0 GiB). Ask-intern’s triage matched these log lines; I confirmed each against the pinned sources. The next per-run overlay will split aligned-length ranges at 4,096 values, express nonzero-byte bins as wildcard patterns, aggregate the wide key/entropy/seed coverage to single bins, and remove the empty printf argument. It changes coverage representation only; it does not touch RTL behavior or test criteria.
