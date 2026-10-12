interface axi_if_min(input logic clk, input logic rst_n);
  logic valid;
  modport subordinate(input valid);
endinterface

module axi_subordinate(axi_if_min.subordinate axi_if);
  logic valid_q;
  assign valid_q = axi_if.valid;
endmodule

module force_release_child_variable;
  timeunit 1ns;
  timeprecision 1ps;

  logic clk = 1'b0;
  logic rst_n = 1'b1;
  logic source = 1'b1;
  logic rand_delays = 1'b1;
  axi_if_min axi_sram_if(clk, rst_n);
  axi_subordinate dut(.axi_if(axi_sram_if.subordinate));

  assign axi_sram_if.valid = source;
  always #5ns clk = ~clk;

  always @(negedge clk) begin
    if (rand_delays) force dut.valid_q = 1'b0;
    else release dut.valid_q;
  end

  initial begin
    #11ns;
    rand_delays = 1'b0;
    #10ns;
    if (axi_sram_if.valid !== 1'b1 || dut.valid_q !== 1'b1)
      $fatal(1, "release did not restore the continuously assigned paths");
    $display("PASS: hierarchical force/release does not back-drive interface input");
    $finish;
  end
endmodule
