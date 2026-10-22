# Row 93 command-width overlay gate

This local one-row run validates the ML-DSA command-byte fix in the M16 testbench overlay. The staged source snapshot is the prior row 93 c339 snapshot with only `run_m15_test.py` updated to apply `op_code-3'd1` to its three native-reference command writes. Caliptra and Adams Bridge source pins and all testcase inputs, expected values, assertions, and pass criteria remain the same.

The Mac does not have the pinned c339 binary. `run-local.sh` patches only the temporary runner copy's expected Icarus version/hash to the local Icarus 14 binary and records its version and binary SHA in `result.json`. The actual c339 and Verilator comparison for the minimal command formatter is in the parent diagnostics directory.

Resources: one local simulation, one thread, 1,800-second runner timeout; wrapper limit 2,100 seconds. The full simulation output is archived after verification under `raw/`.
