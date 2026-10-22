# MLDSA row 96 runner gate: job 2720

The generated-UVMF runner output-path fix worked: pinned Icarus compiled row 96 successfully and VVP loaded the generated image. VVP then exited 1 before the test produced any UVM result. Its six diagnostics point to `$fatal("...", ...)` calls in the pinned generated `ML_KEM_base_sequence.svh`; these omit the required numeric finish argument. This is malformed testbench syntax, not an Icarus defect or DUT failure. The SystemVerilog severity-task syntax takes the finish number before message arguments ([IEEE 1800-2017](https://fpga.mit.edu/6205/_static/F25/documentation/1800-2017.pdf)).

The selected MLDSA sequence also invokes `./test_dilithium5`, which was not staged by the prior runner. A new setup step now builds a hash-guarded copy from the pinned Adams Bridge C reference source, checks its KAT and file protocol, and stages the executable. The Icarus overlay adds the standard fatal finish number to the six generated ML-KEM calls. Neither change touches RTL, firmware, or pass criteria.

This gate is **BLOCKED before the testcase result**; it is not counted as PASS or as a functional firmware FAIL. The raw `result.json` preserves the runner's original status. Compile/runtime logs, commands, source snapshot hash, and metadata are under [`raw/`](raw/).
