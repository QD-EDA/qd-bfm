// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_memory_subordinate;
  reg ACLK = 0;
  always #5 ACLK = ~ACLK;
  reg ARESETn = 0;
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
    .USER_WIDTH(32), .MAX_BEATS(4), .TIMEOUT_CYCLES(64)) manager (.*);
  axi4_caliptra_memory_subordinate #(.ADDR_WIDTH(19), .DATA_WIDTH(32),
    .ID_WIDTH(8), .USER_WIDTH(32), .BASE_ADDR(19'h100), .MEM_BYTES(256)) memory (.*);
  axi4_caliptra_checker #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8),
    .USER_WIDTH(32)) checker_inst (.*);

  wire aw_fire, w_fire, b_fire, ar_fire, r_fire;
  wire [72:0] aw_record, ar_record;
  wire [68:0] w_record;
  wire [41:0] b_record;
  wire [74:0] r_record;
  wire [63:0] cycle_count;
  wire [31:0] aw_count, w_count, b_count, ar_count, r_count;
  axi4_caliptra_monitor #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8),
    .USER_WIDTH(32)) monitor_inst (.*);

  reg success;
  reg [1:0] response;
  reg [31:0] response_user;
  reg [127:0] write_data, write_user, read_data, read_user;
  reg [15:0] write_strb;
  reg [7:0] read_response;

  task automatic check(input condition, input [8*80-1:0] message);
    if (!condition) $fatal(1, "%0s", message);
  endtask

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); manager.reset_master(); ARESETn = 1;

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

    manager.read_burst(19'h300, 0, 2, 2'b01, 8'h54, 32'h0, 1'b0,
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

    $display("PASS: AXI memory subordinate bursts, stalls, USER, errors, and exclusive access");
    $finish;
  end
endmodule
