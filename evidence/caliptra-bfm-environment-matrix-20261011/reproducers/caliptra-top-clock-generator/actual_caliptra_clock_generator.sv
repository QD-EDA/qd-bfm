`default_nettype none
module actual_caliptra_clock_generator;
  bit core_clk;

  always begin : clk_gen
    core_clk = #5ns ~core_clk;
  end

  initial begin
    #20ns;
    #1ps;
    if (core_clk !== 1'b0) $fatal(1, "clock did not return low at 20 ns");
    $display("PASS: Caliptra clock generator completed four transitions");
    $finish;
  end
endmodule
