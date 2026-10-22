Caliptra generated UVMF configuration initializes a dynamic-array property from a one-element slice of a dynamic-array argument. The exact form occurs in `kv_env_configuration.svh` (lines 209–210) and `mldsa_env_configuration.svh` (lines 120–121):

```systemverilog
qvip_ahb_lite_slave_subenv_interface_names    = new[1];
qvip_ahb_lite_slave_subenv_interface_activity = new[1];
qvip_ahb_lite_slave_subenv_interface_names    = interface_names[0:0];
qvip_ahb_lite_slave_subenv_interface_activity = interface_activity[0:0];
```

The minimized class-level reproducer in the accompanying report uses the same dynamic-array formal arguments, class properties, enum activity type, allocation, and assignments. On the pinned Icarus 13.0 build (source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`), `iverilog -g2017` rejects both slice assignments with `sorry: dynamic-array slice r-values are not yet supported as fixed-size unpacked-array expressions.` Verilator 5.032 rejects the same two expressions with `Illegal range select`.

A control that changes only the two assignments to indexed element copies compiles and runs on both tools, printing `DYNAMIC_ARRAY_CLASS_CONTROL_OK`. This is therefore a reproduced simulator support gap, but not an Icarus-only compatibility difference. Please classify whether Icarus should support this dynamic-array slice expression; no claim is made here about Verilator behavior beyond the observed 5.032 result.

Reproducer and control: `evidence/caliptra-bfm-m16-20261018/diagnostics/icarus-dynamic-array-slice/source/`. Slurm evidence archives for jobs 2786, 2787, and 2789 preserve source hashes, commands, raw output, and resource logs.
