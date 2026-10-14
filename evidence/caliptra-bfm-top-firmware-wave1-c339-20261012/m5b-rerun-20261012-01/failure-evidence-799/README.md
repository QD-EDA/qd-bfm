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

Task 26 (`smoke_test_ecc_errortrigger2`) ended as FAIL after 2:35:17. Its
result JSON reports `passed=false`; the simulator log contains a fatal
`ERR_ECC_PRIVKEY_NOT_STABLE` assertion at `ecc_dsa_ctrl.sv:1081`. The wrapper
status stops at `wall_s=8700 mcycle=60408`, but the full log advances through
`wall_s=9000 mcycle=62553`; that later sample is the recorded final mcycle.
There was no 30-minute flat interval. Maximum RSS was 1,852,436 KiB. Its raw
result JSON, status, simulator, firmware, console, provenance, and Slurm logs
are under `runs/35-78ad1bab537c2ff8-26/`, with remote hashes in
`REMOTE-SHA256SUMS-task26.txt`.

Task 36 (`smoke_test_pcr_zeroize`, source row 45) ended as FAIL after 2:40:56.
`result.json` reports `passed=false`, compile exit 0, simulation exit 1, one
bad diagnostic, and no finish record. `sim.log` contains a fatal
`ERR_ECC_PRIVKEY_NOT_STABLE` assertion at `ecc_dsa_ctrl.sv:1081`; there is no
`TESTCASE PASSED` or `TESTCASE FAILED` marker. The final heartbeat in the full
log is `wall_s=9600 mcycle=63065` (33 heartbeats). `status.txt` is stale at
`wall_s=9000 mcycle=61392` and 29 heartbeats, so the full log supplies the
final heartbeat. Resource wall time was 2:40:56 and maximum RSS was 1,852,300
KiB. Selected result JSON, status, simulator, firmware, compile, provenance,
and Slurm logs are under `runs/45-c7d7b277746f7500-36/`; all 25 copied files
match `REMOTE-SHA256SUMS-task36.txt`. At 21:44 MDT, after committing the
evidence and confirming the array task had left Slurm, I deleted its remote
output tree; this freed 375,719,634 bytes (about 0.350 GiB). Compact status
and resource metadata and the wrapper log remain in the protected run dir.


Task 39 (`smoke_test_ecc_errortrigger1`, source row 48) ended as **FAIL** after 4:57:01 (17,821 seconds), below its 21,600-second timeout. `result.json` reports `passed=false`, compile and firmware exits 0, simulation exit 1, and one bad diagnostic. The simulator has no testcase terminal marker; it ends with `ERR_ECC_PRIVKEY_NOT_STABLE` at `ecc_dsa_ctrl.sv:1081`. The full log contains 56 heartbeats; its final heartbeat is `wall_s=17100 mcycle=59872`, with no flat interval. Peak RSS was 1,852,388 KiB. Selected result, simulator, firmware, compile, provenance, status, resource, tool-version, and wrapper logs are under `runs/48-33a3aad04d3bc842-39/` and `logs/`; all 25 files match `REMOTE-SHA256SUMS-task39.txt` (transferred archive SHA-256 `7d4d6d3199e7e94adb10f1df7a3eb064cc2bae0dbec4a573ac9e58448d954d15`). After commit `765958d`, I removed the remote output tree; it occupied 375,745,681 bytes. The run status, resource, provenance, and wrapper logs remain.
