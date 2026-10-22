# Traced one-row attempt 1797

Host: DAN-DESKTOP. Test: `smoke_test_ahb_mux` (`cadf43c78de6a454`), with a 600-second outer timeout, 1 CPU, and 3 GiB. The firmware built successfully, but the assertion-enabled simulator returned `FAIL` at 4 ns with `AXI_SUB_AW_HSHAKE_ERR`. No AW/W/B trace line appeared. The result, simulator log, resource files, and Slurm output are in [`output.tar.gz`](output.tar.gz), SHA-256 `763f15b71420cf2d3d97a49b10e2f99d500954aceea8c97098ab79b7da9c19f8`.

The diagnostic probe compared `awaddr` with the full logical address `0x30030200`. Verilator's generated code shows the `m_axi_bfm_if` address is 19 bits, so the observed bus value is the low 19 bits, `0x30200`; the comparison was optimized away. The probe now casts the logical address to the interface's `AW` width. This attempt is not an overlay pass and does not authorize restarting the array.
