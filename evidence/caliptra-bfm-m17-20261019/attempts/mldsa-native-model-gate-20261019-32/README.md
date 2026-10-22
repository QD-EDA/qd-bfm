# MLDSA native-model setup gate

One-row gate for row 78 after extending setup to stage the pinned Dilithium reference executables for generated ML-DSA rows, including the tracked stream-message model. The gate used pinned Icarus, one CPU, 4 GiB, and the 600 s per-row timeout. It changes testbench setup only.

The native-model setup succeeded: both `test_dilithium5` and `test_dilithium5_strm_msg` were staged. Compilation passed. Simulation wrote through `MLDSA_SIGNATURE[1153]` and then reached the configured timeout without a test verdict, so row 78 is `TIMEOUT`, not a crypto failure.

- Slurm job: 2977 (`DAN-DESKTOP`); exact run metadata is in the raw archive.
- Source snapshot SHA-256: `ddd3ec97af2005e00508077bc80b7735a2f9c52ed18c741e3f8c2cf5d9c0dec7`.
- Raw result archive: [`job-2977-row78.tar.gz`](raw/job-2977-row78.tar.gz).
- Archive SHA-256: `928aab812f7089bae1f65015732bb8e53b577d02578fe0eeeccaa005be20859c` (matches the remote copy).
