# Generated UVMF dynamic-array slice diagnostic

KeyVault row 6 and MLDSA row 96 both contain assignments from one-element dynamic-array slices to dynamic-array class properties. The generated source hashes are recorded below. The class-level reproducer matches the generated argument/property/allocation shape and enum activity type; its control changes only the RHS expressions to element copies.

## Results

| Job | Case | Pinned Icarus 13.0 | Verilator 5.032 |
| --- | --- | --- | --- |
| 2786 | Plain module arrays, string slice | Compile/run PASS | Compile BLOCKED (`Illegal range select`) |
| 2787 | Class properties assigned from formal-array slices | Compile BLOCKED (two unsupported-slice diagnostics) | Compile BLOCKED (`Illegal range select`) |
| 2789 | Same class setup with `[0]` element copies | Compile/run PASS | Compile/run PASS |

The class-level failure is reproducible on both tools; it is a shared support gap, not an Icarus-only compatibility difference. The element-copy control passes on both. This does not change either Caliptra row's result and does not claim that the slice is the only remaining blocker in either environment.

The pinned Icarus source is `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Verilator is `5.032 2025-01-01 rev (Debian 5.032-1)`. Caliptra is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; generated config hashes are KeyVault `52de073510ca16bb8d672d355f54170bedd60268acc00b097d7ad6bcd40b862a` and MLDSA `ebc6c0088ebfdebf48605235ca57a032ebac06acb0a1a97de19349a513e01973`. Host, exact commands, compile/run output and resource logs are preserved in the three raw job archives. Each remote run tree was removed after its archive hash matched locally.

Internal issue [#671](https://github.com/dsellerbrock/iverilog-uvm/issues/671) is open with label `from-caliptra-dv` for A3 to classify.
