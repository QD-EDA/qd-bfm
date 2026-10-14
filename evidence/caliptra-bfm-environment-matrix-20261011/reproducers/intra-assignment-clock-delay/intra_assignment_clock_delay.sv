module intra_assignment_clock_delay;
  timeunit 1ns;
  timeprecision 1ps;

  logic core_clk = 1'b0;

  always begin : clk_gen
    core_clk = #5ns ~core_clk;
  end

  initial begin
    #20ns;
    #1ps;
    if (core_clk !== 1'b0) $fatal(1, "clock did not return low at 20 ns");
    $display("PASS: intra-assignment delay generated four clock edges");
    $finish;
  end
endmodule
