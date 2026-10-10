// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "caliptra_reg_defines.svh"
`include "caliptra_reg_field_defines.svh"
`include "kv_macros.svh"

module tb_caliptra_hmac_ahb_bfm;
  import kv_defines_pkg::*;

  localparam [511:0] TEST_KEY = {4{128'h0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b}};
  localparam [1023:0] TEST_BLOCK = 1024'h4869205468657265800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000440;
  localparam [511:0] EXPECTED_TAG = 512'h637edc6e01dce7e6742a99451aae82df23da3e92439e590e43e761b33e910fb8ac2878ebd5803f6f0b61dbce5e251ff8789a4722c1be65aea45fd464e89f8f5b;
  localparam [383:0] TEST_SEED = 384'h00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff;
  localparam [31:0] SHA512_INIT =
    (32'h1 << `HMAC_REG_HMAC512_CTRL_MODE_LOW) |
    `HMAC_REG_HMAC512_CTRL_INIT_MASK;
  localparam [31:0] CTRL_ZEROIZE = `HMAC_REG_HMAC512_CTRL_ZEROIZE_MASK;

  reg clk = 0;
  reg reset_n = 0;
  reg cptra_pwrgood = 0;
  wire hsel, hwrite, hresp, hreadyout, busy, poisoned;
  wire [31:0] haddr, hwdata, hrdata;
  wire [2:0] hsize;
  wire [1:0] htrans;
  wire hmac_busy, hmac_error;
  wire checker_error, monitor_protocol_error;
  wire [3:0] checker_error_code;
  wire [31:0] checker_error_count, monitor_protocol_error_count;
  wire [31:0] address_count, transfer_count;
  wire transfer_fire, transfer_write, transfer_error;
  wire [31:0] transfer_addr, transfer_data;
  reg [`CLP_CSR_HMAC_KEY_DWORDS-1:0][31:0] cptra_csr_hmac_key = '0;
  reg request_ok, success, response_error;
  reg [31:0] read_data;
  reg [31:0] completed_requests = 0;
  reg [31:0] status;
  reg ready_seen;
  reg [511:0] observed_tag;
  integer i, polls;

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

  hmac_ctrl #(.AHB_ADDR_WIDTH(32), .AHB_DATA_WIDTH(32)) dut (
    .clk(clk), .reset_n(reset_n), .cptra_pwrgood(cptra_pwrgood),
    .cptra_csr_hmac_key(cptra_csr_hmac_key),
    .haddr_i(haddr), .hwdata_i(hwdata), .hsel_i(hsel), .hwrite_i(hwrite),
    .hready_i(hreadyout), .htrans_i(htrans), .hsize_i(hsize),
    .hresp_o(hresp), .hreadyout_o(hreadyout), .hrdata_o(hrdata),
    .kv_read(), .kv_write(), .kv_rd_resp('0), .kv_wr_resp('0),
    .busy_o(hmac_busy), .error_intr(hmac_error), .notif_intr(),
    .ocp_lock_in_progress(1'b0), .debugUnlock_or_scan_mode_switch(1'b0)
  );

  task automatic write_word(input [31:0] address, input [31:0] value);
    begin
      manager.transfer_one(address, 1'b1, 3'd2, value,
        request_ok, success, response_error, read_data);
      if (!request_ok || !success || response_error || poisoned)
        $fatal(1, "HMAC AHB write failed at %08x", address);
      completed_requests++;
    end
  endtask

  task automatic read_word(input [31:0] address, output reg [31:0] value);
    begin
      manager.transfer_one(address, 1'b0, 3'd2, 32'b0,
        request_ok, success, response_error, read_data);
      if (!request_ok || !success || response_error || poisoned)
        $fatal(1, "HMAC AHB read failed at %08x", address);
      value = read_data;
      completed_requests++;
    end
  endtask

  initial begin
    manager.reset_master();
    repeat (2) @(posedge clk);
    cptra_pwrgood = 1;
    repeat (2) @(posedge clk);
    @(negedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);

    for (i = 0; i < 16; i++)
      write_word(`CLP_HMAC_REG_HMAC512_KEY_0 + i*4, TEST_KEY[511-i*32 -: 32]);
    for (i = 0; i < 32; i++)
      write_word(`CLP_HMAC_REG_HMAC512_BLOCK_0 + i*4, TEST_BLOCK[1023-i*32 -: 32]);
    for (i = 0; i < 12; i++)
      write_word(`CLP_HMAC_REG_HMAC512_LFSR_SEED_0 + i*4, TEST_SEED[383-i*32 -: 32]);

    write_word(`CLP_HMAC_REG_HMAC512_CTRL, SHA512_INIT);
    ready_seen = 0;
    for (polls = 0; polls < 10000 && !ready_seen; polls++) begin
      read_word(`CLP_HMAC_REG_HMAC512_STATUS, status);
      ready_seen = (status != 0);
    end
    if (!ready_seen)
      $fatal(1, "HMAC did not become ready within 10000 status polls");

    observed_tag = '0;
    for (i = 0; i < 16; i++) begin
      read_word(`CLP_HMAC_REG_HMAC512_TAG_0 + i*4, read_data);
      observed_tag[511-i*32 -: 32] = read_data;
    end
    if (observed_tag !== EXPECTED_TAG)
      $fatal(1, "HMAC-SHA-512 known-answer mismatch: got %0128x", observed_tag);
    if (hmac_busy || hmac_error)
      $fatal(1, "HMAC status is busy/error after digest completion");

    write_word(`CLP_HMAC_REG_HMAC512_CTRL, CTRL_ZEROIZE);
    #1;
    if (checker_error || checker_error_count != 0 || monitor_protocol_error ||
        monitor_protocol_error_count != 0 || address_count != completed_requests ||
        transfer_count != completed_requests || transfer_error || !transfer_fire ||
        !transfer_write || transfer_addr != `CLP_HMAC_REG_HMAC512_CTRL ||
        transfer_data != CTRL_ZEROIZE)
      $fatal(1, "HMAC AHB checker/monitor did not report clean transfers");

    $display("PASS: native AHB BFM completed HMAC-SHA-512 known-answer test (%0d bus transfers)", completed_requests);
    $finish;
  end
endmodule
