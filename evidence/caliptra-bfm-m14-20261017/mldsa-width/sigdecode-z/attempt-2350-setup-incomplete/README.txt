M14 sigdecode_z overlay follow-up — BLOCKED_SETUP, NOT A TEST RESULT

Job 2350 compiled and exited 0, but it is not a pass: the runtime Python lacks NumPy, so polyz_unpack.py generated neither input_z.hex nor output_decoded_z.hex. The testbench printed two missing-file errors for each of its two runs, then completed empty comparisons. This is invalid setup evidence; no pass or fail is assigned to the row.

The M14 overlay did remove the stale extra testbench argument while preserving each destination base and all comparison code. The next attempt must supply the reproducible NumPy vector-generation setup and verify both expected files before running VVP. The full run was hash-verified and preserved under raw/ before cleanup.

Remote run-tree bytes freed: 193313.
