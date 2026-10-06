# PCRVault client master

`pv_caliptra_master.sv` is a task-based master for the packed PV crypto-client
signals in Caliptra's `pv_defines_pkg`. Compile that package before this module.
The `READ_INDEX` and `WRITE_INDEX` parameters select the corresponding client
lanes; instantiate multiple masters to drive other lanes.

```systemverilog
pv_caliptra_master #(.READ_INDEX(0), .WRITE_INDEX(0)) pv_client (
  .clk(clk), .rst_n(rst_b),
  .pv_read(pv_read), .pv_rd_resp(pv_rd_resp),
  .pv_write(pv_write), .pv_wr_resp(pv_wr_resp)
);
```

Call `write_one(entry, offset, data, request_ok, success, response_error)` to
assert `write_en` through one rising edge. Call
`read_one(entry, offset, request_ok, success, response_error, last, data)` to
drive a lookup and sample the combinational response on the next rising edge.
One read and one write may be active concurrently. A second request on the
same channel is rejected while its task is active. Invalid lane indices
trigger a time-zero fatal; unknown or out-of-range entry/offset requests
return `request_ok=0`, `success=0`, and `response_error=1`. Reset clears the
driven request and reports an interrupted transfer.

The real-DUT smoke is
[`evidence/caliptra-bfm-pv-actual-rtl-20261004`](../../../evidence/caliptra-bfm-pv-actual-rtl-20261004/README.md).
It uses the pinned `pv` RTL and the native AHB-Lite manager for an independent
register readback. It is a client-pin BFM, not a replacement UVMF agent,
transaction coverage model, or full Caliptra environment.

`dv/caliptra_bfm/uvm/pv_caliptra_uvm_pkg.sv` provides a native UVM
sequencer/driver/monitor over a command interface. Its proxy invokes this same
task BFM, so reset handling and PV response sampling remain in one driver. The
focused UVM run writes and reads all dword offsets of a real PCRVault entry,
checks bounds/reset handling, and validates monitor results:
[`evidence/caliptra-bfm-pv-uvm-actual-rtl-20261004`](../../../evidence/caliptra-bfm-pv-uvm-actual-rtl-20261004/README.md).
