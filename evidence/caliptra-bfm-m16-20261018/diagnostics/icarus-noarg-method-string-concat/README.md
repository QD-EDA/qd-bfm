# Icarus omitted class-method parentheses in a concatenation

The minimal reproducer in `noarg_method_string_concat.sv` fails with the pinned Icarus 13.0 binary: a no-argument class method used as a string-concatenation operand without `()` is rejected as not being a string. The same source prints `NOARG_METHOD_STRING_CONCAT_OK` with Verilator 5.051. IEEE 1800-2017 permits omitting empty parentheses for class methods except the directly-recursive non-void case; the reproducer is not recursive.

Pinned-Icarus controls show that the nested call succeeds with explicit `()` and that a flattened local-handle control also compiles and runs. The raw pinned logs, Slurm script and metadata are under `raw/pinned-2718/`. Local compiler outputs and source hashes are beside this README. Local Icarus 14.0 produced a different nested-property diagnostic and an incorrect runtime result; the issue report uses the reproducible pinned 13.0 failure.

The minimized simulator defect is filed internally as [dsellerbrock/iverilog-uvm #664](https://github.com/dsellerbrock/iverilog-uvm/issues/664), labeled `from-caliptra-dv`. It is not posted upstream. The issue body and reproducer are preserved here.
