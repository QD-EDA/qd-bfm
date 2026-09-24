// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_fixed_burst;
  logic clk=0, rst_n=0;
  always #5 clk=~clk;

  logic [31:0] araddr, awaddr, wdata, rdata, aruser, awuser, wuser;
  logic [7:0] arlen, awlen, arid, awid, rid, bid;
  logic [2:0] arsize, awsize;
  logic [1:0] arburst, awburst, rresp, bresp;
  logic arvalid, arready, rvalid, rready, rlast;
  logic awvalid, awready, wvalid, wready, wlast, bvalid, bready;
  logic [3:0] wstrb;
  logic [31:0] send_data[], send_user[], receive_data[], memory[0:255];
  logic [3:0] send_strb[];
  logic [1:0] receive_resp[];
  logic ok;
  logic [1:0] resp;
  integer count, beat=0, hold_cycles=2, aw_count=0, w_count=0, ar_count=0;
  integer aw_stalls=0, w_stalls=0, ar_stalls=0, b_stalls=0, r_stalls=0;
  bit bad_rid, bad_rlast, negative_case, error_response;
  localparam integer AW=0, W=1, B=2, AR=3, R=4;
  integer phase=AW;
  localparam logic [7:0] ID=8'h42;
  localparam logic [31:0] ADDR=32'h1000, AW_USER=32'h12345678,
                          AR_USER=32'h87654321;

  qd_axi4_single_master #(.TIMEOUT(12), .RESPONSE_DELAY(2)) bfm (.*);

  assign awready = rst_n && phase==AW && hold_cycles==0;
  assign wready  = rst_n && phase==W  && hold_cycles==0;
  assign arready = rst_n && phase==AR && hold_cycles==0;
  assign bvalid  = rst_n && phase==B;
  assign bid     = ID;
  assign bresp   = error_response ? 2'b10 : 2'b00;
  assign rvalid  = rst_n && phase==R;
  assign rid     = bad_rid ? ID+8'd1 : ID;
  assign rlast   = bad_rlast ? (beat != count-1) : (beat == count-1);
  assign rdata   = memory[beat];
  assign rresp   = error_response ? 2'b10 : 2'b00;

  // This target checks accepted pins; expected values come from the test,
  // never from the BFM's request payload.
  always @(posedge clk) if (rst_n) begin
    if (negative_case && (awvalid || arvalid))
      $fatal(1, "invalid burst reached request pins");
    if (awvalid && !awready) aw_stalls++;
    if (wvalid && !wready) w_stalls++;
    if (arvalid && !arready) ar_stalls++;
    if (bvalid && !bready) b_stalls++;
    if (rvalid && !rready) r_stalls++;
    case (phase)
      AW: if (hold_cycles != 0) hold_cycles <= hold_cycles-1;
          else if (awvalid) begin
            if ({awaddr,awlen,awsize,awburst,awid,awuser} !==
                {ADDR,8'(count-1),3'd2,2'b00,ID,AW_USER})
              $fatal(1, "AW target mismatch for %0d beats", count);
            aw_count++; beat<=0; phase<=W; hold_cycles<=2;
          end
      W:  if (hold_cycles != 0) hold_cycles <= hold_cycles-1;
          else if (wvalid) begin
            if ({wdata,wstrb,wlast,wuser} !==
                {send_data[beat],send_strb[beat],(beat==count-1),send_user[beat]})
              $fatal(1, "W target mismatch at beat %0d/%0d", beat, count);
            memory[beat]<=wdata;
            w_count++; beat<=beat+1;
            if (beat==count-1) phase<=B;
            else hold_cycles<=2;
          end
      B:  if (bready) begin phase<=AR; hold_cycles<=2; end
      AR: if (hold_cycles != 0) hold_cycles <= hold_cycles-1;
          else if (arvalid) begin
            if ({araddr,arlen,arsize,arburst,arid,aruser} !==
                {ADDR,8'(count-1),3'd2,2'b00,ID,AR_USER})
              $fatal(1, "AR target mismatch for %0d beats", count);
            ar_count++; beat<=0; phase<=R;
          end
      R:  if (rready) begin
            beat<=beat+1;
            if (beat==count-1) begin phase<=AW; hold_cycles<=2; end
          end
    endcase
  end

  task automatic exercise(input integer beats, input bit compat, input bit error_code);
    begin
      if (phase!=AW) $fatal(1, "target did not return to idle");
      count=beats; error_response=error_code;
      send_data=new[beats]; send_strb=new[beats]; send_user=new[beats];
      for (integer i=0; i<beats; i++) begin
        send_data[i]=32'hcafe0000 ^ 32'(i);
        send_strb[i]=(i==beats/2) ? 4'b0101 : 4'b1111;
        send_user[i]=32'ha5000000 | 32'(i);
      end
      bfm.write_fixed_user(ADDR,send_data,send_strb,ID,AW_USER,send_user,
                           compat,ok,resp);
      if (ok !== !error_code || resp !== (error_code ? 2'b10 : 2'b00))
        $fatal(1, "write result mismatch for %0d beats", beats);
      if (beats==16 && $test$plusargs("RESET_READ")) begin
        fork
          bfm.read_fixed_user(ADDR,beats,ID,AR_USER,compat,
                              ok,receive_data,receive_resp);
          begin
            wait(phase==R && beat==2);
            @(negedge clk); rst_n=0;
          end
        join
        if (ok !== 1'b0 || receive_data.size()!=0 ||
            receive_resp.size()!=0 || rready !== 1'b0)
          $fatal(1,"reset returned a successful or partial read burst");
        $display("PASS: reset cancels partial FIXED read without returning data");
        $finish;
      end
      bfm.read_fixed_user(ADDR,beats,ID,AR_USER,compat,
                          ok,receive_data,receive_resp);
      if (ok !== !error_code || receive_data.size()!=beats ||
          receive_resp.size()!=beats)
        $fatal(1, "read result/length mismatch for %0d beats", beats);
      for (integer i=0; i<beats; i++)
        if (receive_data[i] !== send_data[i] ||
            receive_resp[i] !== (error_code ? 2'b10 : 2'b00))
          $fatal(1, "read data/response mismatch at beat %0d/%0d", i, beats);
    end
  endtask

  initial begin
    integer bad_length;
    bad_rid=$test$plusargs("BAD_RID");
    bad_rlast=$test$plusargs("BAD_RLAST");
    repeat(3) @(negedge clk); rst_n=1;
    if ($value$plusargs("BAD_LENGTH=%d",bad_length)) begin
      count=bad_length; negative_case=1;
      send_data=new[bad_length]; send_strb=new[bad_length]; send_user=new[bad_length];
      bfm.write_fixed_user(ADDR,send_data,send_strb,ID,AW_USER,send_user,
                           bad_length==257,ok,resp);
      $display("BAD_LENGTH unexpectedly returned without rejecting %0d beats",bad_length);
      $finish;
    end
    if ($value$plusargs("BAD_READ_LENGTH=%d",bad_length)) begin
      count=bad_length; negative_case=1;
      bfm.read_fixed_user(ADDR,bad_length,ID,AR_USER,bad_length==257,
                          ok,receive_data,receive_resp);
      $display("BAD_READ_LENGTH unexpectedly returned without rejecting %0d beats",bad_length);
      $finish;
    end
    if ($test$plusargs("BAD_USER")) begin
      count=1; negative_case=1;
      send_data=new[1]; send_strb=new[1]; send_user=new[1];
      send_data[0]=32'h1234; send_strb[0]=4'hf; send_user[0]='x;
      bfm.write_fixed_user(ADDR,send_data,send_strb,ID,AW_USER,send_user,
                           0,ok,resp);
      $display("BAD_USER unexpectedly returned without rejecting WUSER");
      $finish;
    end
    exercise(1,0,0);
    if (bad_rid || bad_rlast) $fatal(1,"bad response unexpectedly accepted");
    exercise(16,0,0);
    exercise(256,1,0);
    exercise(3,0,1);
    if (aw_count!=4 || ar_count!=4 || w_count!=276 ||
        aw_stalls==0 || w_stalls==0 || ar_stalls==0 ||
        b_stalls==0 || r_stalls==0)
      $fatal(1,"burst or stall coverage mismatch");
    $display("PASS: FIXED bursts 1/16/256 and error response; USER, LAST, stalls");
    $finish;
  end
  initial begin #100000; $fatal(1,"fixed burst watchdog"); end
endmodule
