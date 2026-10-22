# M16 row 72 `sigdecode_z_normal_test`

**PASS with testbench overlay** on DAN-DESKTOP, Slurm job 2702. Pinned-only remains **BLOCKED**: the M15 compile stops on the undefined `MLDSA_MEM_ADDR_WIDTH` testbench parameter. The overlay uses `ABR_MEM_ADDR_WIDTH` and removes the obsolete second argument from each of two task calls. The RTL, firmware, and output comparisons are unchanged.

The run used Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus `9b5fad2afb4104caa816b257d5bccc40f01b8c66` (compiler SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`). Source testbench SHA256: `de917095eee8bff95a9f95336ab8a5452c5ed5e7dd8be4937919b7a5d853aa1c`; pinned filelist SHA256: `343542e71a3dee1407daac37f46b7f6a53a957473fde972df48188cab54fe11c`; test YAML SHA256: `7d772c0dd889e85411ffb6d009801c5c1695eaad8d5a28e57e4fb962fb0b0c2f`.

Compile and simulation exited 0 without timeout. Both output comparisons completed, there were no mismatch or runtime-error lines, and VVP reached `$finish`. NumPy 2.5.4 generated nonempty `input_z.hex` and `output_decoded_z.hex` (10,481 and 10,536 bytes). Runner elapsed time was 0.153 s; peak RSS was 35,952 KiB. The job requested 1 CPU / 3 GiB and the row timeout was 600 s.

The capture includes commands, logs, vectors, hashes, overlay manifest, and result JSON. Capture SHA256: `289732110c4c801cc0b5dfaee84fa05d0e9a92727800f072705466a0a53959f6`; `SHA256SUMS.local.txt` lists the verified member hashes. The remote run tree was removed after the capture was copied and checked.
