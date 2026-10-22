# Verilator timeout cohort: row 13

`smoke_test_dma_aes_gcm_rd_enc_axi_err` passed on DAN-DESKTOP in Slurm array 1372 task 13. It used 1 CPU, 3 GiB, the pinned Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, QD-BFM commit `dd6d43d5416006a9e77f2458e8df2a5a754f86c7`, and the Verilator 5.052 model (`ea338be98e1e838d3518809ce8899f85a009963c`; model SHA-256 `b6ee29ade1b17547c4b31692ed9a0b48e22031c4551604fd9dc250a81e01ae79`).

The run finished with exit 0, one pass marker, no fail/bad/JTAG errors, final `mcycle=107887`, and 63.408 seconds of simulator wall time. It used plusargs `+CLP_DMA_TB_MODE_NOT_EMPTY`, `+ERR_RESP_START_ADDR=123440000`, and `+ERR_RESP_END_ADDR=123440000`. The corrected c339 baseline is still running in array 1373, so speedup remains pending.

The corrected c339 reference reached its 7,628-second cap after applying the intended AXI error arguments. Its last heartbeat was mcycle 53,626, with no pass/fail or finish marker; it is recorded as TIMEOUT (progress), so speedup remains pending. The raw timeout/exit-137 classification and checksummed evidence are in [`the corrected c339 task archive`](../corrected-timeout-reruns-20261015/task1373_1_smoke_test_dma_aes_gcm_rd_enc_axi_err/README.md).

The copied Verilator result, simulator log/resource report, firmware and vector logs, task resource report, and Slurm log are under this directory. `sha256sum -c remote.SHA256SUMS` passed against the source files before remote output cleanup.
