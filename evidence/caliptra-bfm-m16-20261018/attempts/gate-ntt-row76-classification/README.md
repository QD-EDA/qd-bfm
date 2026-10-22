# M16 row 76 pinned-only classification gate

Job 2675 reran Adams Bridge row 76 (`butterfly_normal_test`) on pinned Icarus without a testbench overlay. Compile and simulation exited 0 in 0.150 seconds, but the testbench printed `Test failed at NTT operation` and `Test failed at INTT operation`. The previous M15 result was BLOCKED because the runner did not recognize these messages. The classifier now records the explicit failure as **FAIL**; it does not change PASS criteria.

The prior job 2674 used the pre-fix classifier and is retained at `../gate-ntt-row76-vectors/raw/` as superseded diagnostic evidence. The current result, full logs, copied runtime/vector files, resource records, submit script, and hashes are under `raw/`.

Pinned inputs: Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, YAML SHA256 `672aa5cf11e0602f17cfe52982efcab5647bf024c4508705adb6c771f4bafd15`, filelist SHA256 `7ec4c3c885c020442163498172a95034956a9ea21f3ec27b5fbc9b9b953957b5`. Icarus source pin `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.

The task used one CPU, 3 GiB, and a 600-second row cap. The 1,754,828-byte Slurm run tree was removed after evidence capture and hash verification.
