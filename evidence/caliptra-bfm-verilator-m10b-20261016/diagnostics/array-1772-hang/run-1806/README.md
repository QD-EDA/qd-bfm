# AW overlay plus first fuse-write trace, job 1806

Host `DAN-DESKTOP`; row `smoke_test_ahb_mux` (`cadf43c78de6a454`), with 1 CPU, 3 GiB, and a 600-second outer cap. The model SHA is `5e54117d60230e48aab9e49b5d4f1b443d4fc1c2af1b0351f1efd35e6d2b4938`. The instrumented AW-only overlay SHA is `4d06cc296a15920453d77b1cd4a163ac4e9499ce4326e452e8c2636749f8fec5`.

The event trace records the first AW at realtime 3.55, W activity at 3.85, and BVALID/BREADY at 3.85. The simulation then fails at 5 ns with `AXI_SUB_W_HSHAKE_ERR` (axi_sub_wr.sv:398). The AW assertion is gone, but this run has no firmware result and cannot qualify for the overlay comparison. The W task uses the same blocking/post-edge handshake pattern implicated in the AW failure. The next candidate applies the edge-sampled/nonblocking handling to W as well and adds clock-sample trace records.

The full row output and trace are in `outputs.tar.gz`; its checksum is alongside it. The `result.json`, `sim.log`, `FILE-SHA256SUMS`, and resource record in the archive were verified against the remote output.
