# QD-BFM

Small, executable AXI4 single-beat manager BFM for bounded directed tests. It
targets Caliptra v2.1.2's inbound SoC AXI subordinate interface:
`caliptra_top.sv` ports `s_axi_w_if` and `s_axi_r_if` (declared as
`axi_if.w_sub` / `axi_if.r_sub`). The source interface is
`caliptra-rtl/src/axi/rtl/axi_if.sv`; widths are selected by the integration
parameters (`DW=32`, `IW=8`, `UW=32`, and SoC address width from
`CALIPTRA_SLAVE_ADDR_WIDTH(CALIPTRA_SLAVE_SEL_SOC_IFC)`).

`qd_axi4_single_master.sv` implements manager-side read and write tasks for
single-beat, full-width transfers. It holds requests through ready stalls,
times out bounded waits, propagates AXI error responses, and fatals on changed
stalled requests, mismatched response IDs, or missing `RLAST`. Connect its
AXI pins to `s_axi_*_if`; tie unused AXI user and lock fields low, and ignore
response user fields. Its response-ready outputs stay asserted only while the
respective transaction waits for a response. On timeout, VALID remains asserted
to preserve AXI rules; reset the BFM and target before another transfer.

This does not implement bursts, multiple outstanding IDs, partial-width
transfers, user/lock signaling, UVM sequencing, coverage, or Caliptra DV
qualification. The local test uses a tiny independent memory target and does
not compile or modify Caliptra sources.

Run with Icarus Verilog:

```sh
./run.sh
```

The test checks write/read data, request-ready stalls, AXI error responses,
an expected address-channel timeout, and rejection of bad response ID or missing
`RLAST`. A protocol violation terminates with
`$fatal`; the pass banner is printed only after all checks succeed.
