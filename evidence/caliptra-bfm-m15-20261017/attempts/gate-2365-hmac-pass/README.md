# M15 HMAC one-row gate: PASS

- Slurm job 2365, array task 0; row 5 `HMAC_otf_reset_test`.
- Host: DAN-DESKTOP, Linux 6.18.33.1 WSL2; current-main Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- Caliptra source pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; YAML SHA256 `0c0cf5f3f1466dd3a521ce1d0901187a150c5517e8e8441a5f4eaed089ed9c12`.
- Exact selector and seed: `+UVM_TESTNAME=HMAC_otf_reset_test +ntb_random_seed=1`.
- Runner timeout 600 seconds; wall time 7.148 seconds; compile and simulation exit codes 0; result PASS. The run log contains `* TESTCASE PASSED`, `UVM_ERROR : 0`, and `UVM_FATAL : 0`.
- Three source-hash-guarded edits are limited to generated HMAC testbench coverage/configuration/sequence files; the existing monitor/reset and test-generation setup overlays are also recorded in their manifests. No RTL, firmware, or pass criteria changed.
- `gate.sbatch`, row selection, submission record, full result JSON, command/resource records, compile/run logs, overlay manifests, and generated testbench overlays are preserved here. The compiled VVP image was removed after evidence capture.

The runner and shell hashes for this gate match commit `0aea6ebe`.
