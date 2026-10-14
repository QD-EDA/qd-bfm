interface axi_if_min;
  logic valid;
endinterface

module force_release_interface;
  timeunit 1ns;
  timeprecision 1ps;

  logic clk = 1'b0;
  logic source = 1'b1;
  logic inject_delay = 1'b1;
  axi_if_min axi_sram_if();

  assign axi_sram_if.valid = source;

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
    $display("PASS: force/release overrides and restores continuous interface assignment");
    $finish;
  end
endmodule
