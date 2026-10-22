# Row 97 internal ML-DSA trace

Slurm job `3228_97` is a one-row diagnostic using the pinned Caliptra SHA `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge SHA `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus c339. It adds observation-only PRE/POST traces around `abr_ctrl`'s ML-DSA verification-result register write. It records `sampler_state_data_i`, verify-valid and clear signals, destination selection, write/clear gates, and register word 0.

Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds. Job metadata and its output archive will be copied here and SHA-256 checked before the run directory is removed.

The overlay only adds `$display`/`$strobe` statements in the run's private source copy and redirects one filelist entry. It does not alter RTL behavior or test criteria.

Job `3228_97` completed in 786.243 seconds with the testcase still classified FAIL. Archive SHA-256: `8bf4ac13888ad7af8b2c5c3e42a033e7ad786fe987d4375eea1047ef1b812f65`. The observer emitted four records, all at 0 ns; it was gated by `mldsa_verifying_process` and did not observe the later verification. This archive is diagnostic evidence only. The corrected observer removes that gate and includes the process flag in each sample.
