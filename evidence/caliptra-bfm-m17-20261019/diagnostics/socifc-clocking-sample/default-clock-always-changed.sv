module top;
  logic clk_tb = 0;
  logic signal = 0;
  always #5 clk_tb = ~clk_tb;
  default clocking default_clk @(posedge clk_tb); endclocking
  always @(posedge clk_tb) if ($changed(signal)) $display("changed at %0t", $time);
  initial begin #2 signal = 1; #10 $finish; end
endmodule
