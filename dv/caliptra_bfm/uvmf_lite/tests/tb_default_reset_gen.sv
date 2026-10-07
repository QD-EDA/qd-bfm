`timescale 1ns/1ps
module tb_default_reset_gen;
  reg clk = 0;
  wire reset;

  always #5 clk = ~clk;
  default_reset_gen dut(.CLK_IN(clk), .RESET(reset));

  initial begin
    #1;
    if (reset !== 1'b0) $fatal(1, "reset must start asserted");
    repeat (1) begin
      @(posedge clk); #1;
      if (reset !== 1'b0) $fatal(1, "reset released before two clocks");
    end
    @(posedge clk); #1;
    if (reset !== 1'b1) $fatal(1, "reset did not release on the second clock");
    repeat (2) @(posedge clk);
    #1;
    if (reset !== 1'b1) $fatal(1, "reset did not remain released");
    $display("PASS: default_reset_gen asserts at startup and releases after two clocks");
    $finish;
  end
endmodule
