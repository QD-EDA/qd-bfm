# M11 MBOX AR handshake trace

Purpose: observe the assertion-sampled ARVALID/ARREADY values, post-edge live values, and the exact clocking-block sample used by the BFM on the first MBOX lock read. This is a diagnostic-only overlay generated from the pinned M11 overlay; it does not change the official M11 overlay.

Target: `smoke_test_mbox` (`78bfcc1e9aac255e`), c339 PASS versus M11 overlay FAIL at `AXI_SUB_AR_HSHAKE_ERR`.

Pinned inputs: QD-BFM source and Caliptra RTL are copied from M11 run 1964's staged snapshot; RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Verilator 5.052 with assertions enabled. The diagnostic adds traces only for AXI address `0x30020000` (MBOX lock). The one-row simulation cap is 600 seconds.

Build job 2039 completed in 4:07.68 with 2,381,376 KiB peak RSS. Run job 2045 ended `FAIL` at the assertion after 40.401 seconds of simulation; the 600-second cap did not fire. Model SHA-256 is `90e6881a0dbe0f1c670744d85e99c9d99fadf87cd44c66a05ccdbe9b016243dd`; the diagnostic `axi_if.sv` SHA-256 is `07b4790b4e26a90c674ceafb375e002109a6193be0b24420dc286f9f120d642e`. The raw run archive is [`raw/diagnostic-run.tar.gz`](raw/diagnostic-run.tar.gz), SHA-256 `3ba9eddb893ecb56edbb567b49caeafaaab3e1c54d901620504abed82c89ea79`.

The task trace repeatedly records the clocking-block sample as `ARVALID=0, ARREADY=1` while the live values are `ARVALID=1, ARREADY=1`, from time 5,697,000 through 5,717,000, followed by `AXI_SUB_AR_HSHAKE_ERR` at 5,718,000. However, version 1 compared the 18-bit interface address to an untruncated 32-bit literal, so its module-level assertion-edge monitor never activated. The task-level observations alone do not prove what the assertion sampled and are not used to classify the root cause. Version 2 uses the interface-width cast and captures the missing monitor.

After verifying the local archive checksum, the finished remote build/result tree was removed; cleanup freed 727,818,252 bytes.
