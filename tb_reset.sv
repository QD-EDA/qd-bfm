// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_reset;
  logic clk=0, rst_n=0, clock_enabled=1;
  always #5 if (clock_enabled) clk=~clk;
  logic [31:0] araddr, awaddr, wdata, rdata;
  logic [7:0] arlen, awlen, arid, awid, rid, bid;
  logic [2:0] arsize, awsize;
  logic [1:0] arburst, awburst, rresp, bresp;
  logic arvalid, arready, rvalid, rready, rlast;
  logic awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic [3:0] wstrb;
  logic stall_aw=0, stall_w=0, stall_b=0, stall_ar=0, stall_r=0;
  logic aw_seen=0, w_seen=0, ar_seen=0;
  logic [31:0] memory=0;
  logic [7:0] write_id, read_id;
  logic ok, finished;
  logic [1:0] resp;
  logic [31:0] data;
  integer completed_cases=0;
  logic released_sampled=0;
  always @(posedge clk or negedge rst_n)
    if (rst_n !== 1'b1) released_sampled<=0;
    else released_sampled<=1;
  always @(posedge awvalid or posedge wvalid or posedge arvalid)
    if (rst_n === 1'b1 && !released_sampled)
      $fatal(1,"request before released-reset rising edge");

  qd_axi4_single_master #(.TIMEOUT(5)) bfm (.*);
  assign awready = rst_n && !stall_aw && !aw_seen;
  assign wready = rst_n && !stall_w && aw_seen && !w_seen;
  assign bvalid = rst_n && !stall_b && w_seen;
  assign bid = write_id;
  assign bresp = 0;
  assign arready = rst_n && !stall_ar && !ar_seen;
  assign rvalid = rst_n && !stall_r && ar_seen;
  assign rid = read_id;
  assign rresp = 0;
  assign rlast = 1;
  assign rdata = memory;

  // Independent target: response only after actual rising-edge handshakes.
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_seen<=0; w_seen<=0; ar_seen<=0;
      write_id<=0; read_id<=0;
    end else begin
      if (awvalid && awready) begin aw_seen<=1; write_id<=awid; end
      if (wvalid && wready) begin
        w_seen<=1;
        for (integer i=0; i<4; i=i+1)
          if (wstrb[i]) memory[i*8+:8] <= wdata[i*8+:8];
      end
      if (bvalid && bready) begin aw_seen<=0; w_seen<=0; end
      if (arvalid && arready) begin ar_seen<=1; read_id<=arid; end
      if (rvalid && rready) ar_seen<=0;
    end
  end

  task automatic quiet();
    if ({awvalid,wvalid,arvalid,bready,rready} !== 5'b0)
      $fatal(1, "reset did not clear manager outputs");
  endtask

  task automatic release_reset();
    @(posedge clk); rst_n <= 1;
    #1;
    if ($test$plusargs("BAD_EARLY_VALID")) force bfm.awvalid=1'b1;
    @(negedge clk);
  endtask

  task automatic recovery();
    stall_aw=0; stall_w=0; stall_b=0; stall_ar=0; stall_r=0;
    bfm.write_one(32'h10,32'hcafebabe,4'hf,8'h21,ok,resp);
    if (ok !== 1'b1 || memory !== 32'hcafebabe) $fatal(1,"write recovery failed");
    bfm.read_one(32'h10,8'h32,ok,data,resp);
    if (ok !== 1'b1 || data !== 32'hcafebabe) $fatal(1,"read recovery failed");
  endtask

  task automatic reset_case(input integer phase, input bit stop_clock);
    finished=0;
    stall_aw=(phase==0); stall_w=(phase==2); stall_b=(phase==3 || phase==13);
    stall_ar=(phase==4); stall_r=(phase==6 || phase==14);
    fork
      begin
        if ((phase>=4 && phase<=7) || phase==11 || phase==12 || phase==14) bfm.read_one(32'h10,8'h32,ok,data,resp);
        else bfm.write_one(32'h10,32'h12345678,4'hf,8'h21,ok,resp);
        finished=1;
      end
      begin
        case (phase)
          0: wait(awvalid);
          1: begin wait(awvalid); @(posedge clk); end
          2: wait(wvalid);
          3: wait(bready);
          4: wait(arvalid);
          5: begin wait(arvalid); @(posedge clk); end
          6: wait(rready);
          7: begin wait(rready); @(posedge clk); end
          8: begin wait(bready); @(posedge clk); end
          9,11: #1;
          10,12: @(posedge clk);
          13: begin wait(bready); repeat (5) @(posedge clk); end
          14: begin wait(rready); repeat (5) @(posedge clk); end
        endcase
        #1;
        if (stop_clock) clock_enabled=0;
        rst_n=0;
        if ($test$plusargs("BAD_RESET_VALID")) force bfm.awvalid=1'b1;
        #1;
        quiet();
        if (finished !== 1'b1 || ok !== 1'b0)
          $fatal(1,"task did not abort on reset: phase %0d",phase);
        #12; quiet(); // No clock is needed for cancellation or idle outputs.
        clock_enabled=1;
      end
    join
    release_reset();
    recovery();
    completed_cases=completed_cases+1;
  endtask

  initial begin
    #5000; $fatal(1,"reset regression watchdog expired");
  end
  initial begin
    #1; quiet();
    release_reset();
    recovery();
    for (integer phase=0; phase<15; phase=phase+1) begin
      reset_case(phase,0);
      reset_case(phase,1);
    end
    // A completed address timeout leaves VALID high until an external reset.
    stall_ar=1;
    bfm.read_one(32'h10,8'h32,ok,data,resp);
    if (ok !== 1'b0 || arvalid !== 1'b1) $fatal(1,"timeout contract changed");
    #1; rst_n=0; #1; quiet();
    release_reset(); recovery();
    if (completed_cases!=30) $fatal(1,"reset cases not all exercised");
    $display("PASS: 30 reset phases, stopped clocks, timeout reset and recovery");
    $finish;
  end
endmodule
