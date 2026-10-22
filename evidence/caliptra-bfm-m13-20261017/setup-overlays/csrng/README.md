# CSRNG setup overlay gate

The pinned-only M13 row `caliptra-v2-1-2-csrng_tb` failed at compile because `caliptra_prim_ram_1p_pkg` is listed after its importer and `caliptra_reg_field_defines.svh` is outside the include path. This one-row overlay copies the established QD-BFM filelist correction; it does not modify the pinned RTL or filelist in the protected source tree.

The overlay filelist SHA-256 is `ff0dbcf62b06eaf7f307697def2c20073f9d6c3551b08b3e8c2b8d3140583c83`; the pinned source filelist SHA-256 is `78614e6aa69492f44feadd10d8f2243e88e1143bf0cb08ac9dbbc965b9236bc6`. The patch adds `src/integration/rtl/caliptra_reg` and moves `caliptra_prim_ram_1p_pkg.sv` before the generic RAM that imports it. The patch and runner are checksummed alongside this note.

Job 2251 is the one-row overlay gate, using the M13 Icarus main SHA `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, Caliptra SHA `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and 6,900-second total process cap. It passed: compile 0.31 s / 76,980 KiB peak RSS; simulation 3.73 s / 32,900 KiB peak RSS; one testcase pass marker and zero failure markers. The run archive SHA-256 is `01a4423a2b18e3ad30560328bd42b332ae7381875be17c4e82c26a6b23087d00` in [`run-2251/`](run-2251/). The completed Slurm run directory and temporary archive were removed after the local copy hash matched the remote hash.
