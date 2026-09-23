// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_caliptra_axi_if;
  parameter DW=32, IW=8, IF_IW=IW;
  localparam AW=32, BYTES=DW/8;
  logic clk=0, rst_n=0;
  always #5 clk=~clk;
  axi_if #(.AW(AW),.DW(DW),.IW(IF_IW),.UW(32)) wr(clk,rst_n), rd(clk,rst_n);
  qd_caliptra_axi_single_master #(.AW(AW),.DW(DW),.IW(IW)) adapter(
    .clk(clk),.rst_n(rst_n),.wr(wr),.rd(rd));
  logic ok;
  logic [1:0] resp;
  logic [DW-1:0] data, memory=0;
  logic [BYTES-1:0] mask;
  integer writes=0, reads=0;

  // Independent pin-level target. It accepts on rising edges, drives on falling
  // edges, and checks each request against the directed sequence, not BFM state.
  initial begin
    wr.awready=0; wr.wready=0; wr.bvalid=0; wr.bresp=0; wr.bid=0; wr.buser='1;
    rd.arready=0; rd.rvalid=0; rd.rresp=0; rd.rid=0; rd.rlast=0; rd.rdata=0; rd.ruser='1;
    wait(rst_n);
    for (integer n=0;n<4;n++) begin
      wait(wr.awvalid);
      repeat(2) @(negedge clk);
      wr.awready=1;
      @(posedge clk);
      if ({wr.awaddr,wr.awlen,wr.awsize,wr.awburst,wr.awid} !==
          {32'h80,8'b0,3'($clog2(BYTES)),2'b0,IW'('1)}) $fatal(1,"write address mapping");
      if ({wr.awuser,wr.awlock,wr.wuser} !== '0) $fatal(1,"write sideband mapping");
      @(negedge clk); wr.awready=0;
      wait(wr.wvalid);
      repeat(2) @(negedge clk);
      wr.wready=1;
      @(posedge clk);
      if (wr.wdata !== DW'(64'hfedcba9876543210) || wr.wlast !== 1'b1 || wr.wstrb !== mask)
        $fatal(1,"write data mapping");
      for (integer b=0;b<BYTES;b++) if (wr.wstrb[b]) memory[b*8+:8]=wr.wdata[b*8+:8];
      writes++;
      @(negedge clk); wr.wready=0; wr.bvalid=1; wr.bid='1; wr.bresp=2'(n);
      do @(posedge clk); while (!wr.bready);
      @(negedge clk); wr.bvalid=0;
      wait(rd.arvalid);
      repeat(2) @(negedge clk);
      rd.arready=1;
      @(posedge clk);
      if ({rd.araddr,rd.arlen,rd.arsize,rd.arburst,rd.arid} !==
          {32'h80,8'b0,3'($clog2(BYTES)),2'b0,IW'(0)}) $fatal(1,"read address mapping");
      if ({rd.aruser,rd.arlock} !== '0) $fatal(1,"read sideband mapping");
      reads++;
      @(negedge clk); rd.arready=0; rd.rvalid=1; rd.rid=0; rd.rlast=1;
      rd.rdata=memory; rd.rresp=2'(n);
      if ($test$plusargs("BAD_RID")) rd.rid='1;
      do @(posedge clk); while (!rd.rready);
      @(negedge clk); rd.rvalid=0;
    end
  end
  initial begin
    repeat(2) @(negedge clk); rst_n=1;
    for (integer n=0;n<4;n++) begin
      case(n)
        0: mask='1;
        1: mask=BYTES'(1);
        2: mask='0;
        3: mask=BYTES'(1) << (BYTES-1);
      endcase
      adapter.driver.write_one(32'h80,DW'(64'hfedcba9876543210),mask,'1,ok,resp);
      if (ok !== (n==0) || resp !== 2'(n)) $fatal(1,"write response mapping");
      adapter.driver.read_one(32'h80,'0,ok,data,resp);
      if (ok !== (n==0) || resp !== 2'(n) || data !== DW'(64'hfedcba9876543210))
        $fatal(1,"read response mapping");
    end
    if (writes!=4 || reads!=4) $fatal(1,"missing handshakes");
    $display("PASS: Caliptra interface mapping DW=%0d IW=%0d",DW,IW);
    $finish;
  end
  initial begin #5000; $fatal(1,"interface watchdog expired"); end
endmodule
