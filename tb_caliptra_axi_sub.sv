// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_caliptra_axi_sub;
  logic clk=0, rst_n=0;
  always #5 clk=~clk;
  axi_if #(.AW(32),.DW(32),.IW(8),.UW(32)) wr(clk,rst_n), rd(clk,rst_n);
  qd_caliptra_axi_single_master #(.AW(32),.DW(32),.IW(8),.TIMEOUT(32)) adapter(
    .clk(clk),.rst_n(rst_n),.wr(wr),.rd(rd));
  logic dv, write, last, hld=1;
  logic [31:0] addr, user, wdata, rdata, memory=0;
  logic [7:0] id;
  logic [3:0] wstrb;
  logic [2:0] size;
  logic rd_err, wr_err;
  axi_sub #(.AW(32),.DW(32),.IW(8),.UW(32),.EX_EN(0),.C_LAT(0)) dut(
    .clk(clk),.rst_n(rst_n),.s_axi_w_if(wr),.s_axi_r_if(rd),
    .dv(dv),.addr(addr),.write(write),.user(user),.id(id),.wdata(wdata),
    .wstrb(wstrb),.size(size),.rdata(rdata),.last(last),.hld(hld),
    .rd_err(rd_err),.wr_err(wr_err));

  // QD-owned component model, downstream of the real Caliptra AXI converter.
  // Error address deliberately has no side effects. Corruption is confined here.
  assign rd_err = addr == 32'h84;
  assign wr_err = addr == 32'h84;
  assign rdata = memory ^ ($test$plusargs("BAD_DATA") ? 32'b1 : 32'b0);
  integer hold_cycles=0, transfers=0, stalled=0;
  logic expected_write;
  logic [31:0] expected_addr, expected_data;
  logic [3:0] expected_strb;
  logic [7:0] expected_id;
  always @(negedge clk) begin
    if (!rst_n || !dv) begin hld=1; hold_cycles=0; end
    else if (hold_cycles<2) begin hld=1; hold_cycles++; end
    else hld=0;
  end
  always @(posedge clk) begin
    if (rst_n && dv && hld) stalled++;
    if (rst_n && dv && !hld) begin
      if ({addr,write,id,user,size,last} !==
          {expected_addr,expected_write,expected_id,32'b0,3'd2,1'b1})
        $fatal(1,"component address/control scoreboard mismatch");
      if (write) begin
        if ({wdata,wstrb} !== {expected_data,expected_strb})
          $fatal(1,"component write scoreboard mismatch");
        if (!wr_err)
          for (integer b=0;b<4;b++) if (wstrb[b]) memory[b*8+:8] <= wdata[b*8+:8];
      end
      transfers++;
    end
  end

  logic ok;
  logic [1:0] resp;
  logic [31:0] data, golden=0;
  task automatic transfer_pair(input logic [31:0] address, payload,
                               input logic [3:0] mask, input logic [7:0] tag,
                               input logic error_expected);
    integer before_count;
    begin
      before_count=transfers;
      expected_addr=address; expected_write=1; expected_data=payload;
      expected_strb=mask; expected_id=tag;
      adapter.driver.write_one(address,payload,mask,tag,ok,resp);
      if (ok !== !error_expected || resp !== (error_expected ? 2'b10 : 2'b00))
        $fatal(1,"write response scoreboard mismatch");
      if (!error_expected)
        for (integer b=0;b<4;b++) if (mask[b]) golden[b*8+:8]=payload[b*8+:8];
      if (transfers != before_count+1) $fatal(1,"write transfer count mismatch");
      expected_write=0;
      adapter.driver.read_one(address,tag,ok,data,resp);
      if (ok !== !error_expected || resp !== (error_expected ? 2'b10 : 2'b00))
        $fatal(1,"read response scoreboard mismatch");
      if (!error_expected && data !== golden) $fatal(1,"read data scoreboard mismatch");
      if (transfers != before_count+2) $fatal(1,"read transfer count mismatch");
    end
  endtask
  initial begin
    repeat(3) @(negedge clk); rst_n=1;
    transfer_pair(32'h80,32'h12345678,4'b1111,8'h00,0);
    transfer_pair(32'h80,32'hdeadbeef,4'b0001,8'hff,0);
    transfer_pair(32'h80,32'hffffffff,4'b0000,8'h80,0);
    transfer_pair(32'h80,32'habcdef01,4'b1000,8'h01,0);
    transfer_pair(32'h84,32'h99999999,4'b1111,8'hff,1);
    // Quiescent reset of both endpoints, then recovery with retained component RAM.
    @(negedge clk); rst_n=0;
    repeat(3) @(negedge clk); rst_n=1;
    transfer_pair(32'h80,32'hfedcba98,4'b0110,8'h00,0);
    if (transfers != 12 || stalled < 24) $fatal(1,"coverage count mismatch");
    $display("PASS: real Caliptra axi_sub transfers=%0d stalled=%0d",transfers,stalled);
    $finish;
  end
  initial begin #10000; $fatal(1,"subordinate watchdog expired"); end
endmodule
