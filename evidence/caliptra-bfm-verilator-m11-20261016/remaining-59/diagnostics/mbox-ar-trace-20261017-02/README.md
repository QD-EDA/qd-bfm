# M11 MBOX AR handshake trace

Purpose: observe the assertion-sampled ARVALID/ARREADY values, post-edge live values, and the exact clocking-block sample used by the BFM on the first MBOX lock read. This is a diagnostic-only overlay generated from the pinned M11 overlay; it does not change the official M11 overlay.

Target: `smoke_test_mbox` (`78bfcc1e9aac255e`), c339 PASS versus M11 overlay FAIL at `AXI_SUB_AR_HSHAKE_ERR`.

Pinned inputs: QD-BFM source and Caliptra RTL are copied from M11 run 1964's staged snapshot; RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Verilator 5.052 with assertions enabled. The diagnostic adds traces only for AXI address `0x30020000` (MBOX lock). The one-row simulation cap is 600 seconds.

This version fixes the width comparison. Build job 2049 completed in 1:32.01 with 2,381,472 KiB peak RSS. Run job 2051 ended `FAIL` at `AXI_SUB_AR_HSHAKE_ERR` after 39.773 seconds of simulation; the 600-second cap did not fire. Model SHA-256 is `d59b809ae0d560aba276a2f84d7e57acdb0497c7ecce454bf48303a0ca3675c9`; diagnostic `axi_if.sv` SHA-256 is `bdd55119ee569d9240f35bf0097f0783958652560e03d33364bbb9fdd4e46635`. The raw run archive is [`raw/diagnostic-run.tar.gz`](raw/diagnostic-run.tar.gz), SHA-256 `6d06d968d50113423313947c3e4db82752f52a279054d27de38f11a69bae2821`.

The width-corrected interface monitor captured 68 assertion-edge samples at `0x00020000`: 67 were `ARVALID=1, ARREADY=1`, and one was `ARVALID=0, ARREADY=1`. None showed `ARVALID=1, ARREADY=0`. The task-level trace still reports sampled `ARVALID=0` and live `ARVALID=1`; because it lacks an interface instance path, this capture does not establish that it is observing the subordinate instance whose assertion failed. The exact assertion-boundary monitor is in version 3.

After verifying the archive checksum, the finished remote build/result tree was removed; cleanup freed 727,866,781 bytes.
