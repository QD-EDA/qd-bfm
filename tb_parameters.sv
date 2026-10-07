// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_parameters;
  parameter WIDTH=32;
`ifdef UNKNOWN_DELAY
  localparam integer DELAY='x;
`else
  localparam integer DELAY=0;
`endif
  qd_axi4_single_master #(.DW(WIDTH),.RESPONSE_DELAY(DELAY)) bfm (.clk(1'b0),.rst_n(1'b0));
  initial begin
    #1;
    $display("PASS: supported width %0d",WIDTH);
    $finish;
  end
endmodule
