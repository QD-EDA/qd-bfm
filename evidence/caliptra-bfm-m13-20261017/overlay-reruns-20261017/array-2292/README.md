# M13b overlay reruns, Slurm array 2292

Submitted on DAN-DESKTOP at 2026-10-17 16:47 MDT, with three 1-CPU/1-GiB tasks and a 6,900-second per-row timeout. Inputs use Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus main `9b5fad2afb4104caa816b257d5bccc40f01b8c66`.

- `ecc_montgomerymultiplier_tb` passed with five vectors and one testcase pass marker.
- `pkdecode_tb` stopped at compile because this first overlay added the width alias but retained the obsolete `.MEM_ADDR_WIDTH` DUT override. Its corrected current-main run is job 2302, archived in [`../pkdecode-corrected-2302/`](../pkdecode-corrected-2302/).
- `ecc_top_tb` timed out at 6,900 seconds with its valid ten-vector input. TC0–TC3 completed keygen, signing, verify, and DH successfully; TC4 keygen began before timeout. The log contains no mismatch or failure marker. `result.txt` reports zero generic pass markers because this testbench uses testcase-specific success messages, not the runner's generic marker; the sim log is the source for the four completed testcase groups.

The terminal task logs, vector, source/toolchain hashes, and resource report are archived under `tasks/caliptra-v2-1-2-ecc_top_tb/`. The compiled `.vvp` output and C vector-generator executables were excluded; their source, vector input, and recorded hashes remain. The 58-file SHA-256 manifest passed verification, after which the Slurm run directory was removed, freeing 6,649,934 bytes; the protected toolchain remains under `/home/dsell/toolchains/`.
