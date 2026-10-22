module fourstate_stable_probe;
  logic value;
  initial begin
    value = 1'bx;
    #1;
    if (value !== 1'bx) $fatal(1, "X was not preserved");
    $display("FOURSTATE_PROBE_PASS");
    $finish;
  end
endmodule
