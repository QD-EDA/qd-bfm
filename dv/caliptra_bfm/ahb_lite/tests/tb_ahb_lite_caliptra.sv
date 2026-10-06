// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_ahb_lite_caliptra;
  localparam integer MAX_BURST_BEATS = 16;
  reg HCLK = 0;
  reg HRESETn = 0;
  reg [7:0] wait_cycles = 2;
  reg inject_error = 0;
  wire HSEL;
  wire [31:0] HADDR;
  wire [63:0] HWDATA;
  wire HWRITE;
  wire [2:0] HSIZE;
  wire [1:0] HTRANS;
  wire busy;
  wire poisoned;
  wire HREADYOUT;
  wire HRESP;
  wire [63:0] HRDATA;
  wire checker_error;
  wire [3:0] checker_error_code;
  wire [31:0] checker_error_count;
  wire address_fire;
  wire transfer_fire;
  wire transfer_protocol_error;
  wire [31:0] transfer_addr;
  wire transfer_write;
  wire [1:0] transfer_trans;
  wire [2:0] transfer_size;
  wire [63:0] transfer_data;
  wire transfer_error;
  wire [63:0] cycle_count;
  wire [31:0] address_count;
  wire [31:0] transfer_count;
  wire protocol_error;
  wire [31:0] protocol_error_count;

  integer response_errors = 0;
  integer seq_address_count = 0;
  reg request_ok;
  reg success;
  reg response_error;
  reg [63:0] read_data;
  reg [MAX_BURST_BEATS*64-1:0] burst_write_data;
  reg [MAX_BURST_BEATS*64-1:0] burst_read_data;
  reg [MAX_BURST_BEATS-1:0] burst_beat_error;
  integer burst_completed_beats;

  always #5 HCLK = ~HCLK;

  ahb_lite_caliptra_master #(
    .ADDR_WIDTH(32), .DATA_WIDTH(64), .MAX_WAIT_CYCLES(16),
    .MAX_BURST_BEATS(MAX_BURST_BEATS)
  ) master (
    .HCLK(HCLK), .HRESETn(HRESETn), .HREADY(HREADYOUT), .HRESP(HRESP),
    .HRDATA(HRDATA), .HSEL(HSEL), .HADDR(HADDR), .HWDATA(HWDATA),
    .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS), .busy(busy),
    .poisoned(poisoned)
  );

  ahb_lite_caliptra_memory_subordinate #(
    .ADDR_WIDTH(32), .DATA_WIDTH(64), .MEMORY_BYTES(256),
    .BASE_ADDR(32'h1000_0000)
  ) memory (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADYOUT), .wait_cycles(wait_cycles),
    .inject_error(inject_error), .HREADYOUT(HREADYOUT), .HRESP(HRESP),
    .HRDATA(HRDATA)
  );

  ahb_lite_caliptra_checker #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) checker_bfm (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADYOUT), .HRESP(HRESP), .error(checker_error),
    .error_code(checker_error_code), .error_count(checker_error_count)
  );

  ahb_lite_caliptra_monitor #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) monitor (
    .HCLK(HCLK), .HRESETn(HRESETn), .HADDR(HADDR), .HWDATA(HWDATA),
    .HSEL(HSEL), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
    .HREADY(HREADYOUT), .HRESP(HRESP), .HRDATA(HRDATA),
    .address_fire(address_fire), .transfer_fire(transfer_fire),
    .transfer_protocol_error(transfer_protocol_error),
    .transfer_addr(transfer_addr), .transfer_write(transfer_write),
    .transfer_trans(transfer_trans), .transfer_size(transfer_size),
    .transfer_data(transfer_data), .transfer_error(transfer_error),
    .cycle_count(cycle_count), .address_count(address_count),
    .transfer_count(transfer_count), .protocol_error(protocol_error),
    .protocol_error_count(protocol_error_count)
  );

  always @(posedge HCLK)
    if (HREADYOUT && HRESP) response_errors <= response_errors + 1;

  always @(posedge HCLK)
    if (HREADYOUT && HSEL && HTRANS == 2'b11)
      seq_address_count <= seq_address_count + 1;

  task automatic check_transfer_result(
    input reg check_data,
    input reg exp_success,
    input reg exp_error,
    input [63:0] exp_data
  );
    begin
      if (!request_ok || success !== exp_success || response_error !== exp_error)
        $fatal(1, "AHB result mismatch: request_ok=%b success=%b error=%b",
               request_ok, success, response_error);
      if (check_data && read_data !== exp_data)
        $fatal(1, "AHB read mismatch: got %h expected %h", read_data, exp_data);
      if (!busy && poisoned)
        $fatal(1, "AHB manager became poisoned after a completed transfer");
    end
  endtask

  initial begin
    repeat (2) @(posedge HCLK);
    @(negedge HCLK);
    HRESETn = 1;

    master.write_one(32'h1000_0000, 3'd3, 64'h0123_4567_89ab_cdef,
                     request_ok, success, response_error);
    check_transfer_result(1'b0, 1'b1, 1'b0, 64'd0);

    master.read_one(32'h1000_0000, 3'd3,
                    request_ok, success, response_error, read_data);
    check_transfer_result(1'b1, 1'b1, 1'b0, 64'h0123_4567_89ab_cdef);

    // A half-word write at byte lane two must preserve every other lane.
    master.write_one(32'h1000_0002, 3'd1, 64'h0000_0000_00cc_0000,
                     request_ok, success, response_error);
    check_transfer_result(1'b0, 1'b1, 1'b0, 64'd0);
    master.read_one(32'h1000_0000, 3'd3,
                    request_ok, success, response_error, read_data);
    check_transfer_result(1'b1, 1'b1, 1'b0, 64'h0123_4567_00cc_cdef);

    burst_write_data = '0;
    burst_write_data[0*64 +: 64] = 64'h0123_4567_89ab_cdef;
    burst_write_data[1*64 +: 64] = 64'h1122_3344_5566_7788;
    burst_write_data[2*64 +: 64] = 64'h99aa_bbcc_ddee_ff00;
    burst_write_data[3*64 +: 64] = 64'hfedc_ba98_7654_3210;
    master.write_burst(32'h1000_0020, 3'd3, 4, burst_write_data,
                       request_ok, success, response_error,
                       burst_completed_beats, burst_beat_error);
    if (!request_ok || !success || response_error ||
        burst_completed_beats != 4 || burst_beat_error[3:0] != 0)
      $fatal(1, "AHB write burst failed: ok=%b success=%b err=%b beats=%0d per=%h",
             request_ok, success, response_error, burst_completed_beats,
             burst_beat_error[3:0]);

    master.read_burst(32'h1000_0020, 3'd3, 4, request_ok, success,
                      response_error, burst_completed_beats,
                      burst_beat_error, burst_read_data);
    if (!request_ok || !success || response_error ||
        burst_completed_beats != 4 || burst_beat_error[3:0] != 0 ||
        burst_read_data[0*64 +: 64] !== burst_write_data[0*64 +: 64] ||
        burst_read_data[1*64 +: 64] !== burst_write_data[1*64 +: 64] ||
        burst_read_data[2*64 +: 64] !== burst_write_data[2*64 +: 64] ||
        burst_read_data[3*64 +: 64] !== burst_write_data[3*64 +: 64])
      $fatal(1, "AHB read burst data/status mismatch: ok=%b success=%b err=%b beats=%0d data=%h",
             request_ok, success, response_error, burst_completed_beats,
             burst_read_data[4*64-1:0]);

    // AHB-Lite ERROR occupies two cycles: first HREADY low, then completion.
    @(negedge HCLK);
    inject_error = 1;
    master.read_one(32'h1000_0000, 3'd3,
                    request_ok, success, response_error, read_data);
    check_transfer_result(1'b0, 1'b0, 1'b1, 64'd0);
    @(negedge HCLK);
    inject_error = 0;

    // Out-of-window accesses are rejected with the same legal ERROR response.
    master.read_one(32'h1000_0100, 3'd3,
                    request_ok, success, response_error, read_data);
    check_transfer_result(1'b0, 1'b0, 1'b1, 64'd0);

    repeat (2) @(posedge HCLK);
    if (checker_error || checker_error_count != 0 || protocol_error ||
        protocol_error_count != 0)
      $fatal(1, "AHB checker/monitor reported an error");
    if (address_count != 14 || transfer_count != 14 || response_errors != 2 ||
        seq_address_count != 6)
      $fatal(1, "Unexpected AHB accounting: addresses=%0d transfers=%0d seq=%0d errors=%0d",
             address_count, transfer_count, seq_address_count, response_errors);

    $display("PASS: AHB-Lite lanes, INCR bursts, waits, ERROR responses, checker, and monitor");
    $finish;
  end
endmodule
