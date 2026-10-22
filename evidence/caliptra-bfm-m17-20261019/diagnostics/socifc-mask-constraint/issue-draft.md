## Summary

Icarus cannot translate a legal non-random function call used in an inline randomization constraint. The Caliptra SoC-IFC INTRBLK testbench uses a mask function with a non-rand register-name argument. Precomputing the mask before `randomize()` is a working testbench workaround. This is distinct from closed issue #494, which is specifically about queue-size leaves passed to constraint functions.

## Minimal reproducer

```systemverilog
package p;
  typedef bit [31:0] dword_t;
  function automatic dword_t get_mask(input string name);
    return name == "WO" ? 32'h0000_0001 : 32'h0000_0000;
  endfunction
  class Transaction;
    rand dword_t data;
  endclass
endpackage
module top;
  import p::*;
  Transaction wrtrans;
  string rname;
  initial begin
    wrtrans = new();
    rname = "WO";
    wrtrans.randomize() with { wrtrans.data & get_mask(rname) != 0; };
    if ((wrtrans.data & get_mask(rname)) == 0) $fatal(1, "constraint not met");
  end
endmodule
```

Compile with `iverilog -g2017 -gassertions -s top method-in-constraint.sv -o test.vvp`. A control assigning `wr_mask = get_mask(rname)` before `randomize()` and using `wr_mask` inside the constraint compiles and runs on the same compilers.

## Observed

Pinned Icarus 9b5fad2afb4104caa816b257d5bccc40f01b8c66, c339, and current main ca559fd97b19bd6a56cc10f0faf8583b4077975f reject the function-call form with `constraint ... could not be translated and the randomize call cannot be compiled`. A class-method form produces Icarus's explicit `requires staged evaluation and is not supported` diagnostic.

Verilator 5.032 does not pass the equivalent reproducer: the package-function form hits an internal package-scope error, and the class-method variant does not meet its constraint. No cross-simulator pass is claimed.

## Expected

Evaluate a non-random function call with non-random arguments in an inline constraint, as required for function calls in constraints by IEEE 1800-2017 §18.5.12, or emit a precise unsupported-feature diagnostic.

## Evidence

Minimal cases and cross-compiler results are retained under `evidence/caliptra-bfm-m17-20261019/diagnostics/socifc-mask-constraint/`.