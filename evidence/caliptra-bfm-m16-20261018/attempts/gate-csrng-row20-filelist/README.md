# CSRNG authored row 20

Row 20 (`csrng_test`, seed 1) is **PASS with filelist overlay** on the current pinned Icarus. M15 pinned-only evidence is **BLOCKED**: the RAM configuration package is listed after the generic RAM module that imports it. Attempt 2709 moved that package earlier and reached the next missing include path, `caliptra_reg_field_defines.svh`; the follow-up adds its pinned include directory and passes. See both captures under this directory.

The passing run was Slurm job 2713 on DAN-DESKTOP. Caliptra is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge at `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; Icarus source at `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Python was 3.14.4 with NumPy 2.5.4 available. The gate requested 1 CPU / 3 GiB, with a 20-minute Slurm cap and 600-second per-row timeout.

Compile and simulation both exited 0 without timeout. The log contains `* TESTCASE PASSED`, `*** All 00 test cases completed successfully.`, and `$finish` at time 31742; no failure, error, fatal, or mismatch marker was found. It also has 252 non-fatal warnings that `csrng_reg_top.sv:2386` has an unhandled `priority or unique case` value. Runner elapsed time was 4.06 seconds; compile peak RSS was 77,008 KiB and simulation peak RSS 32,852 KiB.

The overlay changes only `csrng_tb.vf`: it adds the existing `src/integration/rtl/caliptra_reg` include directory and orders the existing RAM package before its importer. No RTL, firmware, or pass criteria changed. The original filelist hash is `78614e6aa69492f44feadd10d8f2243e88e1143bf0cb08ac9dbbc965b9236bc6`; the passing overlay filelist hash is `1b6b1416f2d56375790f6aacfbc41a707c01fb3cd574f719e3fe2a9c730a4ef3`.

## Captures

- Attempt 2709: **BLOCKED** on the next include directory after correcting package order. Capture SHA256: `2b3f8d913a4b4a34ed7b659787b5cfb19efc1f41accfab83ba826456c780ea28`.
- Attempt 2713: **PASS with overlay**. Capture SHA256: `a6e7a0d4eba89b4c07bf2ad0c67badd63cfc207c1808c5512b786ebf43f139e1`.
