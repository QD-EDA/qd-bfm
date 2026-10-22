# `cptra_ss_test_rom` DMA arbitration trace

This diagnostic-only run used Slurm job 1757, Verilator 5.052, the pinned Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and the M9 QD-BFM source commit `c25f3e750ce090cd7f0b4ed63f86a6a5f22e879c`. It used a 4-CPU, 4-GiB allocation and a separate 600-second simulation cap. It is not a replacement M9 row result.

## Finding

All 16 `CLP_AXI_DMA_REG_WRITE_DATA` stores reach the DMA register with `hold=0`, `wr_stall=0`, `fifo_ready=1`, and increasing FIFO depth. On word 15 (`depth=15`), the CPU arbiter trace also shows `uc_dma_gnt=1`, `uc_req_hold=0`, `dma_reg_req_hold=0`, and no collision. The CPU continues after that store and polls `CLP_AXI_DMA_REG_STATUS0`; these requests are granted without a hold. So neither the FIFO write nor the SoC/CPU arbiter blocks the firmware.

The diagnostic reaches its 600-second cap while firmware is still waiting for DMA `STATUS0.BUSY` to clear. This localizes the timeout after FIFO admission, in DMA transfer completion. The run did not trace the DMA's outbound AXI address, data, or response handshake; the downstream cause remains open pending the AXI-path trace.

## Evidence

- [Hash-verified raw diagnostic archive](remote/diagnostic-evidence.tar.gz) and [SHA-256 sidecar](remote/diagnostic-evidence.tar.gz.sha256).
- `diagnostic-output/result.json` records `TIMEOUT` at the separate 600-second cap; the official M9 timeout remains unchanged.
- `diagnostic-output/sim.log` contains all 16 DMA register writes and the later status polls. `overlay/axi_dma_ctrl_trace.sv` and `overlay/soc_ifc_arb_trace.sv` are logging-only copies; the pinned RTL was not modified.
