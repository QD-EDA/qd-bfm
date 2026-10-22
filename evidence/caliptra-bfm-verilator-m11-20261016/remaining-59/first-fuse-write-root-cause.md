# Array 1772 first-fuse-write stall

Array 1772 was canceled after all six active rows stopped at `SoC: Writing obfuscated UDS to fuse bank` while consuming a full CPU. The archived rows have no firmware outcome and are excluded from result tables.

The stall was in the overlay's AXI handshake wait. The earlier wait used a clocking-block event that Verilator spun on at the first AW transfer. The v2 generator replaces that wait with `@(posedge clk)` and samples AWREADY, WREADY, and BVALID through `#1step` clocking-block inputs; it drives the write channels nonblocking. The exact generator and pinned-source checks are in [`prepare_axi_if_overlay.py`](../../caliptra-bfm-verilator-m10b-20261016/diagnostics/array-1772-hang/overlay-v2/array-1835/prepare_axi_if_overlay.py), and the generated overlay SHA-256 is `d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`.

The traced one-row run on `smoke_test_ahb_mux` reached the first fuse write at AW address `0x30200`: AW accepted at realtime 3.65 ns, W accepted by 3.95 ns, and the B handshake was recorded at 3.95 ns. Firmware then passed with `mcycle=3973`; the 600-second outer cap was not reached. See the [trace run record](../../caliptra-bfm-verilator-m10b-20261016/diagnostics/array-1772-hang/run-1812/README.md) and its archived log. The separate v2 one-row gate (job 1834) also passed within a 600-second cap before array 1835 was submitted. Array 1835 completed its 103-row selection.

This supports the handshake-wait diagnosis and validates the fix on the first fuse write. The canceled run itself has no internal event trace, so it does not independently distinguish a zero-delay scheduler loop from every other cause of the stalled log.
