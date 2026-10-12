interface axi_if_min;
  logic valid;
  logic [31:0] address;
  logic [7:0] length;
  modport subordinate(input valid, address, length);
endinterface

module axi_subordinate(axi_if_min.subordinate axi_if);
  logic unused;
  assign unused = ^{axi_if.valid, axi_if.address, axi_if.length};
endmodule

module force_release_interface_siblings;
  timeunit 1ns;
  timeprecision 1ps;

  logic clk = 1'b0;
  logic source = 1'b1;
  logic inject_delay = 1'b1;
  axi_if_min axi_sram_if();
  axi_subordinate dut(.axi_if(axi_sram_if.subordinate));

  assign axi_sram_if.valid = source;
  assign axi_sram_if.address = 32'h1234;
  assign axi_sram_if.length = 8'h7;

  always #5ns clk = ~clk;

  always @(negedge clk) begin
    if (inject_delay) force axi_sram_if.valid = 1'b0;
    else release axi_sram_if.valid;
  end

  initial begin
    #11ns;
    inject_delay = 1'b0;
    #10ns;
    if (axi_sram_if.valid !== 1'b1) $fatal(1, "release did not restore interface signal");
    if (axi_sram_if.address !== 32'h1234 || axi_sram_if.length !== 8'h7)
      $fatal(1, "continuous sibling members did not retain their values");
    $display("PASS: force/release leaves continuously assigned interface siblings intact");
    $finish;
  end
endmodule
