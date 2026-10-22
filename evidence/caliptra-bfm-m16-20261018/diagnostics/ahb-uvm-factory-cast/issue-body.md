## Summary

A minimal UVM object hierarchy derived from MLDSA generated-UVMF row 96 produces a runtime `$cast` discrepancy on pinned Icarus. The factory reports a matching type wrapper, but casts from the MVC base to both the typedef alias and generated parameterized class return false. The row-96 scoreboard cast failed at 425 ns in job 2755 after printing `alias_wrapper_match=1`.

The reduced case has no queue or analysis port. Removing only the class-scope `DATA_WIDTH` localparam makes the typedef-alias cast succeed on Icarus, which isolates the trigger.

## Reproducer

```systemverilog
`include "uvm_macros.svh"

package mvc_pkg;
  import uvm_pkg::*;

  class mvc_sequence_item_base extends uvm_pkg::uvm_sequence_item;
    `uvm_object_utils(mvc_sequence_item_base)

    function new(string name = "mvc_sequence_item_base");
      super.new(name);
    endfunction
  endclass
endpackage

package mgc_ahb_v2_0_pkg;
  import uvm_pkg::*;

  class ahb_master_burst_transfer #(
    parameter int NUM_MASTERS = 1,
    parameter int MASTER_BITS = 1,
    parameter int NUM_SLAVES = 1,
    parameter int ADDRESS_WIDTH = 32,
    parameter int WDATA_WIDTH = 32,
    parameter int RDATA_WIDTH = 32
  ) extends mvc_pkg::mvc_sequence_item_base;
    localparam int DATA_WIDTH = WDATA_WIDTH > RDATA_WIDTH ? WDATA_WIDTH : RDATA_WIDTH;

    `uvm_object_param_utils(ahb_master_burst_transfer #(NUM_MASTERS, MASTER_BITS,
      NUM_SLAVES, ADDRESS_WIDTH, WDATA_WIDTH, RDATA_WIDTH))

    function new(string name = "ahb_master_burst_transfer");
      super.new(name);
    endfunction
  endclass
endpackage

package ahb_lite_caliptra_uvm_pkg;
  typedef mgc_ahb_v2_0_pkg::ahb_master_burst_transfer #(1, 1, 1, 32, 32, 32)
    ahb_lite_caliptra_mvc_transfer;
endpackage

package qvip_ahb_lite_slave_params_pkg;
  class ahb_lite_slave_0_params;
    localparam int AHB_NUM_MASTERS = 1;
    localparam int AHB_NUM_MASTER_BITS = 1;
    localparam int AHB_NUM_SLAVES = 1;
    localparam int AHB_ADDRESS_WIDTH = 32;
    localparam int AHB_WDATA_WIDTH = 32;
    localparam int AHB_RDATA_WIDTH = 32;
  endclass
endpackage

package mldsa_env_pkg;
  typedef mgc_ahb_v2_0_pkg::ahb_master_burst_transfer #(
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_NUM_MASTERS,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_NUM_MASTER_BITS,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_NUM_SLAVES,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_ADDRESS_WIDTH,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_WDATA_WIDTH,
    qvip_ahb_lite_slave_params_pkg::ahb_lite_slave_0_params::AHB_RDATA_WIDTH
  ) generated_transfer_t;
endpackage

module tb;
  mvc_pkg::mvc_sequence_item_base base_item;
  ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer alias_item;
  mldsa_env_pkg::generated_transfer_t generated_item;
  bit alias_cast;
  bit generated_cast;

  initial begin
    generated_item = mldsa_env_pkg::generated_transfer_t::type_id::create("item");
    base_item = generated_item;
    alias_cast = $cast(alias_item, base_item);
    generated_cast = $cast(generated_item, base_item);
    $display("RESULT type=%s alias_wrapper_match=%0d generated_wrapper_match=%0d alias_cast=%0d generated_cast=%0d",
      base_item.get_type_name(),
      base_item.get_object_type() == ahb_lite_caliptra_uvm_pkg::ahb_lite_caliptra_mvc_transfer::type_id::get(),
      base_item.get_object_type() == mldsa_env_pkg::generated_transfer_t::type_id::get(),
      alias_cast, generated_cast);
    $finish;
  end
endmodule
```

## Results

- **Icarus 13.0 devel**, source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, `iverilog` SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`, UVM 2020.3.1: compile and run exit 0, but `alias_wrapper_match=1 generated_wrapper_match=1 alias_cast=0 generated_cast=0`.
- **Control on the same Icarus build**, with only the localparam removed: `alias_wrapper_match=1 generated_wrapper_match=1 alias_cast=1 generated_cast=0`.
- **Verilator 5.051 devel** (`v5.050-196-g7dcd4e0b6`), UVM 2020.3.1: compile and run exit 0; `alias_wrapper_match=1 generated_wrapper_match=1 alias_cast=1 generated_cast=1`. Built with `-DUVM_NO_DPI`; this checks SV object identity and casting, not UVM DPI helpers.

Icarus commands:

```sh
iverilog -uvm -g2017 -s tb -o repro.vvp ahb_uvm_factory_cast.sv
vvp -n repro.vvp
```

Verilator command:

```sh
verilator --binary --timing -j 3 -Wno-fatal -DUVM_NO_DPI \
  --top-module tb --Mdir obj_dir -I/usr/local/lib/ivl/uvm/src \
  /usr/local/lib/ivl/uvm/src/uvm_pkg.sv ahb_uvm_factory_cast.sv
obj_dir/Vtb
```

This is distinct from #663, which concerns compile-time inherited type-parameter member loss. Exact-source logs, resource reports, toolchain hashes, and the local one-line control are in the A2 evidence tree under `evidence/caliptra-bfm-m16-20261018/diagnostics/ahb-uvm-factory-cast/`.
