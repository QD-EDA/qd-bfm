# Adams Bridge abr_sha3 row61 gate

Single-row gate for the pinned `abr_sha3_tb` stale `.done_i` testbench-port overlay. The overlay is hash guarded and changes only the bench connection; RTL, stimulus, expected values and pass criteria stay pinned. The current DUT has no `done_i` port, and the old `sha3_done` connection has no other readers.

- Row: 61 (`abr_sha3_tb`)
- Icarus: `cae035642e056644274a01e98d4422ce286685b4`, binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`
- Host: DAN-DESKTOP; resources: 1 CPU, 1 GiB, 600-second runner timeout
- Source snapshot SHA-256: `6f002baf8784326f77919af14b7bbc7c22b13d47d8a2508e094209fef6b14aec`
- Run script SHA-256: `be3ca8c1f6eecff9187deda0f55b1ba3af1ff5cbe6e4a0609e931545e7546d71`
- Selector assertion: `#SBATCH --array=61` (verified before submission)

Job 3065 failed at compile because the two testbench edits were written to the same path separately; the second edit discarded the package-import alias. This diagnostic is superseded by gate 03. Raw archive SHA-256 `f4e5d66a2b598e90d80cde93cf04b3958b1d98af6479be80fbf2b0642b0718d7` matches its sidecar.
