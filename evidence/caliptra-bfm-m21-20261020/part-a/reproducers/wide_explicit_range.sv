module wide_explicit_range;
  covergroup cg with function sample(input bit [255:0] value);
    cp: coverpoint value {
      bins full = {[256'h0:256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff]};
    }
  endgroup
  cg coverage = new();
  initial begin
    coverage.sample('0);
    $display("WIDE_EXPLICIT_RANGE_OK");
    $finish;
  end
endmodule
