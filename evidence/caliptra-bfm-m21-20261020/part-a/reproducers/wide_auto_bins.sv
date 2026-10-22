class sha512_result_transaction;
  bit [511:0] result;
endclass

class wide_result_coverage;
  sha512_result_transaction coverage_trans;
  covergroup result_cg;
    option.auto_bin_max = 1024;
    result: coverpoint coverage_trans.result;
  endgroup

  function new();
    coverage_trans = new();
    result_cg = new();
  endfunction
endclass

module wide_auto_bins;
  wide_result_coverage coverage;
  initial begin
    coverage = new();
    coverage.result_cg.sample();
    $display("WIDE_AUTO_BINS_OK");
    $finish;
  end
endmodule
