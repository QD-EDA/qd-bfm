// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_memory_queue;
  reg ACLK = 0;
  always #5 ACLK = ~ACLK;
  reg ARESETn = 0;
  reg stall_aw = 0, stall_w = 0, stall_b = 0, stall_ar = 0, stall_r = 0;
  reg inject_error = 0;

  reg [7:0] AWID = 0;
  reg [18:0] AWADDR = 0;
  reg [7:0] AWLEN = 0;
  reg [2:0] AWSIZE = 2;
  reg [1:0] AWBURST = 2'b01;
  reg AWLOCK = 0;
  reg [31:0] AWUSER = 0;
  reg AWVALID = 0;
  wire AWREADY;
  reg [31:0] WDATA = 0;
  reg [3:0] WSTRB = 4'hf;
  reg [31:0] WUSER = 0;
  reg WLAST = 1;
  reg WVALID = 0;
  wire WREADY;
  wire [7:0] BID;
  wire [1:0] BRESP;
  wire [31:0] BUSER;
  wire BVALID;
  reg BREADY = 0;

  reg [7:0] ARID = 0;
  reg [18:0] ARADDR = 0;
  reg [7:0] ARLEN = 0;
  reg [2:0] ARSIZE = 2;
  reg [1:0] ARBURST = 2'b01;
  reg ARLOCK = 0;
  reg [31:0] ARUSER = 0;
  reg ARVALID = 0;
  wire ARREADY;
  wire [7:0] RID;
  wire [31:0] RDATA;
  wire [1:0] RRESP;
  wire [31:0] RUSER;
  wire RLAST;
  wire RVALID;
  reg RREADY = 0;

  axi4_caliptra_memory_subordinate #(
    .ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8), .USER_WIDTH(32),
    .BASE_ADDR(19'h100), .MEM_BYTES(256), .MAX_OUTSTANDING(2)
  ) memory (.*);

  task automatic check(input condition, input [8*88-1:0] message);
    if (!condition) $fatal(1, "%0s", message);
  endtask

  task automatic send_aw(input [7:0] id, input [18:0] addr,
                         input [31:0] user_value);
    begin
      @(negedge ACLK);
      AWID = id;
      AWADDR = addr;
      AWUSER = user_value;
      AWVALID = 1;
      while (AWREADY !== 1'b1) @(negedge ACLK);
      @(posedge ACLK);
      @(negedge ACLK);
      AWVALID = 0;
    end
  endtask

  task automatic send_w(input [31:0] data_value);
    begin
      @(negedge ACLK);
      WDATA = data_value;
      WVALID = 1;
      while (WREADY !== 1'b1) @(negedge ACLK);
      @(posedge ACLK);
      @(negedge ACLK);
      WVALID = 0;
    end
  endtask

  task automatic send_ar(input [7:0] id, input [18:0] addr,
                         input [31:0] user_value);
    begin
      @(negedge ACLK);
      ARID = id;
      ARADDR = addr;
      ARUSER = user_value;
      ARVALID = 1;
      while (ARREADY !== 1'b1) @(negedge ACLK);
      @(posedge ACLK);
      @(negedge ACLK);
      ARVALID = 0;
    end
  endtask

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK);
    memory.ram[1][0] = 8'haa; memory.ram[1][1] = 8'h11;
    memory.ram[1][2] = 8'h11; memory.ram[1][3] = 8'h11;
    memory.ram[2][0] = 8'hbb; memory.ram[2][1] = 8'hbb;
    memory.ram[2][2] = 8'h22; memory.ram[2][3] = 8'h22;
    ARESETn = 1;

    // Fill both write slots, then verify that AW backpressures until B drains.
    send_aw(8'h11, 19'h104, 32'h1111_0001);
    send_aw(8'h22, 19'h108, 32'h2222_0002);
    @(negedge ACLK);
    AWID = 8'h33;
    AWADDR = 19'h10c;
    AWUSER = 32'h3333_0003;
    AWVALID = 1;
    repeat (2) begin
      @(posedge ACLK); #1;
      check(AWREADY === 1'b0, "write address queue accepted beyond its bound");
    end
    @(negedge ACLK); AWVALID = 0;

    send_w(32'haaaa_1111);
    send_w(32'hbbbb_2222);
    wait (BVALID === 1'b1);
    #1;
    check(BID == 8'h11 && BUSER == 32'h1111_0001 && BRESP == 2'b00,
      "first queued write response did not preserve ID/USER/order");
    repeat (2) begin
      @(posedge ACLK); #1;
      check(BVALID && BID == 8'h11 && BUSER == 32'h1111_0001,
        "stalled first B response changed while BREADY was low");
    end
    check(memory.word_at(1) == 32'haaaa_1111 && memory.word_at(2) == 32'hbbbb_2222,
      "queued write data was not applied in AW order");

    @(negedge ACLK); BREADY = 1;
    @(posedge ACLK); #1;
    check(!BVALID, "first B response did not handshake");
    @(posedge ACLK); #1;
    check(BVALID && BID == 8'h22 && BUSER == 32'h2222_0002 && BRESP == 2'b00,
      "second queued write response did not preserve ID/USER/order");
    @(posedge ACLK); #1;
    check(!BVALID, "second B response did not handshake");
    @(negedge ACLK); BREADY = 0;

    // Queue multiple reads behind R backpressure and check ordered release.
    stall_r = 1;
    send_ar(8'h31, 19'h104, 32'h3131_0001);
    send_ar(8'h42, 19'h108, 32'h4242_0002);
    @(negedge ACLK);
    ARID = 8'h53;
    ARADDR = 19'h10c;
    ARVALID = 1;
    repeat (2) begin
      @(posedge ACLK); #1;
      check(ARREADY === 1'b0, "read address queue accepted beyond its bound");
    end
    @(negedge ACLK); ARVALID = 0; stall_r = 0;

    wait (RVALID === 1'b1);
    #1;
    check(RID == 8'h31 && RDATA == 32'haaaa_1111 &&
          RUSER == 32'h3131_0001 && RLAST && RRESP == 2'b00,
      "first queued read response did not preserve ID/data/USER/order");
    repeat (2) begin
      @(posedge ACLK); #1;
      check(RVALID && RID == 8'h31 && RDATA == 32'haaaa_1111,
        "stalled first R response changed while RREADY was low");
    end

    @(negedge ACLK); RREADY = 1;
    @(posedge ACLK); #1;
    check(!RVALID && ARREADY, "first R response did not release read queue capacity");
    @(negedge ACLK); RREADY = 0;
    @(posedge ACLK); #1;
    check(RVALID && RID == 8'h42 && RDATA == 32'hbbbb_2222 &&
          RUSER == 32'h4242_0002 && RLAST && RRESP == 2'b00,
      "second queued read response did not preserve ID/data/USER/order");
    @(negedge ACLK); RREADY = 1;
    @(posedge ACLK); #1;
    check(!RVALID, "second R response did not handshake");

    $display("PASS: AXI memory subordinate bounded multi-ID read/write queues");
    $finish;
  end
endmodule
