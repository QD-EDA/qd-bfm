# Corrected-checker Verilator pilot

Slurm array task 1315_0 ran `smoke_test_ecc_flow1_kv_ocp_progress` with the
model from build 1311 and the pinned checker overlay. It passed with no bad
diagnostics and the same final mcycle as Icarus c339: 60,927. The Icarus run
took 8,574 seconds; Verilator simulation took 34.925 seconds (245.5x faster).
The Verilator task used 1 CPU, requested 3 GiB, peaked at 26,680 KiB RSS, and
exited 0. Firmware generation took 2.38 seconds; end-to-end harness time was
37.302 seconds.

The successful `* TESTCASE PASSED` marker, `Finished : minstret = 20314,
mcycle = 60927`, zero-error scan, simulator log, resource report, and
`result.json` are retained under `results/`. The exact submission and Slurm
stdout are also retained here. This pilot confirms the corrected overlay
removed the earlier diagnostic-only KV `$display` noise without hiding a
failure or changing the checker predicates.
