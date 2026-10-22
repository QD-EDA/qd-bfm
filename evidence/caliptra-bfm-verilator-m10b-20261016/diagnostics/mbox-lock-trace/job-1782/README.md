# MBOX lock edge trace — job 1782

This logging-only Verilator 5.052 run used pinned Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, with assertions disabled because the unrelated pinned AW assertion stops the model before the mailbox read. The model built successfully (4:03 wall, 2,360,248 KiB peak RSS; SHA-256 in `model.sha256`). The simulation reached the first lock request but hit its outer 180-second cap (`wrapper_exit=124`); it produced no terminal result and does not replace the official M9 `TIMEOUT` row.

At cycle 56915, the first read is decoded with `ack=1`; `mbox_lock.lock.value` is 0, `next=1`, `load=1`, and both `readback` and `rd_data` are 0. After the edge, the field is 1 while readback remains 0. The associated first AXI response is logged as `RDATA=1`, `RRESP=0`. At cycle 56918, the next decoded lock read sees the field and readback as 1. The source confirms that this CSR sets the lock on read and computes its readback from the stored field value.

This ties the observed busy value to the read-to-set lock handoff. The existing AXI task samples live `rvalid/rdata` after `@(posedge clk)`, so this log alone does not establish whether the first response was already stable before that edge or changed in the same scheduling slot. Job 1784 adds negedge, active-region posedge, and post-update samples to make that distinction.

The complete simulator log, build log/resource record, tool version, model hash, staged-input manifest, and their source files are preserved in this directory. The remote run directory was removed after local copies were hash-verified, freeing 719,236,391 bytes.
