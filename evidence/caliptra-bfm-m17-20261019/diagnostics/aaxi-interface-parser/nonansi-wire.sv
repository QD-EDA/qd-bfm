interface m17_if(ACLK);
  input wire ACLK;
  logic q;
endinterface
module top(input wire clk);
  m17_if f(clk);
endmodule
