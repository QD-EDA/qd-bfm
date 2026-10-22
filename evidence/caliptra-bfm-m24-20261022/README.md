# M24 full-census firmware matrix on Verilator 5.052

M24 records all 271 rows from the pinned Caliptra DV test census. The existing full-top wrapper ran the 162 `stock-firmware-test-suite` YAMLs. The other 109 rows are `WAITLIST`: 57 authored-stimulus and 52 generated-UVMF benches have no M24 stock-firmware launch path and were not simulated.

## Pins and run

- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- QD-BFM source: `origin/main` snapshot `b038ce402c359fceb3f341eae2c8fa11f12e95d3`.
- Verilator: 5.052 (`2026-09-05 rev v5.052`); model SHA-256 `f37bd4595e1a2d9eb2a683d40a37b9689133d989d8bb979110ae18d3ff5c81e3`.
- Model build: Slurm job 4023, 1:19.92 wall, 2,359,520 KiB peak RSS. Compact build metadata and checksums are in [`build-evidence/`](build-evidence/).
- Matrix: Slurm array job 4024, indices `0-270%6`, 4 CPUs / 4 GiB / 4-hour Slurm limit per task. The case simulation cap was `min(M9 per-case cap, 13,800 s)`; an outer 14,300-second timeout leaves cleanup margin. The runner did not alter firmware, test logic, assertions, or pass criteria.
- All 271 tasks produced one summary and exited 0 at the harness level. The array result and summary bundle were fetched; the matrix run directory was removed by `slurm-run` after fetch.

## Results

| M24 status | Rows | Notes |
| --- | ---: | --- |
| PASS | 103 | 103/162 full-top rows (63.6%). |
| FAIL | 44 | Terminal simulation/testbench failures; causes are in [`results.tsv`](results.tsv). |
| FIRMWARE_BUILD_FAIL | 14 | Compiler/link diagnostics are recorded per row. |
| TIMEOUT | 1 | `cptra_ss_test_rom` reached its 6,873-second per-case cap without a terminal marker. |
| WAITLIST | 109 | 57 authored-stimulus and 52 generated-UVMF rows; no M24 simulation attempted. |

`results.tsv` has every census row, per-case M24 status and wall time, the M9 Verilator comparison, the most recent Icarus status/source, and a one-line cause for every non-PASS row.

### Comparison with M9

M9 ran the same 162 stock-firmware rows: 103 PASS, 43 FAIL, 14 firmware-build failures, and 2 TIMEOUT. M24 has 103 PASS, 44 FAIL, 14 firmware-build failures, and 1 TIMEOUT. Forty-three FAILs, all 14 build failures, and one timeout match M9; `smoke_test_mbox` is now classified as FAIL at the testbench's 20-million-cycle guard instead of M9's TIMEOUT. Summed per-case wall time fell from 105,804.838 s to 99,356.264 s (6.09% lower); this is the sum of case times, not array elapsed time.

### Comparison with M21 Part B Icarus

For the same 20 selected rows, M21 Icarus recorded 11 PASS and 9 TIMEOUT. M24 Verilator recorded 19 PASS and 1 FAIL: eight Icarus timeouts now pass, and `smoke_test_doe_scan` remains FAIL. The M24 sum for these 20 rows is 1,971.316 s; M21's summed case time was 276,567 s. These are summed per-case wall times, not parallel array durations.

The earlier M23 Verilator run of those 20 rows had 18 PASS, 1 FAIL, and 1 firmware-build failure. M24 fixes its row 144 mapping: matrix name `smoke_test_sha3_interrupts` now maps to firmware directory `smoke_test_sha3_interrupt`; the row passes in 35.945 s. Row 57 `smoke_test_doe_scan` still fails in 163.492 s with the pinned DOE SVA message.

## Failure groups and waitlist

The 44 FAIL rows include 34 LMS firmware images whose `dccm.hex` load exceeds the testbench DCCM array, seven cases stopped by the 20-million-cycle guard, the DOE clear-obfuscation SVA assertion, the existing `smoke_test_kv_lock_use_mid_read` BAD-scanner false positive (QD-BFM issue #12), and one terminal `smoke_test_dma` TESTCASE FAILED assertion. The TIMEOUT and 14 firmware-build failures are listed with their causes in [`../../docs/E-VERILOG-WAITLIST.md`](../../docs/E-VERILOG-WAITLIST.md); terminal FAILs remain in the result table rather than being labeled unsupported.

The evidence is intentionally compact: no raw per-test logs, model executable, `.vvp` files, or source snapshots are included.
