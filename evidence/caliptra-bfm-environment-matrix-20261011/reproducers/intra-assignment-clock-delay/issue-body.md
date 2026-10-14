## Summary

> **Superseded draft:** This pre-correction bit-versus-logic description is not the current issue text. The actual Caliptra clock snippet is now reproduced under c339 and Verilator; the bit-versus-logic distinction remains unsupported. See the current #545 description and `../caliptra-top-clock-generator/README.md`.

Icarus reports that an `always` loop has no delay when its only timing control is a blocking intra-assignment delay to a 2-state `bit` variable. The construct is legal SystemVerilog and the equivalent `logic` clock works in c339.

## Minimal reproducer

```systemverilog
module intra_assignment_bit_clock_delay;
  bit core_clk;

  always begin : clk_gen
    core_clk = #5ns ~core_clk;
  end

  initial begin
    #20ns;
    #1ps;
    if (core_clk !== 1'b0) $fatal(1, "clock did not return low at 20 ns");
    $display("PASS: bit clock with intra-assignment delay generated four edges");
    $finish;
  end
endmodule
```

Run with `iverilog -g2012 -s intra_assignment_bit_clock_delay intra_assignment_bit_clock_delay.sv`; pinned c339 reports:

```text
intra_assignment_bit_clock_delay.sv:4: error: always process does not have any delay.
intra_assignment_bit_clock_delay.sv:4:      : A runtime infinite loop will occur.
Elaboration failed
```

Verilator 5.051 accepts and runs it with `--binary --timing`, printing the PASS message. Replacing `bit core_clk;` with `logic core_clk = 1'b0;` also compiles and passes under pinned c339.

IEEE 1800-2023 §9.4.5 (p. 237) says an intra-assignment delay delays assignment of the new value; §10.4.1 (p. 251) includes `variable_lvalue = delay_or_event_control expression` in blocking-assignment syntax. The reproducer and raw compiler/runtime evidence are in `intra_assignment_bit_clock_delay.sv` and `../iverilog-c339/clock-bit-results/`.
