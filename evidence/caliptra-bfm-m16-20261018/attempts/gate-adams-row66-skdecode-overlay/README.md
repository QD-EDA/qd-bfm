# Row 66 skdecode width overlay, first gate (job 2696)

This first gate reached simulation and **failed**. Adams Bridge row 66 (`skdecode_normal_test`, seed 1) compiled and ran on DAN-DESKTOP with Icarus source pin `9b5fad2afb4104caa816b257d5bccc40f01b8c66` (binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`), Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. Python was 3.14.4; the row timeout was 600 s; Slurm requested 1 CPU and 3 GiB.

Compile exited 0 in 0.03 s (20,852 KiB peak); simulation exited 0 in 0.10 s (13,196 KiB peak); the runner completed in 0.19 s (24,052 KiB peak). The test log reports `Error: invalid s1 is not detected at 121!`, `*** 01 errors detected during testing.`, and `* TESTCASE FAILED`. Result JSON therefore records `FAIL`; the zero VVP exit is not a pass.

The width-only overlay replaced the two missing `MLDSA_MEM_ADDR_WIDTH` references with package-exported `ABR_MEM_ADDR_WIDTH`. Inspection of the pinned bench and controller found the functional cause: the error test injects invalid input only on keymem A, while the controller reads even source addresses on A and odd source addresses on B. Seed 1 selected odd address 121, so this bench path never injected the invalid value. The older c339 run selected address 108 and passed; that historical result did not expose the odd-address hole and is not current-pin qualification. This is a testbench setup defect, not evidence of an Icarus defect; no simulator issue was filed.

The follow-up overlay also injects the same invalid value on keymem B when the selected address is read there. It changes testbench setup only; RTL and pass criteria stay unchanged. That follow-up is recorded separately under `gate-adams-row66-skdecode-bport-fix/`.

The full Slurm run tree was archived to `raw/capture.tar.gz` (SHA256 `88971b0b5b819ff750b6150777af6988f3c699af499510d37f02cbc012d89d4f`). `raw/SHA256SUMS.local.txt` verifies extracted contents. The remote tree occupied 481,338 bytes before cleanup.
