// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_ahb_lite_caliptra;
  localparam integer MAX_BURST_BEATS = 16;
  reg HCLK = 0;
  reg HRESETn = 0;
  reg target_resetn = 0;
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
  wire [31:0] read_address_count;
  wire [31:0] write_address_count;
  wire [31:0] size_1byte_count;
  wire [31:0] size_2byte_count;
  wire [31:0] size_4byte_count;
  wire [31:0] size_8byte_count;
  wire [31:0] pending_wait_cycle_count;
  wire [31:0] error_transfer_count;

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
    .HCLK(HCLK), .HRESETn(target_resetn), .HADDR(HADDR), .HWDATA(HWDATA),
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
    .protocol_error_count(protocol_error_count),
    .read_address_count(read_address_count),
    .write_address_count(write_address_count),
    .size_1byte_count(size_1byte_count), .size_2byte_count(size_2byte_count),
    .size_4byte_count(size_4byte_count), .size_8byte_count(size_8byte_count),
    .pending_wait_cycle_count(pending_wait_cycle_count),
    .error_transfer_count(error_transfer_count)
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
    target_resetn = 1;

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

    @(negedge HCLK); target_resetn = 0;
    repeat (2) @(posedge HCLK);
    @(negedge HCLK); target_resetn = 1;
    master.read_one(32'h1000_0000, 3'd3,
                    request_ok, success, response_error, read_data);
    check_transfer_result(1'b1, 1'b1, 1'b0, 64'h0123_4567_00cc_cdef);

    repeat (2) @(posedge HCLK);
    if (checker_error || checker_error_count != 0 || protocol_error ||
        protocol_error_count != 0)
      $fatal(1, "AHB checker/monitor reported an error");
    if (address_count != 15 || transfer_count != 15 || response_errors != 2 ||
        seq_address_count != 6)
      $fatal(1, "Unexpected AHB accounting: addresses=%0d transfers=%0d seq=%0d errors=%0d",
             address_count, transfer_count, seq_address_count, response_errors);
    if (read_address_count != 9 || write_address_count != 6 ||
        size_1byte_count != 0 || size_2byte_count != 1 ||
        size_4byte_count != 0 || size_8byte_count != 14 ||
        pending_wait_cycle_count == 0 || error_transfer_count != 2)
      $fatal(1, "Unexpected AHB coverage counts: reads=%0d writes=%0d sizes={%0d,%0d,%0d,%0d} waits=%0d errors=%0d",
             read_address_count, write_address_count,
             size_1byte_count, size_2byte_count, size_4byte_count,
             size_8byte_count, pending_wait_cycle_count, error_transfer_count);

    $display("PASS: AHB-Lite lanes, INCR bursts, waits, ERROR responses, reset retention, checker, monitor coverage counts");
    $finish;
  end
endmodule

module tb_ahb_lite_caliptra_reset_abort;
  reg HCLK = 0;
  reg HRESETn = 0;
  reg HREADY = 0;
  reg HRESP = 0;
  reg [63:0] HRDATA = 64'h1234_5678_9abc_def0;
  wire HSEL;
  wire [31:0] HADDR;
  wire [63:0] HWDATA;
  wire HWRITE;
  wire [2:0] HSIZE;
  wire [1:0] HTRANS;
  wire busy;
  wire poisoned;
  reg request_ok;
  reg success;
  reg response_error;
  reg [63:0] read_data;
  reg [255:0] burst_data;
  reg [3:0] burst_error;
  integer burst_completed;

  always #5 HCLK = ~HCLK;

  ahb_lite_caliptra_master #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) master (
    .HCLK(HCLK), .HRESETn(HRESETn), .HREADY(HREADY), .HRESP(HRESP),
    .HRDATA(HRDATA), .HSEL(HSEL), .HADDR(HADDR), .HWDATA(HWDATA),
    .HWRITE(HWRITE), .HSIZE(HSIZE), .HTRANS(HTRANS), .busy(busy),
    .poisoned(poisoned)
  );

  initial begin
    #2000;
    $fatal(1, "AHB reset-abort regression timed out");
  end

  task automatic check_aborted;
    begin
      #1; // Let reset-gated HSEL settle before checking the combinational output.
      if (!request_ok || success || response_error || busy || !poisoned ||
          HTRANS !== 2'b00 || HSEL || HADDR !== 0 || HWDATA !== 0)
        $fatal(1, "AHB reset abort left an invalid result or bus state");
    end
  endtask

  task automatic recover_and_read;
    begin
      master.reset_master();
      if (poisoned || busy || HTRANS !== 2'b00)
        $fatal(1, "AHB manager did not clear after reset_master");
      HREADY = 1;
      repeat (2) @(posedge HCLK);
      @(negedge HCLK); HRESETn = 1;
      master.read_one(32'h1000_0000, 3'd3, request_ok, success,
                      response_error, read_data);
      if (!request_ok || !success || response_error || poisoned ||
          read_data !== HRDATA)
        $fatal(1, "AHB manager did not recover after reset abort");
    end
  endtask

  initial begin
    repeat (2) @(posedge HCLK);
    @(negedge HCLK); HRESETn = 1;
    fork
      master.read_one(32'h1000_0000, 3'd3, request_ok, success,
                      response_error, read_data);
      begin
        wait (HSEL === 1'b1);
        @(posedge HCLK);
        @(negedge HCLK); HRESETn = 0;
      end
    join
    check_aborted();
    recover_and_read();

    fork
      master.read_one(32'h1000_0000, 3'd3, request_ok, success,
                      response_error, read_data);
      begin
        wait (HSEL === 1'b1);
        @(posedge HCLK);
        @(negedge HCLK); HREADY = 0;
        @(posedge HCLK);
        @(negedge HCLK); HRESETn = 0;
      end
    join
    check_aborted();
    recover_and_read();

    fork
      master.read_burst(32'h1000_0000, 3'd3, 4, request_ok, success,
                        response_error, burst_completed, burst_error,
                        burst_data);
      begin
        wait (HSEL === 1'b1);
        wait (HTRANS === 2'b11);
        HREADY = 0;
        @(posedge HCLK);
        @(negedge HCLK); HRESETn = 0;
      end
    join
    check_aborted();
    if (burst_completed != 0 || burst_data !== 0 || burst_error !== 0)
      $fatal(1, "AHB burst reset abort retained a partial result");
    recover_and_read();

    $display("PASS: AHB manager aborts single/burst waits and recovers cleanly");
    $finish;
  end
endmodule
