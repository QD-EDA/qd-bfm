# Corrected result-classifier continuation

The submitted job 660 wrapper searched for `output/$case_dir/result.json`, but the runner writes `output/result.json`. Task 660_11 therefore received a wrapper `FAIL` despite `runner.log` reporting PASS, `result.json` having `passed=true`, and `sim.log` containing `* TESTCASE PASSED`. The raw status and corrected test verdict are preserved under [`../terminal-results/task-11-smoke_test_kv/`](../terminal-results/task-11-smoke_test_kv/).

Only the tasks 660_16–660_51 that were still PENDING were canceled before execution. The six running tasks 660_8, 660_10, and 660_12–660_15 were left running. Job 669 resubmits rows 16–51 with the corrected result path at throttle 6 and `afterany:660`, so it cannot overlap the original array. The 11:36 MDT before/after queue snapshot is in `cancel-snapshot.txt`.

Job 669 uses the protected c339 toolchain and OpenSSL prefix under `/home/dsell/toolchains/iverilog-c339/`. Its pinned QD source snapshot was copied byte-for-byte from job 660 into `/home/dsell/toolchains/qd-bfm-0e331dec3d83ad70e5e73d8f0198dbdd4a226f74/`; `protected-QD-manifest.txt` records the commit and runner hash. The job root contains the full selection manifest so array indices continue to map to the same rows. Script syntax and remote hashes were checked before submission.

The submitted array script SHA-256 is `83b0f82bd723728454a7a8a97e31559aa7fa6e9f826bba67a7d4db74f66b5733`; the selection SHA-256 is `deb72ae2729b6e963f492a32117b5c834f3e4ee1276795fc2ce17b947fa19289`. Job 669 was verified PENDING with dependency `afterany:660` and `ArrayTaskThrottle=6`.

At 14:18 MDT, job 660 is complete. Tasks 660_8, 660_10, 660_12, 660_13, 660_14, and 660_15 have terminal `FAIL`, `TIMEOUT`, `PASS`, `TIMEOUT`, `PASS`, and `TIMEOUT` verdicts. Job 669 has started rows 16–21; rows 22–51 are pending at throttle 6. Provenance confirms each active task uses QD commit `0e331dec3d83ad70e5e73d8f0198dbdd4a226f74`, Icarus source `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and the protected OpenSSL prefix; each active task's binary SHA checks passed.

At 15:23 MDT, job 669 tasks 16–21 remained RUNNING and rows 22–51 PENDING at throttle 6. The six protected c339 VVP processes were each using about one CPU and 1.0 GiB RSS, with 10,714–11,240-second per-test limits. No result JSON or terminal markers existed yet. Their identical initialization-only logs were triaged by the local intern and checked directly; see [`status-15-23.txt`](status-15-23.txt). No test verdict is inferred from this snapshot.

At 16:04 MDT, the same six tasks remained active with 1:53:10 elapsed and about 99.9% CPU each; no result JSON or terminal status existed. This duration remains below their configured limits and within the 2:18:44 observed runtime of an earlier top-level PASS. See [`status-16-04.txt`](status-16-04.txt).

At 16:15 MDT, task 669_18 completed PASS and row 22 started; five other tasks from the original running group remain active. The corrected runner, JSON, simulator marker, warning count, and runtime are recorded under `terminal-results/task-18-smoke_test_doe_kv_ocp_progress/`. The updated queue snapshot is [`status-16-15.txt`](status-16-15.txt).

At 19:27 MDT, task 669_22 ended with the runner's configured 11,240-second timeout (3:07:20; peak RSS 1,852,368 KiB), so row 22 is recorded as terminal TIMEOUT. Its raw status and logs are in `terminal-results/task-22-smoke_test_kv_securitystate/`. Rows 23–26, 28, and 29 are RUNNING; rows 30–51 remain PENDING at throttle 6. DAN-DESKTOP had been up 10:52, and all six VVP processes were active. See [`status-19-26.txt`](status-19-26.txt).

At 19:45 MDT, the same six tasks remained RUNNING. Task 669_24’s nested simulator log advanced to the Datavault Mini Smoke Test, but all six still lacked runner status, result JSON, and terminal markers. The other visible logs were unchanged; no test verdict is inferred. See [`status-19-45.txt`](status-19-45.txt).

At 20:00 MDT, task 669_28 completed PASS. Task status, runner exit 0, result JSON (`passed=true`, `sim_exit=0`), one testcase pass marker, and finish record agree; wall time was 2:24:22 and peak RSS 1,852,464 KiB. Rows 23–26, 29, and 30 are RUNNING; rows 31–51 are PENDING at throttle 6. The before/after queue snapshots are [`status-19-57.txt`](status-19-57.txt) and [`status-19-58.txt`](status-19-58.txt); full raw evidence is under `terminal-results/task-28-smoke_test_dma_aes_kv_short/`.
