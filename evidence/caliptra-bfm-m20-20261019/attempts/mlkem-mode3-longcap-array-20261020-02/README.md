# ML-KEM rows 85 and 100: 3,600-second operation-3 reruns

Fresh two-row array reruns the exact inputs from array 3273, with a 3,600-second runner timeout. The selective source archive omits the three changed ML-KEM helper files, so the job copies the exact separate, hash-verified files into each task's extracted source before building and compares them byte-for-byte. Each task gets its own source directory. This is the run-local helper setup required by the pinned bench; RTL, firmware, vectors, authored sequences, assertions, and pass criteria are unchanged.

Each task requests 1 CPU / 2 GiB, with at most two tasks. The 1:15:00 Slurm limit includes the runner cap and archiving margin. Terminal logs/results will be copied and SHA-256 verified before cleaning the remote run tree.

Submitted as array 3283 at throttle 2 (1 CPU / 2 GiB per task) on 2026-10-20 02:56:33 UTC. Remote checksum validation and `bash -n` passed. See `submission.txt` for the source and script hashes.

Array 3283 row 85 completed `PASS` in 1,962.750 seconds with compile and simulation exit 0, a testcase pass marker, and no UVM error/fatal. The archive `raw/job-3284-85.tar.gz`, SHA-256 `8280cd241153d4db042f44a7b44e6b672cd9bbe5e386f28b055f149dc1b7b52e`, is copied locally and verified against the remote sidecar. Row 100 remains running; do not duplicate or cancel it.

## Terminal row results

- Row 85 is `PASS` in 1,962.750 s; compile/simulation exit 0, testcase pass marker present, and no UVM error/fatal. Archive `raw/job-3284-85.tar.gz` SHA-256 `8280cd241153d4db042f44a7b44e6b672cd9bbe5e386f28b055f149dc1b7b52e` matches its sidecar.
- Row 100 is `TIMEOUT` at the 3,600 s runner cap; compile exit 0, simulation exit 124, and no testcase marker. Its last log activity is the decapsulation operation at 457,455 ns. Archive `raw/job-3283-100.tar.gz` SHA-256 `5a116955a3207467b8164bc24a4d6f189f1c2266dcf61e9961fb9163aa43cab2` matches the remote sidecar.
