## Reduced reproducer

```systemverilog
module wildcard_transition_bin_tb;
  logic [31:0] event_value;
  covergroup cg with function sample(input bit [31:0] bus_event);
    cp: coverpoint bus_event {
      wildcard bins set = (32'h0000_0000 => 32'h400?_????);
    }
  endgroup
  cg coverage = new;
endmodule
```

Run with:

```sh
iverilog -g2012 -s wildcard_transition_bin_tb -o wildcard_transition_bin_tb.vvp wildcard_transition_bin_tb.sv
```

## Observed

On Icarus 13.0 (devel), source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, `iverilog` exits 1 and prints:

```text
wildcard_transition_bin_tb.sv:5: syntax error
wildcard_transition_bin_tb.sv:5: sorry: unsupported bins declaration was ignored (functional coverage for it is not collected).
```

The statement is reduced from Caliptra's `cptra_status_transaction_coverage.svh`; the full generated SoC-IFC environment fails compilation at this declaration family. See `evidence/caliptra-bfm-m16-20261018/diagnostics/iverilog-wildcard-transition-bin/` for the exact source, binary hashes, run command, and output.

Please classify whether this is an intended unsupported feature or a compiler error-handling bug, and fix it if appropriate. No upstream issue was opened.
