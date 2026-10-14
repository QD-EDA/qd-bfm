// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_caliptra_ecc_ahb_bfm;
  import kv_defines_pkg::*;

  reg clk = 0;
  reg reset_n = 0;
  wire hsel, hwrite, hresp, hreadyout, busy, poisoned;
  wire [31:0] haddr, hwdata, hrdata;
  wire [2:0] hsize;
  wire [1:0] htrans;
  wire checker_error, monitor_protocol_error;
  wire [3:0] checker_error_code;
  wire [31:0] checker_error_count, monitor_protocol_error_count;
  wire [31:0] address_count, transfer_count;
  wire transfer_fire, transfer_write, transfer_error;
  wire [31:0] transfer_addr, transfer_data;
  kv_read_t [1:0] kv_read;
  kv_write_t kv_write;
  kv_rd_resp_t [1:0] kv_rd_resp = '0;
  kv_wr_resp_t kv_wr_resp = '0;
  pcr_signing_t pcr_signing_data = '0;
  reg request_ok, success, response_error;
  reg [31:0] read_data;

  always #5 clk = ~clk;

  ahb_lite_caliptra_master #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) manager (
    .HCLK(clk), .HRESETn(reset_n), .HREADY(hreadyout), .HRESP(hresp),
    .HRDATA(hrdata), .HSEL(hsel), .HADDR(haddr), .HWDATA(hwdata),
    .HWRITE(hwrite), .HSIZE(hsize), .HTRANS(htrans), .busy(busy),
    .poisoned(poisoned)
  );

  ahb_lite_caliptra_checker #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) checker_bfm (
    .HCLK(clk), .HRESETn(reset_n), .HADDR(haddr), .HWDATA(hwdata),
    .HSEL(hsel), .HWRITE(hwrite), .HTRANS(htrans), .HSIZE(hsize),
    .HREADY(hreadyout), .HRESP(hresp), .error(checker_error),
    .error_code(checker_error_code), .error_count(checker_error_count)
  );

  ahb_lite_caliptra_monitor #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) monitor (
    .HCLK(clk), .HRESETn(reset_n), .HADDR(haddr), .HWDATA(hwdata),
    .HSEL(hsel), .HWRITE(hwrite), .HTRANS(htrans), .HSIZE(hsize),
    .HREADY(hreadyout), .HRESP(hresp), .HRDATA(hrdata),
    .address_count(address_count), .transfer_count(transfer_count),
    .transfer_fire(transfer_fire), .transfer_addr(transfer_addr),
    .transfer_write(transfer_write), .transfer_size(), .transfer_data(transfer_data),
    .transfer_error(transfer_error), .protocol_error(monitor_protocol_error),
    .protocol_error_count(monitor_protocol_error_count),
    .address_fire(), .transfer_trans(), .transfer_protocol_error(), .cycle_count()
  );

  ecc_top #(.AHB_ADDR_WIDTH(32), .AHB_DATA_WIDTH(32)) dut (
    .clk(clk), .reset_n(reset_n), .cptra_pwrgood(1'b1),
    .haddr_i(haddr), .hwdata_i(hwdata), .hsel_i(hsel), .hwrite_i(hwrite),
    .hready_i(hreadyout), .htrans_i(htrans), .hsize_i(hsize),
    .hresp_o(hresp), .hreadyout_o(hreadyout), .hrdata_o(hrdata),
    .kv_read(kv_read), .kv_write(kv_write), .kv_rd_resp(kv_rd_resp),
    .kv_wr_resp(kv_wr_resp), .pcr_signing_data(pcr_signing_data),
    .ocp_lock_in_progress(1'b0), .busy_o(), .error_intr(), .notif_intr(),
    .debugUnlock_or_scan_mode_switch(1'b0)
  );

  initial begin
    manager.reset_master();
    repeat (4) @(posedge clk);
    @(negedge clk);
    reset_n = 1'b1;
    repeat (4) @(posedge clk);

    manager.transfer_one(32'h0000_0804, 1'b1, 3'd2, 32'h0000_0001,
                         request_ok, success, response_error, read_data);
    if (!request_ok || !success || response_error || poisoned)
      $fatal(1, "AHB BFM write to ECC interrupt enable register failed");

    manager.transfer_one(32'h0000_0804, 1'b0, 3'd2, 32'b0,
                         request_ok, success, response_error, read_data);
    if (!request_ok || !success || response_error || poisoned || read_data !== 32'h1)
      $fatal(1, "AHB BFM ECC register readback failed: %08x", read_data);

    #1;
    if (checker_error || checker_error_count != 0 || monitor_protocol_error ||
        monitor_protocol_error_count != 0 || address_count != 2 || transfer_count != 2 ||
        !transfer_fire || transfer_addr != 32'h0000_0804 || transfer_write ||
        transfer_error || transfer_data != 32'h1)
      $fatal(1, "Caliptra ECC AHB checker/monitor did not report two clean transfers");

    $display("PASS: Caliptra ECC RTL AHB write/readback through native manager");
    $finish;
  end
endmodule
