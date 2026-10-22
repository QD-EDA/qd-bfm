## Summary

Pinned Icarus 13.0 rejects a trailing empty positional argument to `$psprintf`. The same compiler builds and runs a control with only that trailing comma/empty argument removed. Verilator 5.032 builds and runs both. The Caliptra KeyVault generated configuration contains the same argument-list shape in a `uvm_info` message. `$psprintf` is non-standard (Verilator emits `NONSTD`), so please classify this compatibility case before choosing a fix.

## Minimal reproducer

`psprintf_empty_arg.sv`:

```systemverilog
module psprintf_empty_arg;
  initial begin
    $display("%s", $psprintf("The agent at '%s' uses %s", "agent", "ifname", ));
    $finish;
  end
endmodule
```

Control `psprintf_control.sv` differs only by removing the last comma and empty argument.

## Results

Icarus reproducer command:

```sh
iverilog -g2017 -s psprintf_empty_arg -o repro-empty.vvp psprintf_empty_arg.sv
```

Pinned Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`:

- Reproducer compile exits 1: `The function $psprintf has been called with missing/empty parameters.`
- Control compile and run exit 0; it prints `The agent at 'agent' uses ifname`.

Verilator 5.032 (Debian 5.032-1): both forms compile and run with exit 0 using `verilator --binary --timing -Wno-fatal --top-module psprintf_empty_arg --Mdir obj_empty psprintf_empty_arg.sv` followed by `obj_empty/Vpsprintf_empty_arg`. The reproducer prints `The agent at 'agent' uses ifname ` (with a trailing space). Verilator warns that `$psprintf` is non-standard.

## Caliptra context

At Caliptra RTL pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, `kv_rst_configuration.svh` SHA256 `9d1682590cb85410b67cefe0df3f66f6ca31304f03a1458d283df99411c3a2a6` has the same trailing-empty-argument shape at lines 142–144:

```systemverilog
`uvm_info("CFG",
          $psprintf("The agent at '%s' is using interface named %s has the following parameters: ", agent_path, interface_name, ),
          UVM_DEBUG)
```

The full generated KeyVault compile log reports the error at line 149; the source call is at lines 142–144. The source excerpt and compile log are retained in the local M16 evidence tree.

The reduced source, both Slurm job captures, source context, commands, compiler hashes/versions, and logs are preserved in this directory. This report does not claim a full Caliptra test pass and changes no RTL, firmware, or pass criteria.
