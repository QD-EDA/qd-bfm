## Summary

Pinned Icarus 13.0 rejects an omitted argument list on a no-argument class function method when the call is used as a string-concatenation operand. The same source compiles and runs on Verilator 5.051 devel. IEEE 1800-2017 Annex A.9.3 note 37 permits omitting parentheses for class methods except for the stated directly-recursive non-void case; this reproducer is not recursive: https://fpga.mit.edu/6205/_static/F25/documentation/1800-2017.pdf

## Reproducer

```systemverilog
module noarg_method_string_concat;
  class child_config;
    function string convert2string();
      return "child";
    endfunction
  endclass

  class env_config;
    child_config child;
    function string convert2string();
      return {"prefix:", child.convert2string};
    endfunction
  endclass

  initial begin
    env_config cfg = new();
    cfg.child = new();
    if (cfg.convert2string() != "prefix:child") $fatal(1, "unexpected string result");
    $display("NOARG_METHOD_STRING_CONCAT_OK");
    $finish;
  end
endmodule
```

Pinned Icarus command: `iverilog -g2017 -s noarg_method_string_concat -o repro.vvp noarg_method_string_concat.sv`

Actual: `error: String concatenation operand 2 must be a string literal or an expression of string type: child.convert2string` (exit 1).

Expected: compile and run, printing `NOARG_METHOD_STRING_CONCAT_OK`.

Controls: the same pinned compiler passes and runs when the call is written `child.convert2string()`; Verilator passes the original unparenthesized form. Toolchain pins, compiler hashes, raw outputs, and source/control files are preserved in `evidence/caliptra-bfm-m16-20261018/diagnostics/icarus-noarg-method-string-concat/`.

## Caliptra impact

Generated MLDSA row 96 has the equivalent expression in `mldsa_env_configuration.svh:92`. It stops that row's compile before simulation when using the clean-room AHB QD-BFM compatibility filelist. No RTL, firmware, or pass criteria are involved.
