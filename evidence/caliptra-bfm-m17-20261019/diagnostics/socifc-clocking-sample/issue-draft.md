## Summary

Icarus fails to elaborate a sampled-value function in a procedural event control when the module declares a default clocking block. IEEE 1800-2017 §16.9.3 permits sampled-value functions in procedural code and infers the default clocking event outside assertions. The default clocking support umbrella issue #17 explicitly left default clocking out of scope.

## Minimal reproducer

```systemverilog
module top;
  logic clk_tb = 0;
  logic signal = 0;
  always #5 clk_tb = ~clk_tb;
  default clocking default_clk @(posedge clk_tb); endclocking
  initial begin
    #2 signal = 1;
    #10 $finish;
  end
  initial forever @($changed(signal)) $display("changed at %0t", $time);
endmodule
```

Compile with `iverilog -g2017 -gassertions -s top default-clocking-changed.sv -o test.vvp`.

## Observed

Pinned Icarus 9b5fad2afb4104caa816b257d5bccc40f01b8c66 (binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) and current main ca559fd97b19bd6a56cc10f0faf8583b4077975f (binary SHA-256 `c99ee9c08468fb20f7635fb3380adb0d620c9037c19c02236a435a61c7be0130`) both fail with `System function $ivl_clocking_sample not defined in system table or SFT file(s)`.

The same behavior is present in five event controls in Caliptra's SoC-IFC testbench. A testbench overlay that samples `$changed` at `@(posedge clk_tb)` compiles and runs, and SoC-IFC row 21 passes with that overlay. Verilator 5.032 does not validate the original form: with timing enabled it reports an internal `Unknown node type ... STABLE` error.

## Expected

Support sampled-value function expressions in procedural event controls using the inferred default clocking event, or emit a direct unsupported-feature diagnostic instead of the unresolved internal system function. Preserve the LRM sampling region semantics.

## Evidence

Reproducer, compiler output, and the passing workaround are retained under `evidence/caliptra-bfm-m17-20261019/diagnostics/socifc-clocking-sample/`.