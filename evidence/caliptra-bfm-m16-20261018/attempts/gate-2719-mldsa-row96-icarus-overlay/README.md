# MLDSA row 96 Icarus overlay gate: job 2719

The row used pinned Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` (binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`). The job requested 1 CPU and 3 GiB; the row timeout was 600 seconds.

Compilation passed in 7.95 seconds at 767,576 KiB peak RSS, so the MLDSA testbench and AHB filelist overlays cleared the compile blockers from job 2715. The test did not run: the generated-UVMF runner omitted `-o <output>/test.vvp` from the compile command. Icarus therefore wrote its default `runtime/a.out` (103,336,115 bytes; SHA256 `248e01def18c1e4cca8026bac25b6925606a40d694ae73f962c39f3ee9fb90cd`), while the runner invoked VVP on the nonexistent `test.vvp` and got exit 255.

This is a runner defect, not a firmware/test result. The raw `result.json` preserves the runner's original `FAIL` classification; this attempt is counted as **NOT RUN (harness defect)**. No VVP simulation ran. The generated compile command is fixed in `run_m15_test.py`; row 96 must pass a fresh one-row gate before this overlay can qualify.

The overlay is limited to generated testbench sources and the filelist. No RTL, firmware, or pass criteria changed. Raw logs, manifests, commands, resource data, staged-source hash, and job metadata are in [`raw/`](raw/).
