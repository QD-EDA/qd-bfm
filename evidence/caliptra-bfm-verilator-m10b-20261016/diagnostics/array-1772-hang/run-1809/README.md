# AW/W edge-sample diagnostic row, job 1809

Host `DAN-DESKTOP`; row `smoke_test_ahb_mux` (`cadf43c78de6a454`), with 1 CPU, 3 GiB, and a 600-second outer cap. Model SHA-256 `bf548868ab517f17a1da69ef152e16fa58bacb919feac0082d9767f03a804b5d`; candidate overlay SHA-256 `782c46c617c90111bd3ca91cab2739ca6d548ebfeb1a56d83b4b482ac6ff033f`; trace variant SHA-256 `c2bd16110f07bbb1a94c721da6601e5cbd0cb6831488c816f8dd842aae6c1d61`.

The first AW/W/B sequence now gets past `AXI_SUB_AW_HSHAKE_ERR` and `AXI_SUB_W_HSHAKE_ERR`, but fails at 5 ns on `AXI_SUB_B_HSHAKE_ERR` (axi_sub_wr.sv:399). The edge-sample trace shows the B response appears after the last logged sample, so the next trace will remain active beyond the B handshake. This run is still a FAIL before a firmware result. The next candidate changes BREADY timing only, using the same pre-edge sample method for BVALID.

Complete output archive: `outputs.tar.gz`; its checksum is alongside it.
