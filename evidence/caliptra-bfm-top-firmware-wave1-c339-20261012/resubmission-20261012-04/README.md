# Corrected wave-1 retry

Job 611's 44 rows failed before simulation because the runner inferred `/usr` as the OpenSSL prefix and could not find the Debian multiarch `libcrypto.so`. The protected compatibility prefix `/home/dsell/toolchains/iverilog-c339/openssl` now provides the executable, headers, and `libcrypto.so.3` in the layout the runner expects; exact hashes and path checks are in [`../openssl-prefix-recovery.txt`](../openssl-prefix-recovery.txt).

Slurm job 659 ran the runner's full native-vector preparation with the protected prefix and completed all seven build/check commands successfully. Its output is [`openssl-preflight-659.out`](openssl-preflight-659.out).

Job 660 resubmits only rows 8–51 at throttle 6, using the protected Icarus c339 binaries and OpenSSL prefix. The source snapshot is QD commit `0e331dec3d83ad70e5e73d8f0198dbdd4a226f74`; the submitted script and selection hashes are recorded in `submission.txt`. At the 11:05 MDT checkpoint, tasks 8 and 10–14 were RUNNING, row 9 had a firmware-build `FAIL`, and rows 15–51 were pending. The task-9 failure is documented in [`../terminal-results/README.md`](../terminal-results/README.md).
