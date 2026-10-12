interface axi_if_min;
  logic valid;
  logic ready;
  modport subordinate(input valid, output ready);
endinterface

module axi_subordinate(axi_if_min.subordinate axi_if);
  logic sampled_valid;
  assign sampled_valid = axi_if.valid;
  assign axi_if.ready = 1'b1;
endmodule

module force_release_interface_port;
  timeunit 1ns;
  timeprecision 1ps;

  logic clk = 1'b0;
  logic source = 1'b1;
  logic inject_delay = 1'b1;
  axi_if_min axi_sram_if();
  axi_subordinate dut(.axi_if(axi_sram_if.subordinate));

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
    $display("PASS: force/release overrides and restores continuous interface assignment with modport connection");
    $finish;
  end
endmodule
