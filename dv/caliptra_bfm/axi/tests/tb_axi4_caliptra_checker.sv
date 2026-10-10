// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_checker;
  reg ACLK = 0;
  always #5 ACLK = ~ACLK;
  reg ARESETn = 0;

  reg [7:0] AWID = 0;
  reg [18:0] AWADDR = 0;
  reg [7:0] AWLEN = 0;
  reg [2:0] AWSIZE = 2;
  reg [1:0] AWBURST = 1;
  reg AWLOCK = 0;
  reg [31:0] AWUSER = 0;
  reg AWVALID = 0;
  reg AWREADY = 0;
  reg [31:0] WDATA = 0;
  reg [3:0] WSTRB = 4'hf;
  reg [31:0] WUSER = 0;
  reg WLAST = 0;
  reg WVALID = 0;
  reg WREADY = 0;
  reg [7:0] BID = 0;
  reg [1:0] BRESP = 0;
  reg [31:0] BUSER = 0;
  reg BVALID = 0;
  reg BREADY = 0;
  reg [7:0] ARID = 0;
  reg [18:0] ARADDR = 0;
  reg [7:0] ARLEN = 0;
  reg [2:0] ARSIZE = 2;
  reg [1:0] ARBURST = 1;
  reg ARLOCK = 0;
  reg [31:0] ARUSER = 0;
  reg ARVALID = 0;
  reg ARREADY = 0;
  reg [7:0] RID = 0;
  reg [31:0] RDATA = 0;
  reg [1:0] RRESP = 0;
  reg [31:0] RUSER = 0;
  reg RLAST = 0;
  reg RVALID = 0;
  reg RREADY = 0;
  reg [8*32-1:0] test_case = "GOOD";
  integer control_index;
  integer use_z;

  axi4_caliptra_checker #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8), .USER_WIDTH(32)) dut (.*);

  task automatic step;
    begin @(posedge ACLK); #1; end
  endtask

  task automatic set_unknown_control(input integer index, input integer inject_z);
    begin
      case (index)
        0: AWVALID = inject_z ? 1'bz : 1'bx;
        1: AWREADY = inject_z ? 1'bz : 1'bx;
        2: WVALID = inject_z ? 1'bz : 1'bx;
        3: WREADY = inject_z ? 1'bz : 1'bx;
        4: BVALID = inject_z ? 1'bz : 1'bx;
        5: BREADY = inject_z ? 1'bz : 1'bx;
        6: ARVALID = inject_z ? 1'bz : 1'bx;
        7: ARREADY = inject_z ? 1'bz : 1'bx;
        8: RVALID = inject_z ? 1'bz : 1'bx;
        9: RREADY = inject_z ? 1'bz : 1'bx;
        default: $fatal(1, "unknown VALID/READY control index %0d", index);
      endcase
    end
  endtask

  task automatic send_aw(input [7:0] id, input [18:0] addr, input [7:0] len);
    begin
      @(negedge ACLK);
      AWID = id; AWADDR = addr; AWLEN = len; AWVALID = 1; AWREADY = 1;
      step();
      @(negedge ACLK); AWVALID = 0; AWREADY = 0;
    end
  endtask

  task automatic send_w(input [31:0] data, input last);
    begin
      @(negedge ACLK);
      WDATA = data; WLAST = last; WVALID = 1; WREADY = 1;
      step();
      @(negedge ACLK); WVALID = 0; WLAST = 0; WREADY = 0;
    end
  endtask

  task automatic send_b(input [7:0] id);
    begin
      @(negedge ACLK);
      BID = id; BVALID = 1; BREADY = 1;
      step();
      @(negedge ACLK); BVALID = 0; BREADY = 0;
    end
  endtask

  task automatic send_ar(input [7:0] id, input [18:0] addr, input [7:0] len);
    begin
      @(negedge ACLK);
      ARID = id; ARADDR = addr; ARLEN = len; ARVALID = 1; ARREADY = 1;
      step();
      @(negedge ACLK); ARVALID = 0; ARREADY = 0;
    end
  endtask

  task automatic send_locked_aw(input [7:0] id, input [18:0] addr, input [7:0] len);
    begin
      @(negedge ACLK);
      AWID = id; AWADDR = addr; AWLEN = len; AWLOCK = 1; AWVALID = 1; AWREADY = 1;
      step();
      @(negedge ACLK); AWVALID = 0; AWREADY = 0; AWLOCK = 0;
    end
  endtask

  task automatic send_locked_ar(input [7:0] id, input [18:0] addr, input [7:0] len);
    begin
      @(negedge ACLK);
      ARID = id; ARADDR = addr; ARLEN = len; ARLOCK = 1; ARVALID = 1; ARREADY = 1;
      step();
      @(negedge ACLK); ARVALID = 0; ARREADY = 0; ARLOCK = 0;
    end
  endtask

  task automatic send_r(input [7:0] id, input last, input ready);
    begin
      @(negedge ACLK);
      RID = id; RDATA = 32'h1234_5678; RLAST = last; RVALID = 1; RREADY = ready;
      step();
      if (ready) begin
        @(negedge ACLK); RVALID = 0; RLAST = 0; RREADY = 0;
      end
    end
  endtask

  task automatic complete_locked_read(input [7:0] id);
    integer beat;
    begin
      RRESP = 2'b01;
      for (beat = 0; beat < 4; beat = beat + 1)
        send_r(id, beat == 3, 1);
    end
  endtask

  task automatic complete_locked_read_failed(input [7:0] id);
    integer beat;
    begin
      RRESP = 2'b00;
      for (beat = 0; beat < 4; beat = beat + 1)
        send_r(id, beat == 3, 1);
    end
  endtask

  initial begin
    if ($value$plusargs("CASE=%s", test_case)) begin end
    repeat (2) step();
    @(negedge ACLK); ARESETn = 1;

    if (test_case == "GOOD_NARROW_INCR") begin
      AWSIZE = 1;
      AWBURST = 2'b01;
      send_aw(8'h21, 19'h102, 1);
      WSTRB = 4'b1100;
      send_w(32'h1111, 0);
      WSTRB = 4'b0011;
      send_w(32'h2222, 1);
      send_b(8'h21);
    end else if (test_case == "GOOD_NARROW_FIXED") begin
      AWSIZE = 1;
      AWBURST = 2'b00;
      send_aw(8'h22, 19'h102, 1);
      WSTRB = 4'b1100;
      send_w(32'h3333, 0);
      send_w(32'h4444, 1);
      send_b(8'h22);
    end else if (test_case == "GOOD_NARROW_WRAP") begin
      AWSIZE = 1;
      AWBURST = 2'b10;
      send_aw(8'h23, 19'h102, 3);
      WSTRB = 4'b1100;
      send_w(32'h5555, 0);
      WSTRB = 4'b0011;
      send_w(32'h6666, 0);
      WSTRB = 4'b1100;
      send_w(32'h7777, 0);
      WSTRB = 4'b0011;
      send_w(32'h8888, 1);
      send_b(8'h23);
    end else if (test_case == "BAD_WSTRB") begin
      AWSIZE = 1;
      WSTRB = 4'b0100;
      send_aw(8'h24, 19'h100, 0);
      send_w(32'h9999, 1);
    end else if (test_case == "BAD_X_WSTRB") begin
      WSTRB = 4'bx001;
      send_w(32'haaaa, 1);
    end else if (test_case == "BAD_UNKNOWN_CONTROL") begin
      if (!$value$plusargs("CONTROL=%d", control_index) ||
          !$value$plusargs("USE_Z=%d", use_z))
        $fatal(1, "BAD_UNKNOWN_CONTROL requires CONTROL and USE_Z plusargs");
      @(negedge ACLK); set_unknown_control(control_index, use_z);
      step();
    end else if (test_case == "BAD_X_RESET") begin
      @(negedge ACLK); ARESETn = 1'bx;
      step();
    end else if (test_case == "BAD_X_WDATA") begin
      @(negedge ACLK); WDATA = 'x; WVALID = 1; WREADY = 1; WLAST = 1;
      step();
    end else if (test_case == "BAD_AW_STABILITY") begin
      AWVALID = 1; AWREADY = 0; AWADDR = 19'h100; AWUSER = 32'h1;
      step();
      @(negedge ACLK); AWADDR = 19'h104;
      step();
    end else if (test_case == "BAD_W_STABILITY") begin
      @(negedge ACLK); WVALID = 1; WREADY = 0; WDATA = 32'h1; WLAST = 1;
      step();
      @(negedge ACLK); WDATA = 32'h2;
      step();
    end else if (test_case == "BAD_B_STABILITY") begin
      @(negedge ACLK); BVALID = 1; BREADY = 0; BID = 8'h14; BRESP = 2'b00;
      step();
      @(negedge ACLK); BRESP = 2'b10;
      step();
    end else if (test_case == "BAD_AR_STABILITY") begin
      ARVALID = 1; ARREADY = 0; ARADDR = 19'h100; ARUSER = 32'h1;
      step();
      @(negedge ACLK); ARADDR = 19'h104;
      step();
    end else if (test_case == "BAD_R_STABILITY") begin
      send_ar(8'h2, 19'h100, 0);
      @(negedge ACLK); RID = 8'h2; RDATA = 32'h1; RLAST = 1; RVALID = 1; RREADY = 0;
      step();
      @(negedge ACLK); RDATA = 32'h2;
      step();
    end else if (test_case == "BAD_WLAST") begin
      send_aw(8'h3, 19'h100, 1);
      send_w(32'h1, 1);
    end else if (test_case == "BAD_NO_WLAST") begin
      send_aw(8'h3, 19'h100, 0);
      send_w(32'h1, 0);
    end else if (test_case == "BAD_RLAST") begin
      send_ar(8'h4, 19'h100, 1);
      send_r(8'h4, 1, 1);
    end else if (test_case == "BAD_4KB") begin
      send_aw(8'h5, 19'h00ffc, 1);
    end else if (test_case == "BAD_BID") begin
      send_aw(8'h6, 19'h100, 0);
      send_w(32'h1, 1);
      send_b(8'h7);
    end else if (test_case == "BAD_RID") begin
      send_ar(8'h8, 19'h100, 0);
      send_r(8'h9, 1, 1);
    end else if (test_case == "BAD_EXOKAY_B") begin
      send_aw(8'h8, 19'h100, 0);
      send_w(32'h1, 1);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h8);
    end else if (test_case == "BAD_EXOKAY_R") begin
      send_ar(8'h9, 19'h100, 0);
      @(negedge ACLK); RRESP = 2'b01;
      send_r(8'h9, 1, 1);
    end else if (test_case == "BAD_X_AWLOCK") begin
      @(negedge ACLK); AWLOCK = 1'bx;
      send_aw(8'h10, 19'h100, 0);
    end else if (test_case == "BAD_X_ARLOCK") begin
      @(negedge ACLK); ARLOCK = 1'bx;
      send_ar(8'h11, 19'h100, 0);
    end else if (test_case == "BAD_X_BRESP") begin
      send_aw(8'h12, 19'h100, 0);
      send_w(32'h1, 1);
      @(negedge ACLK); BRESP = 2'bx1;
      send_b(8'h12);
    end else if (test_case == "BAD_X_RRESP") begin
      send_ar(8'h13, 19'h100, 0);
      @(negedge ACLK); RRESP = 2'bx1;
      send_r(8'h13, 1, 1);
    end else if (test_case == "BAD_LOCK_MIXED_R") begin
      send_locked_ar(8'h10, 19'h110, 1);
      @(negedge ACLK); RRESP = 2'b01;
      send_r(8'h10, 0, 1);
      @(negedge ACLK); RRESP = 2'b00;
      send_r(8'h10, 1, 1);
    end else if (test_case == "BAD_MISSING_R") begin
      send_ar(8'h8, 19'h100, 0);
      dut.check_idle();
    end else if (test_case == "BAD_MISSING_W") begin
      send_aw(8'h8, 19'h100, 0);
      dut.check_idle();
    end else if (test_case == "BAD_EARLY_B") begin
      send_aw(8'h9, 19'h100, 0);
      send_b(8'h9);
    end else if (test_case == "BAD_WRITE_QUEUE_FULL") begin
      for (int request = 0; request < 17; request++)
        send_aw(8'ha, 19'h100 + (request * 4), 0);
    end else if (test_case == "BAD_READ_QUEUE_FULL") begin
      for (int request = 0; request < 17; request++)
        send_ar(8'hb, 19'h100 + (request * 4), 0);
    end else if (test_case == "BAD_LOCK_ALIGNMENT") begin
      send_locked_aw(8'hc, 19'h104, 1);
    end else if (test_case == "BAD_LOCK_TOO_LONG") begin
      send_locked_ar(8'hd, 19'h100, 16);
    end else if (test_case == "BAD_LOCK_NON_POWER2") begin
      send_locked_aw(8'he, 19'h100, 2);
    end else if (test_case == "BAD_LOCK_NO_READ") begin
      send_locked_aw(8'h30, 19'h110, 3);
    end else if (test_case == "BAD_LOCK_EARLY_WRITE") begin
      send_locked_ar(8'h30, 19'h110, 3);
      send_locked_aw(8'h30, 19'h110, 3);
    end else if (test_case == "BAD_LOCK_MISMATCH") begin
      send_locked_ar(8'h30, 19'h110, 3);
      complete_locked_read(8'h30);
      send_locked_aw(8'h30, 19'h120, 3);
    end else if (test_case == "BAD_LOCK_LEN_MISMATCH") begin
      send_locked_ar(8'h30, 19'h110, 3);
      complete_locked_read(8'h30);
      send_locked_aw(8'h30, 19'h110, 0);
    end else if (test_case == "BAD_LOCK_SIZE_MISMATCH") begin
      send_locked_ar(8'h30, 19'h110, 3);
      complete_locked_read(8'h30);
      AWSIZE = 1;
      send_locked_aw(8'h30, 19'h110, 3);
    end else if (test_case == "BAD_LOCK_BURST_MISMATCH") begin
      send_locked_ar(8'h30, 19'h110, 3);
      complete_locked_read(8'h30);
      AWBURST = 0;
      send_locked_aw(8'h30, 19'h110, 3);
    end else if (test_case == "GOOD_LOCK_INVALIDATED_OKAY") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read(8'h31);
      send_aw(8'h32, 19'h114, 0);
      send_w(32'h1, 1);
      send_b(8'h32);
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      send_b(8'h31);
    end else if (test_case == "GOOD_LOCK_NONOVERLAP_EXOKAY") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read(8'h31);
      send_aw(8'h32, 19'h120, 0);
      send_w(32'h1, 1);
      send_b(8'h32);
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h31);
    end else if (test_case == "GOOD_LOCK_ZERO_STROBE_EXOKAY") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read(8'h31);
      send_aw(8'h32, 19'h110, 0);
      WSTRB = 4'b0000;
      send_w(32'h1, 1);
      send_b(8'h32);
      WSTRB = 4'hf;
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h31);
    end else if (test_case == "BAD_LOCK_INVALIDATED_EXOKAY") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read(8'h31);
      send_aw(8'h32, 19'h114, 0);
      send_w(32'h1, 1);
      send_b(8'h32);
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h31);
    end else if (test_case == "GOOD_LOCK_ACTIVE_EXOKAY") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read(8'h31);
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      send_aw(8'h32, 19'h114, 0);
      send_w(32'h1, 1);
      send_b(8'h32);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h31);
    end else if (test_case == "GOOD_LOCK_READ_FAIL_OKAY") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read_failed(8'h31);
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      send_b(8'h31);
    end else if (test_case == "BAD_LOCK_READ_FAIL_EXOK") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read_failed(8'h31);
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h31);
    end else if (test_case == "BAD_LOCK_PARTIAL_OVERLAP_EXOKAY") begin
      ARSIZE = 0; AWSIZE = 0;
      send_locked_ar(8'h31, 19'h10f, 0);
      RRESP = 2'b01;
      send_r(8'h31, 1, 1);
      send_aw(8'h32, 19'h10f, 1);
      WSTRB = 4'b1000;
      send_w(32'h1, 0);
      send_locked_aw(8'h31, 19'h10f, 0);
      WSTRB = 4'b0001;
      send_w(32'h2, 1);
      send_b(8'h32);
      WSTRB = 4'b1000;
      send_w(32'h3, 1);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h31);
    end else if (test_case == "BAD_LOCK_W_BEFORE_AW_EXOKAY") begin
      ARSIZE = 0; AWSIZE = 0;
      send_locked_ar(8'h31, 19'h110, 0);
      RRESP = 2'b01;
      send_r(8'h31, 1, 1);
      WSTRB = 4'b0001;
      send_w(32'h1, 0);
      send_aw(8'h32, 19'h110, 1);
      send_locked_aw(8'h31, 19'h110, 0);
      WSTRB = 4'b0010;
      send_w(32'h2, 1);
      send_b(8'h32);
      WSTRB = 4'b0001;
      send_w(32'h3, 1);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h31);
    end else if (test_case == "GOOD_EXCLUSIVE") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read(8'h31);
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      @(negedge ACLK); BRESP = 2'b01;
      send_b(8'h31);
    end else if (test_case == "GOOD_SAME_ID_READS") begin
      send_ar(8'hb, 19'h100, 1);
      send_ar(8'hb, 19'h108, 0);
      send_r(8'hb, 0, 1);
      send_r(8'hb, 1, 1);
      send_r(8'hb, 1, 1);
    end else if (test_case == "GOOD_SAME_ID_WRITES") begin
      send_aw(8'hc, 19'h100, 0);
      send_aw(8'hc, 19'h104, 0);
      send_w(32'h1111, 1);
      send_w(32'h2222, 1);
      send_b(8'hc);
      send_b(8'hc);
    end else if (test_case == "GOOD_REORDER") begin
      // AXI4 permits W to precede its address and responses to complete out
      // of order across IDs. It still requires a single ordered W stream.
      send_w(32'h1001, 1);
      send_aw(8'h11, 19'h100, 0);
      send_aw(8'h22, 19'h104, 0);
      send_w(32'h2202, 1);
      send_b(8'h22);
      send_b(8'h11);

      send_ar(8'h33, 19'h200, 0);
      send_ar(8'h44, 19'h204, 0);
      send_r(8'h44, 1, 1);
      send_r(8'h33, 1, 1);
    end else begin
      // Exercise AW and W stability while the subordinate applies backpressure.
      @(negedge ACLK);
      AWID = 8'h11; AWADDR = 19'h100; AWLEN = 1; AWUSER = 32'hca11; AWVALID = 1; AWREADY = 0;
      step(); step();
      @(negedge ACLK); AWREADY = 1;
      step();
      @(negedge ACLK); AWVALID = 0; AWREADY = 0;

      @(negedge ACLK);
      WDATA = 32'h1111; WLAST = 0; WUSER = 32'hb1; WVALID = 1; WREADY = 0;
      step();
      @(negedge ACLK); WREADY = 1;
      step();
      @(negedge ACLK); WDATA = 32'h2222; WLAST = 1; WUSER = 32'hb2; WREADY = 0;
      step();
      @(negedge ACLK); WREADY = 1;
      step();
      @(negedge ACLK); WVALID = 0; WLAST = 0; WREADY = 0;
      send_b(8'h11);

      send_ar(8'h22, 19'h200, 1);
      send_r(8'h22, 0, 0); // R response payload must remain stable under stall.
      @(negedge ACLK); RREADY = 1;
      step();
      @(negedge ACLK); RVALID = 0; RREADY = 0; RLAST = 0;
      send_r(8'h22, 1, 1);
    end

    if (test_case != "GOOD" && test_case != "GOOD_REORDER" &&
        test_case != "GOOD_SAME_ID_READS" && test_case != "GOOD_SAME_ID_WRITES" &&
        test_case != "GOOD_EXCLUSIVE" &&
        test_case != "GOOD_LOCK_INVALIDATED_OKAY" &&
        test_case != "GOOD_LOCK_NONOVERLAP_EXOKAY" &&
        test_case != "GOOD_LOCK_ZERO_STROBE_EXOKAY" &&
        test_case != "GOOD_LOCK_ACTIVE_EXOKAY" &&
        test_case != "GOOD_LOCK_READ_FAIL_OKAY" &&
        test_case != "GOOD_NARROW_INCR" && test_case != "GOOD_NARROW_FIXED" &&
        test_case != "GOOD_NARROW_WRAP")
      $fatal(1, "Expected injected checker failure for %0s", test_case);
    dut.check_idle();
    $display("PASS: Caliptra AXI checker accepts valid traffic case=%0s", test_case);
    $finish;
  end
endmodule
