module m20_auto_bin_repro #(parameter integer WIDTH = 512);
  logic [WIDTH-1:0] result;

  covergroup result_cg;
    option.auto_bin_max = 1024;
    result_cp: coverpoint result;
  endgroup

  result_cg coverage = new;

  initial begin
    result = '0;
    coverage.sample();
    $display("SAMPLE_OK WIDTH=%0d", WIDTH);
    $finish;
  end
endmodule
