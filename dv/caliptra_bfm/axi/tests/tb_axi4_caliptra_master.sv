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
    .USER_WIDTH(32), .MAX_BEATS(16), .TIMEOUT_CYCLES(64)) bfm (.*);
  generate if (CHECKER_ENABLED) begin : g_checker
    axi4_caliptra_checker #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8), .USER_WIDTH(32)) checker_inst (.*);
  end endgenerate

  reg [31:0] mem [0:63];
  reg [1:0] cycle_mod = 0;
  reg [2:0] aw_delay = 2;
  reg [2:0] ar_delay = 2;
  reg write_pending = 0;
  reg [8*32-1:0] test_case = "GOOD";
  reg w_before_aw_mode = 0;
  reg early_w_pending = 0;
  reg [31:0] early_wdata;
  reg [3:0] early_wstrb;
  reg [31:0] early_wuser;
  reg early_wlast;
  reg w_before_aw_seen = 0;
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
  reg suppress_write_response = 0;
  integer aw_stalls = 0;
  integer w_stalls = 0;
  integer ar_stalls = 0;
  integer both_directions_active = 0;
  integer i, lane;
  integer wrap_beats, beat_index;
  reg [18:0] wrap_start;
  reg [18:0] beat_addr;
  reg [1:0] next_resp;

  function automatic [18:0] address_for_beat(
    input [18:0] start_addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst,
    input [7:0] beat
  );
    reg [63:0] bytes_per_beat;
    reg [63:0] span;
    reg [63:0] wrap_base;
    begin
      bytes_per_beat = 64'd1 << size;
      case (burst)
        2'b00: address_for_beat = start_addr;
        2'b01: address_for_beat = (beat == 0) ? start_addr :
          ((start_addr / bytes_per_beat) + beat) * bytes_per_beat;
        2'b10: begin
          span = ({56'b0, len} + 1) * bytes_per_beat;
          wrap_base = (start_addr / span) * span;
          address_for_beat = wrap_base +
            ((start_addr - wrap_base + beat * bytes_per_beat) % span);
        end
        default: address_for_beat = start_addr;
      endcase
    end
  endfunction

  assign AWREADY = ARESETn && (aw_delay == 0);
  assign WREADY = ARESETn &&
    (w_before_aw_mode ? !early_w_pending : write_pending) &&
    (cycle_mod[0] == 1'b1);
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
      early_w_pending <= 0; w_before_aw_seen <= 0;
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
        write_addr <= AWADDR;
        write_len <= AWLEN;
        write_size <= AWSIZE;
        write_burst <= AWBURST;
        write_id <= AWID;
        write_count <= 0;
        if (AWUSER !== 32'hca11_ab1e || AWLOCK !== (test_case != "WRAP_NARROW"))
          $fatal(1, "master lost AWUSER or AWLOCK");
        if (w_before_aw_mode && early_w_pending) begin
          if (AWLEN !== 0 || !early_wlast)
            $fatal(1, "W-before-AW probe expected one final data beat");
          if (early_wuser !== 32'hd000_0000)
            $fatal(1, "master lost early WUSER");
          for (lane = 0; lane < 4; lane = lane + 1)
            if (early_wstrb[lane]) mem[AWADDR[7:2]][8*lane +: 8] <= early_wdata[8*lane +: 8];
          early_w_pending <= 0;
          write_pending <= 0;
          BID <= AWID;
          BRESP <= 2'b00;
          BUSER <= 32'hb000_0001;
          BVALID <= 1;
        end else write_pending <= 1;
      end

      if (WVALID && WREADY) begin
        if (AWVALID && !AWREADY) w_before_aw_seen <= 1;
        if (w_before_aw_mode && !write_pending) begin
          early_w_pending <= 1;
          early_wdata <= WDATA;
          early_wstrb <= WSTRB;
          early_wuser <= WUSER;
          early_wlast <= WLAST;
        end else begin
          if (WLAST !== (write_count == write_len))
            $fatal(1, "master WLAST disagrees with AWLEN");
          beat_addr = address_for_beat(write_addr, write_len, write_size,
                                        write_burst, write_count);
          for (lane = 0; lane < 4; lane = lane + 1)
            if (WSTRB[lane]) mem[beat_addr[7:2]][8*lane +: 8] <= WDATA[8*lane +: 8];
          if (WUSER !== (32'hd000_0000 + write_count))
            $fatal(1, "master lost per-beat WUSER");
          if (WLAST) begin
            write_pending <= 0;
            BID <= inject_bad_bid ? write_id + 1'b1 : write_id;
            BRESP <= inject_error ? 2'b10 : 2'b00;
            BUSER <= 32'hb000_0001;
            if (!suppress_write_response) BVALID <= 1;
          end else write_count <= write_count + 1'b1;
        end
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
        if (ARUSER !== 32'hcafe_0001 || ARLOCK !== (test_case != "WRAP_NARROW"))
          $fatal(1, "master lost ARUSER or ARLOCK");
        if (!suppress_read) begin
          RID <= ARID;
          beat_addr = address_for_beat(ARADDR, ARLEN, ARSIZE, ARBURST, 0);
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
          beat_addr = address_for_beat(read_addr, read_len, read_size,
                                        read_burst, read_count + 1'b1);
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
  reg abort_read_success, abort_write_success;
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
  initial begin
    if ($value$plusargs("CASE=%s", test_case)) begin end
    for (i = 0; i < 64; i = i + 1) mem[i] = 0;
    mem[16] = 32'h0000_00ff;
    mem[17] = 32'h1234_5678;
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); bfm.reset_master(); ARESETn = 1;

    if (test_case == "WRAP_NARROW") begin
      write_data = 0;
      write_strb = 0;
      write_user = 0;
      for (beat_index = 0; beat_index < 16; beat_index = beat_index + 1) begin
        write_data[beat_index*32 +: 32] = 32'h5100_0000 + beat_index;
        write_strb[beat_index*4 +: 4] = 4'hf;
        write_user[beat_index*32 +: 32] = 32'hd000_0000 + beat_index;
      end
      for (wrap_beats = 2; wrap_beats <= 16; wrap_beats = wrap_beats * 2) begin
        wrap_start = 19'h40 + wrap_beats*4 - 4;
        bfm.write_burst(wrap_start, wrap_beats-1, 2, 2'b10, 8'h30,
          32'hca11_ab1e, 1'b0, write_data, write_strb, write_user,
          success, response, response_user);
        check(success && response == 0 && write_response_id == 8'h30,
          "legal WRAP write failed");
        bfm.read_burst(wrap_start, wrap_beats-1, 2, 2'b10, 8'h31,
          32'hcafe_0001, 1'b0, success, read_data, read_user,
          read_response, response_user);
        check(success && read_response_id == 8'h31,
          "legal WRAP read failed");
        for (beat_index = 0; beat_index < wrap_beats; beat_index = beat_index + 1)
          check(read_data[beat_index*32 +: 32] === write_data[beat_index*32 +: 32] &&
                read_user[beat_index*32 +: 32] === 32'ha000_0000 + beat_index &&
                read_response[beat_index*2 +: 2] === 2'b00,
            "WRAP read did not return the wrapped address sequence");
      end

      mem[16] = 32'h0000_00ff;
      mem[17] = 32'h1234_5678;
      write_data = {480'b0, 32'h0000_c3d4, 32'ha1b2_0000};
      write_strb = {56'b0, 4'h3, 4'hc};
      write_user = {448'b0, 32'hd000_0001, 32'hd000_0000};
      bfm.write_burst(19'h42, 1, 1, 2'b01, 8'h32, 32'hca11_ab1e, 1'b0,
        write_data, write_strb, write_user, success, response, response_user);
      check(success && response == 0, "aligned narrow INCR write failed");
      bfm.read_burst(19'h42, 1, 1, 2'b01, 8'h33, 32'hcafe_0001, 1'b0,
        success, read_data, read_user, read_response, response_user);
      check(success && read_data[31:0] == 32'ha1b2_00ff &&
        read_data[63:32] == 32'h1234_c3d4,
        "narrow INCR transfer corrupted adjacent byte lanes");

      write_data = {480'b0, 32'h1122_3344, 32'haa00_0000};
      write_strb = {56'b0, 4'hf, 4'h8};
      write_user = {448'b0, 32'hd000_0001, 32'hd000_0000};
      bfm.write_burst(19'h43, 1, 2, 2'b01, 8'h36, 32'hca11_ab1e, 1'b0,
        write_data, write_strb, write_user, success, response, response_user);
      check(success && mem[16] == 32'haa_b2_00ff &&
        mem[17] == 32'h1122_3344,
        "unaligned INCR write did not use one partial first beat then an aligned beat");
      bfm.read_burst(19'h43, 1, 2, 2'b01, 8'h37, 32'hcafe_0001, 1'b0,
        success, read_data, read_user, read_response, response_user);
      check(success && read_data[31:0] == 32'haa_b2_00ff &&
        read_data[63:32] == 32'h1122_3344,
        "unaligned INCR read did not advance to the aligned second beat");

      write_data = {480'b0, 32'hbb00_0000, 32'haa00_0000};
      write_strb = {56'b0, 4'h8, 4'h8};
      write_user = {448'b0, 32'hd000_0001, 32'hd000_0000};
      bfm.write_burst(19'h47, 1, 2, 2'b00, 8'h38, 32'hca11_ab1e, 1'b0,
        write_data, write_strb, write_user, success, response, response_user);
      check(success && mem[17] == 32'hbb22_3344,
        "unaligned FIXED write did not retain its address and byte lane");
      bfm.read_burst(19'h47, 1, 2, 2'b00, 8'h39, 32'hcafe_0001, 1'b0,
        success, read_data, read_user, read_response, response_user);
      check(success && read_data[31:0] == 32'hbb22_3344 &&
        read_data[63:32] == 32'hbb22_3344,
        "unaligned FIXED read did not repeat the same address");

      bfm.write_burst(19'h40, 2, 2, 2'b10, 8'h34, 32'hca11_ab1e, 1'b0,
        write_data, write_strb, write_user, success, response, response_user);
      check(!success && !AWVALID && !WVALID && !bfm.write_busy,
        "manager accepted a three-beat WRAP burst");
      bfm.read_burst(19'h42, 3, 2, 2'b10, 8'h35, 32'hcafe_0001, 1'b0,
        success, read_data, read_user, read_response, response_user);
      check(!success && !ARVALID && !bfm.read_busy,
        "manager accepted a misaligned WRAP burst");
      if (CHECKER_ENABLED) g_checker.checker_inst.check_idle();
      $display("PASS: AXI manager WRAP, narrow and unaligned INCR, and invalid burst shapes");
      $finish;
    end else if (test_case == "W_BEFORE_AW") begin
      w_before_aw_mode = 1;
      write_data = {480'b0, 32'h0123_4567};
      write_strb = {60'b0, 4'hf};
      write_user = {480'b0, 32'hd000_0000};
      bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h2a, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(success, "exclusive read before W-before-AW write failed");
      bfm.write_burst(19'h40, 0, 2, 2'b01, 8'h2a, 32'hca11_ab1e, 1'b1,
        write_data, write_strb, write_user, success, response, response_user);
      check(success && response == 0 && response_user == 32'hb000_0001,
        "W-before-AW write did not complete successfully");
      check(w_before_aw_seen, "target did not accept W before AW");
      check(mem[16] == 32'h0123_4567, "W-before-AW payload was not written");
      if (CHECKER_ENABLED) g_checker.checker_inst.check_idle();
      $display("PASS: AXI manager completes a write when W is accepted before AW");
      $finish;
    end else if (test_case == "CONCURRENT") begin
      mem[18] = 32'h8765_4321;
      write_data = {480'b0, 32'hdead_beef};
      write_strb = {60'b0, 4'hf};
      write_user = {480'b0, 32'hd000_0000};
      bfm.read_burst(19'h4c, 0, 2, 2'b01, 8'h35, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(success, "exclusive read before concurrent write failed");
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
    end else if (test_case == "RESET_ABORT") begin
      suppress_read = 1;
      fork
        bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h51, 32'hcafe_0001, 1'b1,
          abort_read_success, read_data, read_user, read_response, response_user);
        begin
          wait(read_pending);
          @(posedge ACLK);
          @(negedge ACLK); ARESETn = 0;
          repeat (2) @(posedge ACLK);
          @(negedge ACLK); bfm.reset_master(); suppress_read = 0; ARESETn = 1;
        end
      join
      check(!abort_read_success && !bfm.read_busy && !ARVALID && !RREADY,
        "reset did not abort and clear an in-flight read");
      bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h52, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(success, "read manager did not recover after reset abort");

      ar_delay = 2;
      fork
        bfm.read_burst(19'h40, 0, 2, 2'b01, 8'h53, 32'hcafe_0001, 1'b1,
          abort_read_success, read_data, read_user, read_response, response_user);
        begin : reset_ar_stall
          integer cycles;
          cycles = 0;
          while (!(ARVALID && !ARREADY) && cycles < 8) begin
            @(posedge ACLK); #1; cycles = cycles + 1;
          end
          if (!(ARVALID && !ARREADY)) $fatal(1, "AR did not stall for reset test");
          ARESETn = 0;
          repeat (2) @(posedge ACLK);
          @(negedge ACLK); bfm.reset_master(); ARESETn = 1;
        end
      join
      check(!abort_read_success && !bfm.read_busy && !ARVALID && !RREADY,
        "reset did not abort and clear a stalled AR request");

      write_data = {480'b0, 32'h5678_1234};
      write_strb = {60'b0, 4'hf};
      write_user = {480'b0, 32'hd000_0000};

      aw_delay = 2;
      fork
        bfm.write_burst(19'h80, 0, 2, 2'b01, 8'h62, 32'hca11_ab1e, 1'b1,
          write_data, write_strb, write_user, abort_write_success, response, response_user);
        begin : reset_aw_stall
          integer cycles;
          cycles = 0;
          while (!(AWVALID && !AWREADY) && cycles < 8) begin
            @(posedge ACLK); #1; cycles = cycles + 1;
          end
          if (!(AWVALID && !AWREADY)) $fatal(1, "AW did not stall for reset test");
          ARESETn = 0;
          repeat (2) @(posedge ACLK);
          @(negedge ACLK); bfm.reset_master(); ARESETn = 1;
        end
      join
      check(!abort_write_success && !bfm.write_busy && !AWVALID && !WVALID && !BREADY,
        "reset did not abort and clear a stalled AW request");

      bfm.read_burst(19'hc0, 0, 2, 2'b01, 8'h63, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(success, "exclusive read before reset-aborted W-stall write failed");
      aw_delay = 0;
      fork
        bfm.write_burst(19'hc0, 0, 2, 2'b01, 8'h63, 32'hca11_ab1e, 1'b1,
          write_data, write_strb, write_user, abort_write_success, response, response_user);
        begin : reset_w_stall
          integer cycles;
          wait(AWVALID); #1; cycle_mod = 1;
          cycles = 0;
          while (!(write_pending && WVALID && !WREADY) && cycles < 8) begin
            @(posedge ACLK); #1; cycles = cycles + 1;
          end
          if (!(write_pending && WVALID && !WREADY))
            $fatal(1, "W did not stall after AW for reset test");
          @(posedge ACLK); #1; ARESETn = 0;
          repeat (2) @(posedge ACLK);
          @(negedge ACLK); bfm.reset_master(); ARESETn = 1;
        end
      join
      check(!abort_write_success && !bfm.write_busy && !AWVALID && !WVALID && !BREADY,
        "reset did not abort and clear a stalled W request");

      bfm.read_burst(19'h80, 0, 2, 2'b01, 8'h64, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(success, "exclusive read before reset-aborted response write failed");
      suppress_write_response = 1;
      fork
        bfm.write_burst(19'h80, 0, 2, 2'b01, 8'h64, 32'hca11_ab1e, 1'b1,
          write_data, write_strb, write_user, abort_write_success, response, response_user);
        begin
          wait(BREADY);
          @(posedge ACLK);
          @(negedge ACLK); ARESETn = 0;
          repeat (2) @(posedge ACLK);
          @(negedge ACLK); bfm.reset_master(); suppress_write_response = 0; ARESETn = 1;
        end
      join
      check(!abort_write_success && !bfm.write_busy && !AWVALID && !WVALID && !BREADY,
        "reset did not abort and clear an in-flight write");
      bfm.read_burst(19'h80, 0, 2, 2'b01, 8'h65, 32'hcafe_0001, 1'b1,
        success, read_data, read_user, read_response, response_user);
      check(success, "exclusive read before recovery write failed");
      bfm.write_burst(19'h80, 0, 2, 2'b01, 8'h65, 32'hca11_ab1e, 1'b1,
        write_data, write_strb, write_user, success, response, response_user);
      check(success, "write manager did not recover after reset abort");
      if (CHECKER_ENABLED) g_checker.checker_inst.check_idle();
      $display("PASS: AXI manager aborts in-flight reads and writes on reset, then recovers");
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
    bfm.read_burst(19'h40, 1, 2, 2'b01, 8'h11, 32'hcafe_0001, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(success, "exclusive read before manager write failed");
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

    bfm.read_burst(19'h80, 0, 2, 2'b01, 8'h31, 32'hcafe_0001, 1'b1,
      success, read_data, read_user, read_response, response_user);
    check(success, "exclusive read before SLVERR write failed");
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
