M14 compress_tb diagnostic one-row gate — FAIL

Job 2346 completed on DAN-DESKTOP in one second (1 CPU, 3 GiB). Compile and simulation exited 0, but the testcase produced no pass marker and failed its completion check in all three modes. At each test timeout, the scoreboard had exactly the expected API write count (32/32, 160/160, 352/352); the final captured controller/pipeline state was idle/read_done=1, busy=0, valid=0, hold=0, buffers empty, and api_rw_en=0. This shows the compressed writes drained successfully and the RTL busy state had returned low, while the testbench's negedge-only poll did not retain the completion event. The next change makes the testbench latch compress_done at the rising edge and keeps the same required completion check and scoreboards.

Pins: Caliptra RTL 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e; Adams Bridge b77e3d899e828d626cfc2a0d26a6b5704cc121e0; Icarus 9b5fad2afb4104caa816b257d5bccc40f01b8c66. Raw logs, diagnostic overlay, exact run script, resource/version files, result, and revisions are preserved under raw/. The remote copy was hash-verified before run-tree cleanup.

Remote run-tree bytes freed: 151056.
