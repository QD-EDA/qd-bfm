# Cancelled DMA status probe (invalid address filter)

Job 1766 ran the one-row `cptra_ss_test_rom` diagnostic with a logging-only `M9STAT` probe, but its address filter was wrong. The monitor looked for `0x22818`; the pinned generated register header defines `CLP_AXI_DMA_REG_STATUS0` at `0x3002200c`, and the trace sees the low address offset `0x2200c`. I canceled the job after 5:18, before it produced a `result.json` or terminal outcome. This is not a test result and does not affect the M9 row.

The partial build and simulator logs, resource record, generated overlay, and input hashes are in [`cancelled-evidence.tar.gz`](cancelled-evidence.tar.gz), SHA-256 `e12f43ef96434a3b11c847e3349244363d1ce0c3679c9e9187a4d23cb3be4f6c`. Its QD-BFM source manifest matches the canonical source snapshot and manifest inside diagnostic 02’s [`diagnostic-evidence.tar.gz`](../cptra-ss-dma-axi-20261016-02/diagnostic-evidence.tar.gz). The partial simulator log is also in [`raw/`](raw/).

The corrected readback probe targets `0x2200c` in diagnostic 04.
