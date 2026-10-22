# Parameterized AHB transfer cast reproducer

This minimal case reproduces the row-96 scoreboard cast failure from MLDSA generated-UVMF. Job 2755 printed `alias_wrapper_match=1` immediately before the cast failed at 425 ns; its raw logs are preserved [here](../mldsa-row96-type-identity-20261018-01/raw/job-2755/).

`ahb_master_burst_transfer` is a six-parameter UVM object class with a class-scope `DATA_WIDTH` localparam derived from its width parameters. The generated type receives those parameters through a nested QVIP parameter class, and the test casts a factory-created object from the MVC base to both the QD-BFM typedef alias and the generated type. The factory reports the same wrapper for both declarations. There is no queue or analysis port in this reduction.

## Results

Pinned Icarus 13.0 (source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`) compiled and ran with exit status 0, but both casts returned false:

```text
RESULT type=mvc_sequence_item_base alias_wrapper_match=1 generated_wrapper_match=1 alias_cast=0 generated_cast=0
```

The control source removes only the `DATA_WIDTH` localparam. On the same Icarus build, the alias cast then succeeds while the generated parameter-expression cast remains false:

```text
RESULT type=mvc_sequence_item_base alias_wrapper_match=1 generated_wrapper_match=1 alias_cast=1 generated_cast=0
```

Verilator 5.051 devel (`v5.050-196-g7dcd4e0b6`) passed the same main source:

```text
RESULT type=mvc_sequence_item_base alias_wrapper_match=1 generated_wrapper_match=1 alias_cast=1 generated_cast=1
```

Verilator was built with `-DUVM_NO_DPI` because this test exercises SV object identity and `$cast`, not UVM DPI helpers. It emitted a host stack-size warning but completed with exit status 0, no UVM_ERROR/FATAL, and the expected result. Exact versions, binary hashes, source hashes, commands, logs, and resource data are recorded in this directory.

## Reproduction

Run with an installed UVM 2020.3.1 source tree:

```sh
iverilog -uvm -g2017 -s tb -o repro.vvp ahb_uvm_factory_cast.sv
vvp -n repro.vvp
```

The control is identical except for the one removed localparam:

```sh
iverilog -uvm -g2017 -s tb -o control.vvp ahb_uvm_factory_cast_control.sv
vvp -n control.vvp
```

Verilator command used on macOS:

```sh
verilator --binary --timing -j 3 -Wno-fatal -DUVM_NO_DPI \
  --top-module tb --Mdir obj_dir -I/usr/local/lib/ivl/uvm/src \
  /usr/local/lib/ivl/uvm/src/uvm_pkg.sv ahb_uvm_factory_cast.sv
obj_dir/Vtb
```

This is distinct from issue #663, which concerns compile-time loss of an inherited type-parameter member. This report is a runtime `$cast` mismatch despite matching factory wrappers. The minimized case is filed internally for A3 as [issue #666](https://github.com/dsellerbrock/iverilog-uvm/issues/666), labeled `from-caliptra-dv`; nothing was posted upstream.
