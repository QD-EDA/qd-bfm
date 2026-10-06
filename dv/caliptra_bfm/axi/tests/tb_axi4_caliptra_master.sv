// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_master #(parameter CHECKER_ENABLED = 1);
  reg ACLK = 0;
  always #5 ACLK = ~ACLK;
  reg ARESETn = 0;

  wire [7:0] AWID;
  wire [18:0] AWADDR;
  wire [7:0] AWLEN;
  wire [2:0] AWSIZE;
  wire [1:0] AWBURST;
  wire AWLOCK;
  wire [31:0] AWUSER;
  wire AWVALID;
  wire AWREADY;
  wire [31:0] WDATA;
  wire [3:0] WSTRB;
  wire [31:0] WUSER;
  wire WLAST;
  wire WVALID;
  wire WREADY;
  reg [7:0] BID;
  reg [1:0] BRESP;
  reg [31:0] BUSER;
  reg BVALID;
  wire BREADY;
  wire [7:0] ARID;
  wire [18:0] ARADDR;
  wire [7:0] ARLEN;
  wire [2:0] ARSIZE;
  wire [1:0] ARBURST;
  wire ARLOCK;
  wire [31:0] ARUSER;
  wire ARVALID;
  wire ARREADY;
  reg [7:0] RID;
  reg [31:0] RDATA;
  reg [1:0] RRESP;
  reg [31:0] RUSER;
  reg RLAST;
  reg RVALID;
  wire RREADY;
  wire [7:0] write_response_id;
  wire [7:0] read_response_id;

  axi4_caliptra_master #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8),
    .USER_WIDTH(32), .MAX_BEATS(16), .TIMEOUT_CYCLES(12)) bfm (.*);
  generate if (CHECKER_ENABLED) begin : g_checker
    axi4_caliptra_checker #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8), .USER_WIDTH(32)) checker_inst (.*);
  end endgenerate

  reg [31:0] mem [0:63];
  reg [1:0] cycle_mod = 0;
  reg [2:0] aw_delay = 2;
  reg [2:0] ar_delay = 2;
  reg write_pending = 0;
  reg read_pending = 0;
  reg [18:0] write_addr = 0;
  reg [18:0] read_addr = 0;
  reg [7:0] write_len = 0;
  reg [7:0] read_len = 0;
  reg [7:0] write_count = 0;
  reg [7:0] read_count = 0;
  reg [2:0] write_size = 2;
  reg [2:0] read_size = 2;
  reg [1:0] write_burst = 1;
  reg [1:0] read_burst = 1;
  reg [7:0] write_id = 0;
  reg [7:0] read_id = 0;
  reg inject_error = 0;
  reg inject_read_error = 0;
  reg inject_bad_bid = 0;
  reg inject_bad_rlast = 0;
  reg suppress_read = 0;
  integer aw_stalls = 0;
  integer w_stalls = 0;
  integer ar_stalls = 0;
  integer both_directions_active = 0;
  integer i, lane;
  reg [18:0] beat_addr;
  reg [1:0] next_resp;

  assign AWREADY = ARESETn && (aw_delay == 0);
  assign WREADY = ARESETn && write_pending && (cycle_mod[0] == 1'b1);
  assign ARREADY = ARESETn && (ar_delay == 0);

  always @(posedge ACLK)
    if (ARESETn && (AWVALID || WVALID || BREADY) && (ARVALID || RREADY))
      both_directions_active <= both_directions_active + 1;

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      cycle_mod <= 0;
      aw_delay <= 2;
      ar_delay <= 2;
      write_pending <= 0; read_pending <= 0;
      BVALID <= 0; BUSER <= 0; BID <= 0; BRESP <= 0;
      RVALID <= 0; RUSER <= 0; RID <= 0; RDATA <= 0; RRESP <= 0; RLAST <= 0;
      write_count <= 0; read_count <= 0;
    end else begin
      cycle_mod <= cycle_mod + 1'b1;
      if (AWVALID && !AWREADY && aw_delay != 0) aw_delay <= aw_delay - 1'b1;
      if (ARVALID && !ARREADY && ar_delay != 0) ar_delay <= ar_delay - 1'b1;
      if (AWVALID && !AWREADY) aw_stalls <= aw_stalls + 1;
      if (WVALID && !WREADY) w_stalls <= w_stalls + 1;
      if (ARVALID && !ARREADY) ar_stalls <= ar_stalls + 1;

      if (AWVALID && AWREADY) begin
        if (write_pending) $fatal(1, "test target received overlapping AW");
        write_pending <= 1;
        write_addr <= AWADDR;
        write_len <= AWLEN;
        write_size <= AWSIZE;
        write_burst <= AWBURST;
        write_id <= AWID;
        write_count <= 0;
        if (AWUSER !== 32'hca11_ab1e || AWLOCK !== 1'b1)
          $fatal(1, "master lost AWUSER or AWLOCK");
      end

      if (WVALID && WREADY) begin
        if (WLAST !== (write_count == write_len))
          $fatal(1, "master WLAST disagrees with AWLEN");
        if (write_burst == 2'b01)
          beat_addr = write_addr + (write_count << write_size);
        else beat_addr = write_addr;
        for (lane = 0; lane < 4; lane = lane + 1)
          if (WSTRB[lane]) mem[beat_addr[7:2]][8*lane +: 8] <= WDATA[8*lane +: 8];
        if (WUSER !== (32'hd000_0000 + write_count))
          $fatal(1, "master lost per-beat WUSER");
        if (WLAST) begin
          write_pending <= 0;
          BID <= inject_bad_bid ? write_id + 1'b1 : write_id;
          BRESP <= inject_error ? 2'b10 : 2'b00;
          BUSER <= 32'hb000_0001;
          BVALID <= 1;
        end else write_count <= write_count + 1'b1;
      end
      if (BVALID && BREADY) BVALID <= 0;

      if (ARVALID && ARREADY) begin
        if (read_pending) $fatal(1, "test target received overlapping AR");
        read_pending <= 1;
        read_addr <= ARADDR;
        read_len <= ARLEN;
        read_size <= ARSIZE;
        read_burst <= ARBURST;
        read_id <= ARID;
        read_count <= 0;
        if (ARUSER !== 32'hcafe_0001 || ARLOCK !== 1'b1)
          $fatal(1, "master lost ARUSER or ARLOCK");
        if (!suppress_read) begin
          RID <= ARID;
          beat_addr = ARADDR;
          RDATA <= mem[beat_addr[7:2]];
          RUSER <= 32'ha000_0000;
          RRESP <= inject_read_error ? 2'b10 : 2'b00;
          RLAST <= (ARLEN == 0) && !inject_bad_rlast;
          RVALID <= 1;
        end
      end else if (RVALID && RREADY && read_pending && !suppress_read) begin
        if (read_count == read_len) begin
          RVALID <= 0;
          read_pending <= 0;
        end else begin
          read_count <= read_count + 1'b1;
          if (read_burst == 2'b01)
            beat_addr = read_addr + ((read_count + 1'b1) << read_size);
          else beat_addr = read_addr;
          RDATA <= mem[beat_addr[7:2]];
          RUSER <= 32'ha000_0000 + read_count + 1'b1;
          RRESP <= inject_read_error ? 2'b10 : 2'b00;
          RLAST <= (read_count + 1'b1 == read_len) && !inject_bad_rlast;
        end
      end
    end
  end

  task automatic check(input condition, input [8*80-1:0] message);
    if (!condition) $fatal(1, "%0s", message);
  endtask

  reg success;
  reg [1:0] response;
  reg [31:0] response_user;
  reg [511:0] write_data;
  reg [63:0] write_strb;
  reg [511:0] write_user;
  reg [511:0] read_data;
  reg [511:0] read_user;
  reg [31:0] read_response;
  reg write_success_concurrent, read_success_concurrent;
  reg [1:0] write_response_concurrent;
  reg [31:0] write_user_concurrent, read_response_user_concurrent;
  reg [8*32-1:0] test_case = "GOOD";
  initial begin
    if ($value$plusargs("CASE=%s", test_case)) begin end
    for (i = 0; i < 64; i = i + 1) mem[i] = 0;
    mem[16] = 32'h0000_00ff;
    mem[17] = 32'h1234_5678;
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); bfm.reset_master(); ARESETn = 1;

    if (test_case == "CONCURRENT") begin
      mem[18] = 32'h8765_4321;
      write_data = {480'b0, 32'hdead_beef};
      write_strb = {60'b0, 4'hf};
      write_user = {480'b0, 32'hd000_0000};
      fork
        bfm.write_burst(19'h4c, 0, 2, 2'b01, 8'h35, 32'hca11_ab1e, 1'b1,
          write_data, write_strb, write_user, write_success_concurrent,
          write_response_concurrent, write_user_concurrent);
        bfm.read_burst(19'h48, 0, 2, 2'b01, 8'h46, 32'hcafe_0001, 1'b1,
          read_success_concurrent, read_data, read_user, read_response,
          read_response_user_concurrent);
      join
      check(write_success_concurrent && write_response_concurrent == 2'b00 &&
            write_user_concurrent == 32'hb000_0001,
        "concurrent write did not complete with its B response");
      check(read_success_concurrent && read_data[31:0] == 32'h8765_4321 &&
            read_response[1:0] == 2'b00 &&
            read_response_user_concurrent == 32'ha000_0000 &&
            read_response_id == 8'h46,
        "concurrent read did not complete with its R response");
      check(write_response_id == 8'h35,
        "concurrent write did not retain its B response ID");
      check(both_directions_active > 0,
        "AXI manager serialized the read and write task calls");
      if (CHECKER_ENABLED) g_checker.checker_inst.check_idle();
      $display("PASS: AXI manager overlaps independent read and write tasks");
      $finish;
    end else if (test_case == "BAD_BID") begin
      write_data = {480'b0, 32'hfeed_1234};
      write_strb = {60'b0, 4'hf};
      write_user = {480'b0, 32'hd000_0000};
      inject_bad_bid = 1;
      bfm.write_burst(19'h80, 0, 2, 2'b01, 8'h31, 32'hca11_ab1e, 1'b1,
        write_data, write_strb, write_user, success, response, response_user);
      check(!success && bfm.poisoned, "bad BID did not fail-stop the manager");
      check(write_response_id == BID,
        "manager did not retain the actual mismatched BID");
      bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h41, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(!success, "poisoned manager accepted another transaction");
      @(negedge ACLK); ARESETn = 0;
      repeat (2) @(posedge ACLK);
      @(negedge ACLK); bfm.reset_master(); inject_bad_bid = 0; ARESETn = 1;
      bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h42, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(success, "manager did not recover after reset following bad BID");
      $display("PASS: bad BID poisons manager until reset, then recovers");
      $finish;
    end else if (test_case == "BAD_RLAST") begin
      inject_bad_rlast = 1;
      bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h41, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(!success && bfm.poisoned, "bad RLAST did not fail-stop the manager");
      check(read_response_id == RID,
        "manager did not retain the actual RID");
      bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h42, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(!success, "poisoned manager accepted another transaction");
      @(negedge ACLK); ARESETn = 0;
      repeat (2) @(posedge ACLK);
      @(negedge ACLK); bfm.reset_master(); inject_bad_rlast = 0; ARESETn = 1;
      bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h43, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(success, "manager did not recover after reset following bad RLAST");
      $display("PASS: bad RLAST poisons manager until reset, then recovers");
      $finish;
    end

    write_data = {448'b0, 32'h2222_2222, 32'h1111_1111};
    write_strb = {56'b0, 4'hf, 4'h3};
    write_user = {448'b0, 32'hd000_0001, 32'hd000_0000};
    bfm.write_burst(19'h40, 1, 2, 2'b01, 8'h11, 32'hca11_ab1e, 1'b1,
      write_data, write_strb, write_user, success, response, response_user);
    check(success && response == 0 && response_user == 32'hb000_0001,
      "multi-beat write or BUSER failed");
    check(write_response_id == 8'h11, "BID capture failed");
    check(mem[16] == 32'h0000_1111 && mem[17] == 32'h2222_2222,
      "write data or byte strobes were wrong");
    check(aw_stalls > 0 && w_stalls > 0, "write backpressure was not exercised");

    bfm.read_burst(19'h40, 1, 2, 2'b01, 8'h22, 32'hcafe_0001, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(success && read_data[31:0] == 32'h0000_1111 &&
      read_data[63:32] == 32'h2222_2222, "multi-beat read data failed");
    check(read_user[31:0] == 32'ha000_0000 && read_user[63:32] == 32'ha000_0001 &&
      response_user == 32'ha000_0000, "RUSER capture failed");
    check(read_response_id == 8'h22, "RID capture failed");
    check(ar_stalls > 0, "read backpressure was not exercised");

    bfm.write_burst(19'h00ffc, 1, 2, 2'b01, 8'h23, 32'hca11_ab1e, 1'b1,
      write_data, write_strb, write_user, success, response, response_user);
    check(!success, "master accepted an INCR burst crossing 4KB");

    inject_read_error = 1;
    bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h24, 32'hcafe_0001, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(!success && read_response[1:0] == 2'b10,
      "read error response was not returned as a failed transaction");
    inject_read_error = 0;

    inject_error = 1;
    write_data = {480'b0, 32'hfeed_1234};
    write_strb = {60'b0, 4'hf};
    write_user = {480'b0, 32'hd000_0000};
    bfm.write_burst(19'h80, 0, 2, 2'b01, 8'h31, 32'hca11_ab1e, 1'b1,
      write_data, write_strb, write_user, success, response, response_user);
    check(!success && response == 2'b10, "SLVERR response was not returned as a failed transaction");
    inject_error = 0;

    suppress_read = 1;
    bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h41, 32'hcafe_0001, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(!success, "read timeout was not reported");
    bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h42, 32'hcafe_0001, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(!success, "timed-out manager accepted another transaction before reset");
    @(negedge ACLK); ARESETn = 0;
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); bfm.reset_master(); suppress_read = 0; ARESETn = 1;
    bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h43, 32'hcafe_0001, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(success && read_data[31:0] == 32'h0000_1111,
      "master did not recover after reset");
    if (CHECKER_ENABLED) g_checker.checker_inst.check_idle();

    $display("PASS: AXI manager bursts, USER/LOCK, stalls, errors, timeout and reset recovery");
    $finish;
  end
endmodule
