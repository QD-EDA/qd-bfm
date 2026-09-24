// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_caliptra_axi_fixed_burst;
  logic clk=0, rst_n=0;
  always #5 clk=~clk;
  axi_if #(.AW(32),.DW(32),.IW(8),.UW(32)) wr(clk,rst_n), rd(clk,rst_n);
  qd_caliptra_axi_single_master #(.AW(32),.DW(32),.IW(8),.TIMEOUT(64),.RESPONSE_DELAY(3)) adapter(
    .clk(clk),.rst_n(rst_n),.wr(wr),.rd(rd));
  logic dv, write, last, hld=1;
  logic [31:0] addr, user, wdata, rdata, memory=0;
  logic [7:0] id;
  logic [3:0] wstrb;
  logic [2:0] size;
  logic rd_err=0, wr_err=0;
  axi_sub #(.AW(32),.DW(32),.IW(8),.UW(32),.EX_EN(0),.C_LAT(0)) dut(
    .clk(clk),.rst_n(rst_n),.s_axi_w_if(wr),.s_axi_r_if(rd),
    .dv(dv),.addr(addr),.write(write),.user(user),.id(id),.wdata(wdata),
    .wstrb(wstrb),.size(size),.rdata(rdata),.last(last),.hld(hld),
    .rd_err(rd_err),.wr_err(wr_err));
  assign rdata=memory ^ ($test$plusargs("BAD_DATA") ? 32'b1 : 32'b0);

  logic expected_write;
  logic [31:0] expected_awuser, expected_aruser;
  logic [7:0] expected_id;
  logic [31:0] payload[];
  logic [3:0] masks[];
  logic [31:0] users[];
  integer beats, component_beats, w_beats, held=0, hold_cycles=0;
  integer w_stalled=0, r_stalled=0, b_stalled=0;
  logic aw_held=0, w_held=0, ar_held=0, r_held=0, b_held=0;
  logic [85:0] old_aw, old_ar;
  logic [69:0] old_w;
  logic [75:0] old_r;
  logic [42:0] old_b;

  always @(negedge clk) begin
    if (!rst_n || !dv) begin hld=1; hold_cycles=0; end
    else if (hold_cycles<2) begin hld=1; hold_cycles++; end
    else hld=0;
  end
  always @(posedge clk) if (rst_n) begin
    if (aw_held && {wr.awaddr,wr.awlen,wr.awsize,wr.awburst,wr.awid,wr.awuser,wr.awvalid} !== old_aw)
      $fatal(1,"AW changed under backpressure");
    if (w_held && {wr.wdata,wr.wstrb,wr.wuser,wr.wlast,wr.wvalid} !== old_w)
      $fatal(1,"W changed under backpressure");
    if (ar_held && {rd.araddr,rd.arlen,rd.arsize,rd.arburst,rd.arid,rd.aruser,rd.arvalid} !== old_ar)
      $fatal(1,"AR changed under backpressure");
    if (r_held && {rd.rdata,rd.rresp,rd.rid,rd.rlast,rd.ruser,rd.rvalid} !== old_r)
      $fatal(1,"R changed under backpressure");
    if (b_held && {wr.bresp,wr.bid,wr.buser,wr.bvalid} !== old_b)
      $fatal(1,"B changed under backpressure");
    aw_held=wr.awvalid && !wr.awready;
    w_held=wr.wvalid && !wr.wready;
    ar_held=rd.arvalid && !rd.arready;
    r_held=rd.rvalid && !rd.rready;
    b_held=wr.bvalid && !wr.bready;
    old_aw={wr.awaddr,wr.awlen,wr.awsize,wr.awburst,wr.awid,wr.awuser,wr.awvalid};
    old_w={wr.wdata,wr.wstrb,wr.wuser,wr.wlast,wr.wvalid};
    old_ar={rd.araddr,rd.arlen,rd.arsize,rd.arburst,rd.arid,rd.aruser,rd.arvalid};
    old_r={rd.rdata,rd.rresp,rd.rid,rd.rlast,rd.ruser,rd.rvalid};
    old_b={wr.bresp,wr.bid,wr.buser,wr.bvalid};
    if (rd.rvalid && !rd.rready) r_stalled++;
    if (wr.bvalid && !wr.bready) b_stalled++;
    if (wr.wvalid && !wr.wready) w_stalled++;
    if (dv && hld) held++;
    if (dv && !hld) begin
      if (component_beats >= beats) $fatal(1,"extra component transfer");
      if ({addr,write,id,user,size,last} !==
          {32'h80,expected_write,expected_id,
           (expected_write ? expected_awuser : expected_aruser),3'd2,(component_beats==beats-1)})
        $fatal(1,"component address/control mismatch at beat %0d",component_beats);
      if (write) begin
        if ({wdata,wstrb} !== {payload[component_beats],masks[component_beats]})
          $fatal(1,"component write data/strobe mismatch at beat %0d",component_beats);
        for (integer b=0;b<4;b++) if (wstrb[b]) memory[b*8+:8] <= wdata[b*8+:8];
      end
      component_beats++;
    end
    if (wr.wvalid && wr.wready) begin
      if (w_beats >= beats) $fatal(1,"extra W transfer");
      if ({wr.wdata,wr.wstrb,wr.wuser,wr.wlast} !==
          {payload[w_beats],masks[w_beats],users[w_beats],(w_beats==beats-1)})
        $fatal(1,"W pin mismatch at beat %0d",w_beats);
      w_beats++;
    end
  end

  logic ok;
  logic [1:0] bresp;
  logic [31:0] read_data[];
  logic [1:0] read_resp[];
  task automatic pair(input integer count, input logic compat);
    logic [31:0] golden;
    logic [31:0] driven_awuser;
    begin
      beats=count; payload=new[count]; masks=new[count]; users=new[count];
      golden=memory;
      for (integer n=0;n<count;n++) begin
        payload[n]=32'h4a00_0000 ^ (32'(n)*32'h0101_0305);
        masks[n]=(n%5==0) ? 4'b0101 : 4'b1111;
        users[n]=32'hbd00_0000 | 32'(n);
        for (integer b=0;b<4;b++) if (masks[n][b]) golden[b*8+:8]=payload[n][b*8+:8];
      end
      expected_write=1; expected_awuser=32'ha5a5_0010 | 32'(count);
      expected_aruser=32'h5a5a_0020 | 32'(count);
      driven_awuser=expected_awuser;
      if ($test$plusargs("BAD_USER")) expected_awuser=~expected_awuser;
      expected_id=8'(count==16 ? 8'h16 : 8'h25);
      component_beats=0; w_beats=0;
      adapter.driver.write_fixed_user(32'h80,payload,masks,expected_id,
                                      driven_awuser,users,compat,ok,bresp);
      if (ok !== 1'b1 || bresp !== 2'b00 || component_beats != count || w_beats != count)
        $fatal(1,"write burst failed: count=%0d component=%0d W=%0d",count,component_beats,w_beats);
      if (memory !== golden) $fatal(1,"write memory mismatch");
      expected_write=0; component_beats=0;
      adapter.driver.read_fixed_user(32'h80,count,expected_id,expected_aruser,
                                     compat,ok,read_data,read_resp);
      if (ok !== 1'b1 || component_beats != count || $size(read_data) != count || $size(read_resp) != count)
        $fatal(1,"read burst failed: count=%0d component=%0d",count,component_beats);
      for (integer n=0;n<count;n++)
        if (read_resp[n] !== 2'b00 || read_data[n] !== golden)
          $fatal(1,"read response/data mismatch at beat %0d",n);
      $display("PASS: real Caliptra axi_sub FIXED %0d-beat pair compatibility=%0d",count,compat);
    end
  endtask
  initial begin
    repeat(3) @(negedge clk); rst_n=1;
    pair(16,0);
    pair(256,1);
    if (held < 8 || w_stalled==0 || r_stalled==0 || b_stalled==0)
      $fatal(1,"backpressure coverage missing held=%0d W=%0d R=%0d B=%0d",held,w_stalled,r_stalled,b_stalled);
    $display("COVERAGE: component beats=%0d held=%0d W stalls=%0d R stalls=%0d B stalls=%0d",2*(16+256),held,w_stalled,r_stalled,b_stalled);
    $finish;
  end
  initial begin #100000; $fatal(1,"burst watchdog expired"); end
endmodule
