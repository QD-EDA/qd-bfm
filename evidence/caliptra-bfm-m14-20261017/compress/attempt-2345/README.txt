M14 compress_tb current-main overlay attempt — FAIL

Slurm job 2345 completed on DAN-DESKTOP (1 CPU, 3 GiB; scheduler exit 0). The harness compiled successfully (compile_exit=0), ran the testbench (sim_exit=0), and recorded FAIL: no pass marker, one failure marker. All three modes reported compress_done timeout. The scoreboard did not report packed API write count/address/data mismatches. The intern summary independently matched the log; its no-cause interpretation was checked against the log and RTL.

This is not a simulator defect. The pinned current-main filelist is blocked by a missing package and stale testbench ports; the overlay fixes setup and adapts to the current compress_top interface, but its completion check fails. The next diagnostic overlay will print the completed cycle count, output count, and controller/pipeline state on timeout.

Pins: Caliptra RTL 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e; Adams Bridge b77e3d899e828d626cfc2a0d26a6b5704cc121e0; Icarus source 9b5fad2afb4104caa816b257d5bccc40f01b8c66. Tool binary hashes and source/filelist hashes are in raw/task/tool-binaries.sha256 and raw/task/input-sha256.txt. Exact Slurm script, runtime overlay, logs, versions, resource reports, result, and source revisions are preserved under raw/.

The copied run tree was byte-for-byte hash-verified against DAN-DESKTOP before cleanup. The disposable remote run tree was removed after preservation; bytes freed: 149469.
