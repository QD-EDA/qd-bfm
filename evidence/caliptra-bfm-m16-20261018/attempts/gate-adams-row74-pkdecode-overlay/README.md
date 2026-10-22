# M16 authored row 74: PKDecode

**PASS with testbench overlay**, Slurm job 2774 on DAN-DESKTOP. The current-main pinned-only gate was previously blocked at the stale `.MEM_ADDR_WIDTH` DUT parameter.

The hash-guarded testbench overlay uses `ABR_MEM_ADDR_WIDTH`, removes the unsupported DUT parameter, and changes the second source base from `0x20` to `0`. The pinned DUT reads API address zero; the prior run with source base `0x20` produced 1,790 explicit mismatches, while the earlier corrected run completed both comparisons with zero mismatches. This is a testbench/input-address correction, not a simulator defect. The comparison loop and mismatch reporting were left unchanged; no RTL, firmware, or pass criteria changed.

Compile and simulation exited 0. Both built-in PKDecode comparison sections completed and the log reached `$finish`; the log contains no mismatch lines. The generated `input_pk.hex` and `output_decoded_pk.hex` are preserved with the logs and hashes in [`raw/capture.tar.gz`](raw/capture.tar.gz). The runner recognizes the two completed comparisons only when there are no existing mismatch markers and VVP exits 0.

Pins: Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Python 3.14.4 / NumPy 2.5.4 were on the job PATH. Compile, simulation, and runner peaks were 13,588 KiB, 12,008 KiB, and 25,032 KiB. The job requested one CPU, 256 MiB, and a 600-second row timeout.

**Selection limit:** the YAML contains only `testname` and `seed`; this handwritten top ignores `+UVM_TESTNAME` and runs its two fixed comparison cases unconditionally. This evidence validates those built-in cases, not selectable per-YAML variation.

The capture SHA256 is `7219481654daec43771b49dfec38dbee430df072beac2d3c3f7aaefa9d681195`. The remote run tree was removed after capture verification.
