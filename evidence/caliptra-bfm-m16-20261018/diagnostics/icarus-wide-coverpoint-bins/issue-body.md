## Summary

Pinned Icarus 13.0 rejects an automatic-bin coverpoint on a 512-bit class property during elaboration. The otherwise identical 64-bit control compiles and runs. This construct is copied from Caliptra's generated `SHA512_out_transaction_coverage.svh`, where `OUTPUT_TEXT_WIDTH` defaults to 512 and `result` is the coverpoint.

## Reproducer (512-bit)

```systemverilog
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
```

## Control (64-bit)

```systemverilog
class sha512_result_transaction;
  bit [63:0] result;
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

module narrow_auto_bins_control;
  wide_result_coverage coverage;
  initial begin
    coverage = new();
    coverage.result_cg.sample();
    $display("NARROW_AUTO_BINS_OK");
    $finish;
  end
endmodule
```

## Pinned result

- Icarus: 13.0 devel, source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- 64-bit control: compile and run exit 0; prints `NARROW_AUTO_BINS_OK`.
- 512-bit case: compile exit 1 with `automatic bins for a coverpoint wider than 64 bits are not represented`; simulation does not start.
- The control also warns that this class-property sample is currently treated as constant zero. That separate coverage-sampling limitation is visible in the raw log and is not hidden by this report.

Commands: `iverilog -g2012 -s <top> -o <top>.vvp <source.sv`, then `vvp -n <top>.vvp` for the control. Each command had a 60-second timeout. Both source files, complete logs, tool hashes, and the Slurm run metadata are preserved in `evidence/caliptra-bfm-m16-20261018/diagnostics/icarus-wide-coverpoint-bins/` in the QD-BFM worktree.

## Caliptra impact

Generated SHA-512 row 17 (`SHA512_random_test`) stops before simulation at `SHA512_out_transaction_coverage.svh:50` because `coverage_trans.result` is 512 bits. That row also has a separate no-parentheses string-concatenation error already tracked in internal issue #664. No RTL, firmware, or pass criteria are involved.
