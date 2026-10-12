module force_release_continuous;
  timeunit 1ns;
  timeprecision 1ps;

  logic source;
  logic observed;

  assign observed = source;

  initial begin
    source = 1'b0;
    #1ns;
    force observed = 1'b1;
    #1ns;
    if (observed !== 1'b1) $fatal(1, "force did not override continuous assignment");
    release observed;
    #1ns;
    if (observed !== 1'b0) $fatal(1, "release did not restore continuous assignment");
    $display("PASS: force/release overrides and restores continuous assignment");
    $finish;
  end
endmodule
