# ML-KEM row 95 setup gate

Fresh one-row gate for row 95, ML_KEM_randomized_keygen_test. The M20 overlay builds the existing QD-BFM native ML-KEM reference helper, checks it against pinned Adams Bridge keygen/encapsulation KATs, stages it under ml-kem/, creates the expected tv/ directory, and provides the python3.9 executable name used by the pinned sequence.

The native helper and its Python wrapper/checker are local ignored workspace inputs, so they are staged separately from the tracked QD-BFM source snapshot and individually hashed. The overlay changes setup only: RTL, firmware, stimulus, input seeds, expected values, assertions, and pass criteria are unchanged. Resources: 1 CPU / 2 GiB; 1,800-second runner cap; 2,100-second Slurm limit.

Job 3242 completed `PASS` on DAN-DESKTOP in 1,329.816 seconds (1 CPU / 2 GiB; Python 3.14.4, GCC 15.2.0, OpenSSL 3.5.5; pinned Icarus `cae035642e056644274a01e98d4422ce286685b4`, binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`). The ML-KEM key-generation validation completed, `* TESTCASE PASSED` was logged, and final UVM_ERROR/UVM_FATAL counts were both zero. The local native helper also passed pinned keygen/encapsulation KATs and rejected malformed input. This is `PASS_OVERLAY` because the test required per-run native-model setup, Python shim, and `tv/` directory.

Archive: `raw/job-3242-95.tar.gz`; SHA-256 `dcf1dc49df9ca1c0dd282f868e64d1f3d7cd76fe563872649c690912618f79c5`, matching the remote sidecar. The archive includes the result, complete simulation log, setup manifest, KAT output, and staged native model evidence.
