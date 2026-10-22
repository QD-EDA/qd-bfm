interface m17_if(input logic ACLK);
  logic q;
endinterface
module top(input logic clk);
  m17_if f(clk);
endmodule
