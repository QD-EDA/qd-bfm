# Icarus packed-struct assignment width reproducer

`sigencode_z_tb` reports 3,584 mismatches where every observed output is `xxxxx`. Instrumenting a temporary copy showed zero output-memory writes. In pinned `sigencode_z_top.sv`, request patterns assign `locked_*_addr + num_*_operands` to the packed request's address field. The address is 14 bits, but the counter makes the addition 32 bits.

This self-contained bench compares that wide expression with the same expression explicitly sized to the 14-bit member. Icarus c339 leaves `rd_wr_en` at `RW_IDLE` for the wide expression (`bad=0002`, `bad_en=00`); Verilator 5.051 produces `RW_READ` (`bad=4002`, `bad_en=01`). Both simulators produce `RW_READ` for the sized control. This reproduces the request-field failure observed in the pinned `sigencode_z_top.sv` at lines 183-184 and 203-204.

The mismatch is against IEEE 1800-2017 §10.9.2, which requires each structure assignment-pattern member expression to be evaluated in the context of the corresponding member type ([standard text](https://fpga.mit.edu/6205/_static/F25/documentation/1800-2017.pdf)).

## Run

```sh
iverilog -g2017 -s tb -o repro.vvp self-contained.sv
vvp -n repro.vvp
verilator --binary --timing -Wno-fatal --top-module tb self-contained.sv --Mdir obj_dir
./obj_dir/Vtb
```

Both compiles and runs exited 0. They ran serially on `MacBook-Air.local` (macOS 27.0, arm64), each under `~/codex-supervisor/localrun 1200`; runner logs include elapsed time and peak RSS. Tool hashes and source revisions are recorded beside this file.
