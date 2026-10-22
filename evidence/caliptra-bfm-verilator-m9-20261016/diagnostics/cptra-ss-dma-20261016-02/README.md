# `cptra_ss_test_rom` DMA write trace

This diagnostic was run as Slurm job 1608. It used the pinned Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052, and a logging-only overlay on the DMA register write path. The case retained its normal 6,873-second timeout and had a separate 600-second diagnostic cap. It is not a replacement M9 row result.

## Result

The firmware build completed; the simulation timed out after 600 seconds. At 5,973,000 ns, the trace sampled the 16th write to `CLP_AXI_DMA_REG_WRITE_DATA` with `dv=1`, `write=1`, `hold=0`, `wr_stall=0`, `fifo_valid=1`, `fifo_ready=1`, `depth=15`, `full=0`, `data=67120ad3`, and `swmod=1`. The firmware emitted no marker after the corresponding `lsu_write_32` call.

The trace shows the write presented while the DMA register path reports no stall and the FIFO is ready at depth 15. It localizes the stopped firmware call to completion of this 16th write, after the request reaches the non-full FIFO. It does not reveal why the CPU-visible store completion fails.

## Evidence

- [Result JSON](remote/diagnostic-output/result.json): TIMEOUT, simulator wall 600.004 seconds, model SHA-256 `c318d1f6a8581884676e48356eaf0d39d35951d45f7decca51a501b9ce15f350`.
- [Simulator trace](remote/diagnostic-output/sim.log), [firmware log](remote/diagnostic-output/firmware.log), and [resource record](remote/diagnostic-output/sim.resource).
- [Trace overlay](remote/overlay/axi_dma_ctrl_trace.sv) and [Slurm output](remote/logs/a2-m9-cptra-trace-1608.out).
- The copied outputs and overlay passed [remote SHA-256 verification](remote/evidence.SHA256SUMS).
