# Adams Bridge missing-config-header row 58 gate, retry 3

This gate reruns row 58 (`sib_rand_test`) after adding a testbench-only import alias from the pinned `sampler_pkg` name to the source-pinned `abr_sampler_pkg`. The generic hash-guarded overlay also maps the stale config and package filelist paths. No macro values, RTL, expected outputs, or pass criteria change.

Pinned Icarus: `cae035642e056644274a01e98d4422ce286685b4`; one CPU, 4 GiB, 600-second per-row timeout. Source snapshot SHA-256: `78c3eae07e1d080ba38f7fc1399d7dc28770df42c3ffebc23a0cfaacafc04e6f`. Job 3053 compiled successfully and ran for 0.549 seconds. The overlay resolves the stale config and sampler package names. The bench reaches its unchanged 200,000-cycle cap, prints an ERROR, and finishes without a testcase pass/fail marker, so row 58 remains BLOCKED. The raw archive SHA-256 is 280dbe230173d269d8398acef73df23ab56a3d777ce7bca28501cf6e249445db.
