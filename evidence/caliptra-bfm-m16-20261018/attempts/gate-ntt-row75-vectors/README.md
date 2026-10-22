# M16 row 75 vector-staging gate

Row 75 (`ntt_normal_test`) compiled and ran on the pinned Adams Bridge and current-main Icarus after the runner copied the contents of `tb/test_vectors/` into the runtime working directory. This fixes the original missing `ntt_unmasked_input.hex` setup failure without changing RTL, firmware, or the testbench.

The run ended with exit 0 after 239.094 seconds and printed `End of test`. It is recorded as **BLOCKED**, not PASS: the log has no configured `TESTCASE PASSED` marker or exact zero-error suite summary. Source inspection found mismatch messages printed with `$display`; `error_ctr` is only declared and initialized, never incremented or checked. Adding a success marker or inferring PASS from process completion would change the pass criteria, so no such change was made. The intern's log summary was checked against the preserved log and source.

- Job: 2672, Slurm host `DAN-DESKTOP`, Linux x86_64 / WSL2.
- Source: Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; YAML SHA256 `dd7461775dd89940ac00f5e3892ad7c8f1f6dea9c219b3b68f4a413cd386f76d`; filelist SHA256 `78dfcb30cec74796efea8b868c04698bfda6a211ec70df0abfb2838342d46dd2`.
- Icarus source pin: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- Resources: one CPU, 3 GiB requested, 600-second per-row timeout; run completed within the cap.
- Local runner unit tests: 13 passed. Targeted vector-staging test passed.
- The full task logs, generated runtime, vector hashes, resource records, job metadata, staged runner/manifest, and submit script are under [`raw/`](raw/).
- The 40,574,418-byte Slurm run tree was removed after copying and hash-verifying the evidence. The compiled VVP image was not retained.
