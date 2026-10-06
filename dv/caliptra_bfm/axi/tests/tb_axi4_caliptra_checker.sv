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

  axi4_caliptra_checker #(.ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8), .USER_WIDTH(32)) dut (.*);

  task automatic step;
    begin @(posedge ACLK); #1; end
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
      for (beat = 0; beat < 4; beat = beat + 1)
        send_r(id, beat == 3, 1);
    end
  endtask

  initial begin
    if ($value$plusargs("CASE=%s", test_case)) begin end
    repeat (2) step();
    @(negedge ACLK); ARESETn = 1;

    if (test_case == "BAD_AW_STABILITY") begin
      AWVALID = 1; AWREADY = 0; AWADDR = 19'h100; AWUSER = 32'h1;
      step();
      @(negedge ACLK); AWADDR = 19'h104;
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
    end else if (test_case == "BAD_MISSING_R") begin
      send_ar(8'h8, 19'h100, 0);
      dut.check_idle();
    end else if (test_case == "BAD_EARLY_B") begin
      send_aw(8'h9, 19'h100, 0);
      send_b(8'h9);
    end else if (test_case == "BAD_DUP_BID") begin
      send_aw(8'ha, 19'h100, 0);
      send_aw(8'ha, 19'h104, 0);
    end else if (test_case == "BAD_DUP_RID") begin
      send_ar(8'hb, 19'h100, 0);
      send_ar(8'hb, 19'h104, 0);
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
    end else if (test_case == "GOOD_EXCLUSIVE") begin
      send_locked_ar(8'h31, 19'h110, 3);
      complete_locked_read(8'h31);
      send_locked_aw(8'h31, 19'h110, 3);
      send_w(32'h3210, 0);
      send_w(32'h3211, 0);
      send_w(32'h3212, 0);
      send_w(32'h3213, 1);
      send_b(8'h31);
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

    if (test_case != "GOOD" && test_case != "GOOD_REORDER" && test_case != "GOOD_EXCLUSIVE")
      $fatal(1, "Expected injected checker failure for %0s", test_case);
    dut.check_idle();
    $display("PASS: Caliptra AXI checker accepts valid traffic case=%0s", test_case);
    $finish;
  end
endmodule
