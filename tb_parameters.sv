// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_parameters;
  parameter WIDTH=32;
  qd_axi4_single_master #(.DW(WIDTH)) bfm (.clk(1'b0),.rst_n(1'b0));
  initial begin
    #1;
    $display("PASS: supported width %0d",WIDTH);
    $finish;
  end
endmodule
