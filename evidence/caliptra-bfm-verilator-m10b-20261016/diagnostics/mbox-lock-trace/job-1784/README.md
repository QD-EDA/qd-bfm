# MBOX lock edge trace — job 1784

This logging-only Verilator 5.052 run used pinned Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, with assertions disabled so the unrelated AW assertion would not stop execution before MBOX. The model built in 4:31 wall time with 2,360,500 KiB peak RSS; model SHA-256 is in `model.sha256`. Simulation hit the separate 180-second outer cap (`wrapper_exit=124`), so this is diagnostic evidence, not an official test result.

## First lock response

The CSR logger sees the first read at its cycle 56915 (`time=5694000`): `ack=1`, stored lock value 0, `next=1`, `load=1`, and `readback=rd_data=0`. After the edge the stored value is 1. This is the pinned software-set-on-read behavior.

On the AXI interface, the preceding negedge sample at cycle 56941 has `valid=1`, `ready=0`, and `data=0`. At posedge cycle 56942, the active-region sample has `valid=1`, `ready=1`, and `data=0`; the post-update `$strobe` at that same edge has `data=1`. The following negedge reports `data=1`. The AXI read task then logs sequence 1 as `rdata=1` and returns 1.

The pinned `get_read_beat` waits on `@(posedge clk)` and then reads live `rdata` in the task process (`axi_if.sv:216–220`). The edge trace shows that the handshake's pre-update value is 0, while the live signal changes to 1 in that posedge scheduling slot and the task returns 1. This is the cause of the MBOX disagreement: an active-region scheduling race in the testbench AXI read sampler. Icarus's one-poll grant is consistent with capturing the pre-update value 0; no RTL functional change is needed to explain this row.

The trace log, build records, filelist, source copies, and remote SHA-256 manifest are preserved in this directory and were verified against DAN-DESKTOP before the remote run was removed. Cleanup freed 718,407,725 bytes.
