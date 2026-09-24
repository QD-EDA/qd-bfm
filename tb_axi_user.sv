// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi_user;
  logic clk=0, rst_n=0;
  always #5 clk=~clk;
  logic [31:0] araddr, awaddr, wdata, rdata, aruser, awuser, wuser;
  logic [7:0] arlen, awlen, arid, awid, rid, bid;
  logic [2:0] arsize, awsize;
  logic [1:0] arburst, awburst, rresp, bresp;
  logic arvalid, arready=0, rvalid=0, rready, rlast=1;
  logic awvalid, awready=0, wvalid, wready=0, wlast, bvalid=0, bready;
  logic [3:0] wstrb;
  logic [31:0] expected_aw, expected_w, expected_ar;
  logic bad_arg=0;
  integer aw_count=0, w_count=0, ar_count=0, aw_stalls=0, w_stalls=0, ar_stalls=0;
  logic ok;
  logic [1:0] resp;
  logic [31:0] data;
  qd_axi4_single_master #(.TIMEOUT(12)) bfm (.*);

  always @(posedge awvalid or posedge wvalid or posedge arvalid)
    if (bad_arg) $fatal(1, "invalid USER reached request pins");

  // Independently observe accepted channel data and hold READY low first.
  initial begin
    rdata=32'h12345678; rresp=0; rid=0; bresp=0; bid=0;
    wait(rst_n);
    forever begin
      wait(awvalid);
      repeat(2) @(negedge clk);
      awready=1;
      @(posedge clk);
      if (awuser !== expected_aw) $fatal(1,"AWUSER target mismatch");
      aw_count++;
      @(negedge clk); awready=0;
      wait(wvalid);
      repeat(2) @(negedge clk);
      wready=1;
      @(posedge clk);
      if (wuser !== expected_w) $fatal(1,"WUSER target mismatch");
      w_count++;
      @(negedge clk); wready=0; bid=awid; bvalid=1;
      do @(posedge clk); while (!bready);
      @(negedge clk); bvalid=0;
      wait(arvalid);
      repeat(2) @(negedge clk);
      arready=1;
      @(posedge clk);
      if (aruser !== expected_ar) $fatal(1,"ARUSER target mismatch");
      ar_count++;
      @(negedge clk); arready=0; rid=arid; rvalid=1;
      do @(posedge clk); while (!rready);
      @(negedge clk); rvalid=0;
    end
  end
  always @(posedge clk) if (rst_n) begin
    if (awvalid && !awready) aw_stalls++;
    if (wvalid && !wready) w_stalls++;
    if (arvalid && !arready) ar_stalls++;
  end

  task automatic pair(input logic [31:0] au, wu, ru);
    expected_aw=au; expected_w=wu; expected_ar=ru;
    bfm.write_one_user(32'h80,32'h12345678,4'hf,8'h42,au,wu,ok,resp);
    if (ok !== 1'b1 || resp !== 0) $fatal(1,"USER write failed");
    bfm.read_one_user(32'h80,8'h42,ru,ok,data,resp);
    if (ok !== 1'b1 || data !== 32'h12345678) $fatal(1,"USER read failed");
  endtask

  initial begin
    repeat(3) @(negedge clk); rst_n=1;
    if ($test$plusargs("BAD_AW_X")) begin bad_arg=1; bfm.write_one_user('h80,'h12,'hf,'h42,32'hx,0,ok,resp); end
    if ($test$plusargs("BAD_AW_Z")) begin bad_arg=1; bfm.write_one_user('h80,'h12,'hf,'h42,32'hz,0,ok,resp); end
    if ($test$plusargs("BAD_W_X")) begin bad_arg=1; bfm.write_one_user('h80,'h12,'hf,'h42,0,32'hx,ok,resp); end
    if ($test$plusargs("BAD_W_Z")) begin bad_arg=1; bfm.write_one_user('h80,'h12,'hf,'h42,0,32'hz,ok,resp); end
    if ($test$plusargs("BAD_AR_X")) begin bad_arg=1; bfm.read_one_user('h80,'h42,32'hx,ok,data,resp); end
    if ($test$plusargs("BAD_AR_Z")) begin bad_arg=1; bfm.read_one_user('h80,'h42,32'hz,ok,data,resp); end
    if ($test$plusargs("MUTATE_AW")) begin
      expected_aw=32'ha5a5a5a5; expected_w=0; expected_ar=0;
      fork
        bfm.write_one_user('h80,'h12,'hf,'h42,expected_aw,0,ok,resp);
        begin wait(awvalid); @(negedge clk); force awuser=32'h5a5a5a5a; end
      join
    end
    if ($test$plusargs("MUTATE_W")) begin
      expected_aw=0; expected_w=32'ha5a5a5a5; expected_ar=0;
      fork
        bfm.write_one_user('h80,'h12,'hf,'h42,0,expected_w,ok,resp);
        begin wait(wvalid); @(negedge clk); force wuser=32'h5a5a5a5a; end
      join
    end
    if ($test$plusargs("MUTATE_AR")) begin
      expected_aw=0; expected_w=0; expected_ar=32'ha5a5a5a5;
      fork
        bfm.read_one_user('h80,'h42,expected_ar,ok,data,resp);
        begin wait(arvalid); @(negedge clk); force aruser=32'h5a5a5a5a; end
      join
    end
    if ($test$plusargs("WRONG_USER")) begin
      expected_aw=32'hdeadbeef;
      bfm.write_one_user('h80,'h12,'hf,'h42,32'hcafebabe,0,ok,resp);
    end
    pair(0,0,0);
    pair(32'ha5a5a5a5,32'h5a5a5a5a,32'h80000000);
    pair('1,'1,'1);
    if ({aw_count,w_count,ar_count} !== {32'd3,32'd3,32'd3} ||
        aw_stalls<3 || w_stalls<3 || ar_stalls<3)
      $fatal(1,"USER transfer/stall coverage mismatch");
    $display("PASS: USER 0/nonzero/all-ones on AW/W/AR with stalls");
    $finish;
  end
  initial begin #5000; $fatal(1,"USER watchdog"); end
endmodule
