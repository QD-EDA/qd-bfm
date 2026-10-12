# Corrected result-classifier continuation

The submitted job 660 wrapper searched for `output/$case_dir/result.json`, but the runner writes `output/result.json`. Task 660_11 therefore received a wrapper `FAIL` despite `runner.log` reporting PASS, `result.json` having `passed=true`, and `sim.log` containing `* TESTCASE PASSED`. The raw status and corrected test verdict are preserved under [`../terminal-results/task-11-smoke_test_kv/`](../terminal-results/task-11-smoke_test_kv/).

Only the tasks 660_16–660_51 that were still PENDING were canceled before execution. The six running tasks 660_8, 660_10, and 660_12–660_15 were left running. Job 669 resubmits rows 16–51 with the corrected result path at throttle 6 and `afterany:660`, so it cannot overlap the original array. The 11:36 MDT before/after queue snapshot is in `cancel-snapshot.txt`.

Job 669 uses the protected c339 toolchain and OpenSSL prefix under `/home/dsell/toolchains/iverilog-c339/`. Its pinned QD source snapshot was copied byte-for-byte from job 660 into `/home/dsell/toolchains/qd-bfm-0e331dec3d83ad70e5e73d8f0198dbdd4a226f74/`; `protected-QD-manifest.txt` records the commit and runner hash. The job root contains the full selection manifest so array indices continue to map to the same rows. Script syntax and remote hashes were checked before submission.

The submitted array script SHA-256 is `83b0f82bd723728454a7a8a97e31559aa7fa6e9f826bba67a7d4db74f66b5733`; the selection SHA-256 is `deb72ae2729b6e963f492a32117b5c834f3e4ee1276795fc2ce17b947fa19289`. Job 669 was verified PENDING with dependency `afterany:660` and `ArrayTaskThrottle=6`.
