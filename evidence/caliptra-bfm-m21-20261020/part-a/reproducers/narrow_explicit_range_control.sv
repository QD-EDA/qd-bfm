module narrow_explicit_range_control;
  covergroup cg with function sample(input bit [63:0] value);
    cp: coverpoint value { bins full = {[64'h0:64'hffffffffffffffff]}; }
  endgroup
  cg coverage = new();
  initial begin
    coverage.sample('0);
    $display("NARROW_EXPLICIT_RANGE_OK");
    $finish;
  end
endmodule
