// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_memory_subordinate;
  localparam integer MAX_BEATS = 256;
  reg ACLK = 0;
  always #5 ACLK = ~ACLK;
  reg ARESETn = 0;
  reg memory_resetn = 0;
  reg stall_aw = 0, stall_w = 0, stall_b = 0, stall_ar = 0, stall_r = 0;
  reg inject_error = 0;

  wire [7:0] AWID; wire [18:0] AWADDR; wire [7:0] AWLEN;
  wire [2:0] AWSIZE; wire [1:0] AWBURST; wire AWLOCK;
  wire [31:0] AWUSER; wire AWVALID; wire AWREADY;
  wire [31:0] WDATA; wire [3:0] WSTRB; wire [31:0] WUSER;
  wire WLAST; wire WVALID; wire WREADY;
  wire [7:0] BID; wire [1:0] BRESP; wire [31:0] BUSER;
  wire BVALID; wire BREADY;
  wire [7:0] ARID; wire [18:0] ARADDR; wire [7:0] ARLEN;
  wire [2:0] ARSIZE; wire [1:0] ARBURST; wire ARLOCK;
  wire [31:0] ARUSER; wire ARVALID; wire ARREADY;
  wire [7:0] RID; wire [31:0] RDATA; wire [1:0] RRESP;
  wire [31:0] RUSER; wire RLAST; wire RVALID; wire RREADY;
  wire [7:0] write_response_id, read_response_id;

  axi4_caliptra_master #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8),
    .USER_WIDTH(32), .MAX_BEATS(MAX_BEATS),
    .TIMEOUT_CYCLES(2*MAX_BEATS + 64)) manager (.*);
  axi4_caliptra_memory_subordinate #(.ADDR_WIDTH(19), .DATA_WIDTH(32),
    .ID_WIDTH(8), .USER_WIDTH(32), .BASE_ADDR(19'h100), .MEM_BYTES(2048)) memory (
      .ARESETn(memory_resetn), .*
    );
  axi4_caliptra_checker #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8),
    .USER_WIDTH(32)) checker_inst (.*);

  wire aw_fire, w_fire, b_fire, ar_fire, r_fire;
  wire [72:0] aw_record, ar_record;
  wire [68:0] w_record;
  wire [41:0] b_record;
  wire [74:0] r_record;
  wire [63:0] cycle_count;
  wire [31:0] aw_count, w_count, b_count, ar_count, r_count;
  wire [31:0] aw_valid_cycles, aw_stall_cycles;
  wire [31:0] w_valid_cycles, w_stall_cycles;
  wire [31:0] b_valid_cycles, b_stall_cycles;
  wire [31:0] ar_valid_cycles, ar_stall_cycles;
  wire [31:0] r_valid_cycles, r_stall_cycles;
  wire [31:0] aw_burst_fixed_count, aw_burst_incr_count;
  wire [31:0] aw_burst_wrap_count, aw_burst_reserved_count;
  wire [31:0] aw_burst_unknown_count;
  wire [31:0] aw_lock_clear_count, aw_lock_set_count, aw_lock_unknown_count;
  wire [31:0] ar_burst_fixed_count, ar_burst_incr_count;
  wire [31:0] ar_burst_wrap_count, ar_burst_reserved_count;
  wire [31:0] ar_burst_unknown_count;
  wire [31:0] ar_lock_clear_count, ar_lock_set_count, ar_lock_unknown_count;
  wire [31:0] b_resp_okay_count, b_resp_exokay_count;
  wire [31:0] b_resp_slverr_count, b_resp_decerr_count, b_resp_unknown_count;
  wire [31:0] r_resp_okay_count, r_resp_exokay_count;
  wire [31:0] r_resp_slverr_count, r_resp_decerr_count, r_resp_unknown_count;
  wire [31:0] w_strb_full_count, w_strb_partial_count;
  wire [31:0] w_strb_zero_count, w_strb_unknown_count;
  wire [31:0] w_last_count, r_last_count;
  axi4_caliptra_monitor #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8),
    .USER_WIDTH(32)) monitor_inst (.*);

  reg success;
  reg [1:0] response;
  reg [31:0] response_user;
  reg [32*MAX_BEATS-1:0] write_data, write_user, read_data, read_user;
  reg [4*MAX_BEATS-1:0] write_strb;
  reg [2*MAX_BEATS-1:0] read_response;

  task automatic check(input condition, input [8*80-1:0] message);
    if (condition !== 1'b1) $fatal(1, "%0s", message);
  endtask

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); manager.reset_master(); ARESETn = 1; memory_resetn = 1;

    stall_aw = 1; stall_w = 1; stall_b = 1;
    write_data = {64'b0, 32'h2222_2222, 32'h1111_1111};
    write_strb = {8'b0, 4'hf, 4'hf};
    write_user = {64'b0, 32'hd000_0001, 32'hd000_0000};
    fork
      manager.write_burst(19'h100, 1, 2, 2'b01, 8'h51, 32'habcd_0051, 1'b0,
        write_data, write_strb, write_user, success, response, response_user);
      begin repeat (3) @(negedge ACLK); stall_aw = 0; end
      begin repeat (6) @(negedge ACLK); stall_w = 0; end
      begin repeat (12) @(negedge ACLK); stall_b = 0; end
    join
    check(success && response == 0 && response_user == 32'habcd_0051,
      "memory subordinate write response or USER failed");
    check(memory.word_at(0) == 32'h1111_1111 && memory.word_at(1) == 32'h2222_2222,
      "memory subordinate did not store the burst");
    check(aw_count == 1 && w_count == 2 && b_count == 1 &&
      aw_record[31:0] == 32'habcd_0051 && aw_record[32] == 1'b0 &&
      w_record[32:1] == 32'hd000_0001 && b_record[31:0] == 32'habcd_0051,
      "monitor did not publish AW/W/B handshake records");

    stall_ar = 1; stall_r = 1;
    fork
      manager.read_burst(19'h100, 1, 2, 2'b01, 8'h52, 32'habcd_0052, 1'b0,
        success, read_data, read_user, read_response, response_user);
      begin repeat (3) @(negedge ACLK); stall_ar = 0; end
      begin repeat (8) @(negedge ACLK); stall_r = 0; end
    join
    check(success && read_data[31:0] == 32'h1111_1111 &&
      read_data[63:32] == 32'h2222_2222, "memory subordinate read data failed");
    check(read_user[31:0] == 32'habcd_0052 && response_user == 32'habcd_0052,
      "memory subordinate did not propagate ARUSER to RUSER");

    inject_error = 1;
    manager.read_burst(19'h100, 0, 2, 2'b01, 8'h53, 32'h0, 1'b0,
      success, read_data, read_user, read_response, response_user);
    check(!success && read_response[1:0] == 2'b10,
      "memory subordinate did not return injected SLVERR");
    inject_error = 0;

    manager.read_burst(19'h900, 0, 2, 2'b01, 8'h54, 32'h0, 1'b0,
      success, read_data, read_user, read_response, response_user);
    check(!success && read_response[1:0] == 2'b11 && read_data[31:0] == 0,
      "unmapped read did not return zero data and DECERR");

    checker_inst.check_idle();
    repeat (2) @(posedge ACLK);
    check(ar_count == 3 && r_count == 4 && r_record[32:1] == 32'h0,
      "monitor did not publish AR/R records and response USER");

    manager.read_burst(19'h108, 0, 2, 2'b01, 8'h60, 32'h0, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(success && read_response[1:0] == 2'b01,
      "exclusive read did not establish a monitor and return EXOKAY");
    write_data = 0; write_data[31:0] = 32'h3333_4444;
    write_strb = 0; write_strb[3:0] = 4'hf;
    write_user = 0; write_user[31:0] = 32'hd000_0060;
    manager.write_burst(19'h108, 0, 2, 2'b01, 8'h60, 32'h0, 1'b1,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b01 && memory.word_at(2) == 32'h3333_4444,
      "matching exclusive write did not return EXOKAY and update memory");

    manager.read_burst(19'h108, 0, 2, 2'b01, 8'h60, 32'h0, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(success && read_response[1:0] == 2'b01,
      "second exclusive read did not establish a monitor");
    write_data[31:0] = 32'h5555_6666;
    write_user[31:0] = 32'hd000_0061;
    manager.write_burst(19'h108, 0, 2, 2'b01, 8'h61, 32'h0, 1'b0,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b00 && memory.word_at(2) == 32'h5555_6666,
      "intervening normal write did not update memory");
    write_data[31:0] = 32'h7777_8888;
    manager.write_burst(19'h108, 0, 2, 2'b01, 8'h60, 32'h0, 1'b1,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b00 && memory.word_at(2) == 32'h5555_6666,
      "failed exclusive write changed memory or returned the wrong response");

    manager.read_burst(19'h110, 1, 2, 2'b01, 8'h62, 32'h0, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(success && read_response[3:0] == 4'b0101,
      "multi-beat exclusive read did not return EXOKAY on every beat");
    write_data = 0; write_data[63:0] = {32'h9999_aaaa, 32'h8888_7777};
    write_strb = 0; write_strb[7:0] = 8'hff;
    manager.write_burst(19'h110, 1, 2, 2'b01, 8'h62, 32'h0, 1'b1,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b01 && memory.word_at(4) == 32'h8888_7777 &&
      memory.word_at(5) == 32'h9999_aaaa,
      "multi-beat exclusive write did not return EXOKAY and update memory");

    write_data = 0; write_data[31:0] = 32'h1122_3344;
    write_strb = 0; write_strb[3:0] = 4'hf;
    write_user = 0; write_user[31:0] = 32'hd000_0063;
    manager.write_burst(19'h118, 0, 2, 2'b01, 8'h63, 32'h0, 1'b0,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && memory.word_at(6) == 32'h1122_3344,
      "full-strobe write did not initialize the partial-strobe check word");
    write_data[31:0] = 32'haabb_ccdd;
    write_strb[3:0] = 4'b0011;
    manager.write_burst(19'h118, 0, 2, 2'b01, 8'h64, 32'h0, 1'b0,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && memory.word_at(6) == 32'h1122_ccdd,
      "partial-strobe write did not preserve inactive memory lanes");
    write_data[31:0] = 32'hffff_ffff;
    write_strb[3:0] = 4'b0000;
    manager.write_burst(19'h118, 0, 2, 2'b01, 8'h65, 32'h0, 1'b0,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && memory.word_at(6) == 32'h1122_ccdd,
      "zero-strobe write unexpectedly changed memory");

    write_data = 0;
    write_data[31:0] = 32'h6262_6262;
    write_data[63:32] = 32'h6363_6363;
    write_strb = 16'h00ff;
    manager.write_burst(19'h8f8, 1, 2, 2'b01, 8'h66, 32'h0, 1'b0,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b00 &&
      memory.word_at(510) == 32'h6262_6262 && memory.word_at(511) == 32'h6363_6363,
      "valid write at the final mapped words failed");

    write_data = {32'hdddd_dddd, 32'hcccc_cccc, 32'hbbbb_bbbb, 32'haaaa_aaaa};
    write_strb = 16'hffff;
    manager.write_burst(19'h8f8, 3, 2, 2'b01, 8'h67, 32'h0, 1'b0,
      write_data, write_strb, write_user, success, response, response_user);
    check(!success && response == 2'b11 &&
      memory.word_at(510) == 32'h6262_6262 && memory.word_at(511) == 32'h6363_6363,
      "boundary-crossing write was not rejected atomically");

    manager.read_burst(19'h8f8, 3, 2, 2'b01, 8'h68, 32'h0, 1'b0,
      success, read_data, read_user, read_response, response_user);
    check(!success && read_response == 8'hff && read_data == 0,
      "boundary-crossing read did not return zero data and DECERR on every beat");

    write_data = {32'hdddd_0003, 32'hcccc_0002, 32'hbbbb_0001, 32'haaaa_0000};
    write_strb = 16'hffff;
    manager.write_burst(19'h10c, 3, 2, 2'b10, 8'h69, 32'h0, 1'b0,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b00 &&
      memory.word_at(3) == 32'haaaa_0000 && memory.word_at(0) == 32'hbbbb_0001 &&
      memory.word_at(1) == 32'hcccc_0002 && memory.word_at(2) == 32'hdddd_0003,
      "WRAP write did not progress from the final word to the start of its region");
    manager.read_burst(19'h10c, 3, 2, 2'b10, 8'h6a, 32'h0, 1'b0,
      success, read_data, read_user, read_response, response_user);
    check(success && read_data[31:0] == 32'haaaa_0000 &&
      read_data[63:32] == 32'hbbbb_0001 && read_data[95:64] == 32'hcccc_0002 &&
      read_data[127:96] == 32'hdddd_0003,
      "WRAP read data did not follow the wrapped address order");

    write_data = 0;
    write_data[31:0] = 32'haaaa_bbbb;
    write_data[63:32] = 32'hcccc_dddd;
    write_strb = 16'h00ff;
    manager.write_burst(19'h120, 1, 2, 2'b00, 8'h6b, 32'h0, 1'b0,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b00 && memory.word_at(8) == 32'hcccc_dddd,
      "FIXED write did not retain the final beat at its repeated address");
    manager.read_burst(19'h120, 1, 2, 2'b00, 8'h6c, 32'h0, 1'b0,
      success, read_data, read_user, read_response, response_user);
    check(success && read_data[31:0] == 32'hcccc_dddd &&
      read_data[63:32] == 32'hcccc_dddd,
      "FIXED read did not repeat the same address for both beats");

    for (integer beat = 0; beat < MAX_BEATS; beat = beat + 1) begin
      write_data[32*beat +: 32] = 32'h5eed_0000 | beat;
      write_strb[4*beat +: 4] = 4'hf;
      write_user[32*beat +: 32] = 32'hd100_0000 | beat;
    end
    manager.write_burst(19'h200, 8'hff, 2, 2'b01, 8'ha1, 32'habcd_00a1,
      1'b0, write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b00 && response_user == 32'habcd_00a1,
      "256-beat INCR write did not complete with its B response");
    manager.read_burst(19'h200, 8'hff, 2, 2'b01, 8'ha2, 32'habcd_00a2,
      1'b0, success, read_data, read_user, read_response, response_user);
    check(success && response_user == 32'habcd_00a2,
      "256-beat INCR read did not complete with its ARUSER");
    for (integer beat = 0; beat < MAX_BEATS; beat = beat + 1) begin
      if (read_data[32*beat +: 32] !== (32'h5eed_0000 | beat) ||
          read_user[32*beat +: 32] !== 32'habcd_00a2 ||
          read_response[2*beat +: 2] !== 2'b00)
        $fatal(1, "256-beat INCR readback mismatch at beat %0d", beat);
    end

    check(aw_burst_fixed_count + aw_burst_incr_count + aw_burst_wrap_count +
      aw_burst_reserved_count + aw_burst_unknown_count == aw_count &&
      aw_burst_fixed_count == 1 && aw_burst_incr_count == aw_count - 2 &&
      aw_burst_wrap_count == 1 && aw_burst_reserved_count == 0 &&
      aw_burst_unknown_count == 0 &&
      aw_lock_clear_count + aw_lock_set_count + aw_lock_unknown_count == aw_count &&
      aw_lock_clear_count == 10 && aw_lock_set_count == 3 &&
      aw_lock_unknown_count == 0,
      "write address coverage did not account for burst and exclusive bins");
    check(ar_burst_fixed_count + ar_burst_incr_count + ar_burst_wrap_count +
      ar_burst_reserved_count + ar_burst_unknown_count == ar_count &&
      ar_burst_fixed_count == 1 && ar_burst_incr_count == ar_count - 2 &&
      ar_burst_wrap_count == 1 && ar_burst_reserved_count == 0 &&
      ar_burst_unknown_count == 0 &&
      ar_lock_clear_count + ar_lock_set_count + ar_lock_unknown_count == ar_count &&
      ar_lock_clear_count == 7 && ar_lock_set_count == 3 &&
      ar_lock_unknown_count == 0,
      "read address coverage did not account for burst and exclusive bins");
    check(b_resp_okay_count + b_resp_exokay_count + b_resp_slverr_count +
      b_resp_decerr_count + b_resp_unknown_count == b_count &&
      b_resp_okay_count == 10 && b_resp_exokay_count == 2 &&
      b_resp_slverr_count == 0 && b_resp_decerr_count == 1 &&
      b_resp_unknown_count == 0,
      "write response coverage did not match response denominator");
    check(r_resp_okay_count + r_resp_exokay_count + r_resp_slverr_count +
      r_resp_decerr_count + r_resp_unknown_count == r_count &&
      r_resp_okay_count == 264 && r_resp_exokay_count == 4 &&
      r_resp_slverr_count == 1 && r_resp_decerr_count == 5 &&
      r_resp_unknown_count == 0,
      "read response coverage did not match response-beat denominator");
    check(w_strb_full_count + w_strb_partial_count + w_strb_zero_count +
      w_strb_unknown_count == w_count && w_strb_full_count == 276 &&
      w_strb_partial_count == 1 && w_strb_zero_count == 1 &&
      w_strb_unknown_count == 0 && w_last_count == 13,
      "write strobe coverage did not match beat denominator");
    check(aw_count == 13 && w_count == 278 && b_count == 13 &&
      ar_count == 10 && r_count == 274 && r_last_count == 10 &&
      w_strb_full_count == 276,
      "AXI monitor denominators did not include boundary, WRAP, and FIXED traffic");
    check(aw_valid_cycles == aw_count + aw_stall_cycles,
      "AW VALID cycles do not equal accepted transfers plus stalls");
    check(w_valid_cycles == w_count + w_stall_cycles,
      "W VALID cycles do not equal accepted transfers plus stalls");
    check(b_valid_cycles == b_count + b_stall_cycles,
      "B VALID cycles do not equal accepted transfers plus stalls");
    check(ar_valid_cycles == ar_count + ar_stall_cycles,
      "AR VALID cycles do not equal accepted transfers plus stalls");
    check(r_valid_cycles == r_count + r_stall_cycles,
      "R VALID cycles do not equal accepted transfers plus stalls");
    check(aw_stall_cycles != 0 && w_stall_cycles != 0 &&
      ar_stall_cycles != 0,
      "the directed backpressure profile missed a channel stall bin");
    check(r_last_count == 10,
      "read LAST coverage did not match the ten completed read transactions");

    $display("COVERAGE AXI address AW=%0d FIXED/INCR/WRAP/reserved/unknown=%0d/%0d/%0d/%0d/%0d lock-clear/set/unknown=%0d/%0d/%0d AR=%0d FIXED/INCR/WRAP/reserved/unknown=%0d/%0d/%0d/%0d/%0d lock-clear/set/unknown=%0d/%0d/%0d",
      aw_count, aw_burst_fixed_count, aw_burst_incr_count, aw_burst_wrap_count,
      aw_burst_reserved_count, aw_burst_unknown_count, aw_lock_clear_count,
      aw_lock_set_count, aw_lock_unknown_count, ar_count, ar_burst_fixed_count,
      ar_burst_incr_count, ar_burst_wrap_count, ar_burst_reserved_count,
      ar_burst_unknown_count, ar_lock_clear_count, ar_lock_set_count,
      ar_lock_unknown_count);
    $display("COVERAGE AXI responses B=%0d OKAY/EXOKAY/SLVERR/DECERR/unknown=%0d/%0d/%0d/%0d/%0d R=%0d OKAY/EXOKAY/SLVERR/DECERR/unknown=%0d/%0d/%0d/%0d/%0d",
      b_count, b_resp_okay_count, b_resp_exokay_count, b_resp_slverr_count,
      b_resp_decerr_count, b_resp_unknown_count, r_count, r_resp_okay_count,
      r_resp_exokay_count, r_resp_slverr_count, r_resp_decerr_count,
      r_resp_unknown_count);
    $display("COVERAGE AXI W beats=%0d WSTRB full/partial/zero/unknown=%0d/%0d/%0d/%0d WLAST=%0d",
      w_count, w_strb_full_count, w_strb_partial_count, w_strb_zero_count,
      w_strb_unknown_count, w_last_count);
    $display("COVERAGE AXI VALID/stall cycles AW=%0d/%0d W=%0d/%0d B=%0d/%0d AR=%0d/%0d R=%0d/%0d",
      aw_valid_cycles, aw_stall_cycles, w_valid_cycles, w_stall_cycles,
      b_valid_cycles, b_stall_cycles, ar_valid_cycles, ar_stall_cycles,
      r_valid_cycles, r_stall_cycles);
    $display("COVERAGE AXI R beats=%0d RLAST=%0d", r_count, r_last_count);

    manager.read_burst(19'h108, 0, 2, 2'b01, 8'h6d, 32'h0, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(success && read_response[1:0] == 2'b01,
      "pre-reset exclusive read did not establish a reservation");
    @(negedge ACLK); memory_resetn = 0;
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); memory_resetn = 1;

    write_data = 0; write_data[31:0] = 32'hffff_ffff;
    write_strb = 16'h000f;
    manager.write_burst(19'h108, 0, 2, 2'b01, 8'h6d, 32'h0, 1'b1,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 2'b00 && memory.word_at(2) == 32'hdddd_0003,
      "reset did not clear the exclusive reservation while preserving SRAM");
    manager.read_burst(19'h108, 0, 2, 2'b01, 8'h6f, 32'h0, 1'b0,
      success, read_data, read_user, read_response, response_user);
    check(success && read_data[31:0] == 32'hdddd_0003,
      "post-reset AXI read did not return preserved SRAM data");
    checker_inst.check_idle();

    $display("PASS: AXI memory subordinate bursts through 256 beats, boundary DECERR, FIXED/WRAP, stalls, USER, errors, reset, and exclusive access");
    $finish;
  end
endmodule
