# Job 799 task 29 firmware-build failure

Task 29 (`smoke_test_kv_ecc_flow1`, source row 38) ended as FAIL after 36.47
seconds, before VVP started. The wrapper reports `FAIL`, runner exit 1, and no
progress heartbeats. No simulator `sim.log`, result JSON, or testcase terminal
marker was produced, so no final mcycle exists.

The firmware build failed because GCC treated the undeclared `srand` call at
line 197 as an error. `runner.log` reports the failed firmware build and missing
images; `firmware.log` contains the compiler diagnostic. The run used the pinned
c339 binaries. Raw build, firmware, status, resource, provenance, and Slurm logs
are under `runs/38-b65eaf52203ca1c3-29/` and `logs/`, with remote hashes in
`REMOTE-SHA256SUMS-task29.txt`.

Task 31 (`smoke_test_kv_ecc_flow2`, source row 40) also ended as FAIL before
VVP started, after 26.31 seconds. The wrapper reports runner exit 1 and zero
heartbeats; no simulator `sim.log`, result JSON, testcase marker, or final mcycle
exists. GCC reports the same implicit `srand` declaration at line 197. The raw
status, resource, build, firmware, provenance, and Slurm logs are under
`runs/40-244a281ff42ebdc1-31/`, with remote hashes in
`REMOTE-SHA256SUMS-task31.txt`.
