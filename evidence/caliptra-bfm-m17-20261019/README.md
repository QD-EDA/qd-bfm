# Caliptra BFM M17 matrix

This report covers the 108-row M15/M16 corpus in `m17-results.tsv`. M17 exercises the remaining authored-stimulus rows and generated open-AHB/AAXI environments, records per-row `PASS`, `FAIL`, `BLOCKED`, `TIMEOUT`, or `NOT_RUN`, and preserves raw Slurm outputs with SHA-256 checksums under `attempts/`.

## Pins and run limits

- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Adams Bridge: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.
- Icarus source: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`.
- Icarus binary SHA-256: `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- Runs execute on DAN-DESKTOP with one CPU and 4 GiB per row, a 600 s per-row timeout, and no more than six concurrent tasks. Raw archives contain structured row results, logs, job metadata, and overlay artifacts; each attempt retains its frozen source snapshot and checksum beside the archive.

## Overlay boundary

Overlays are limited to BFM, testbench, filelist, and setup compatibility. They do not edit RTL, firmware, expected outputs, or pass criteria. A row is `PASS` only when its existing testbench emits a recognized pass marker without a failure marker or UVM error/fatal. Normal `$finish` without a result checker is not counted as a pass.

The top AAXI filelist omits the unused ARM `Axi4PC.sv` syntax-guard stub after a source search confirmed the environment does not instantiate it. The M17 runner unit test covers which environments may drop that entry.

## Results

The authoritative row-by-row record is [`m17-results.tsv`](m17-results.tsv). Attempt READMEs explain each gate or batch. Every raw archive and frozen source snapshot has an adjacent SHA-256 sidecar. Infrastructure/staging failures are retained in the attempt history but do not count as test outcomes.

Final M17 counts across the 108 rows: 22 `PASS`, 17 `FAIL`, 31 `BLOCKED`, 9 `TIMEOUT`, and 29 intentionally out of scope `NOT_RUN`. All 79 M17 target rows have a terminal result.

## Root-cause summary

- Top AAXI and generated SoC-IFC compilation stops first at the pinned wildcard-transition coverage syntax defect (#661); the compile also reports the unavailable vendor `avery_defines.svh` include.
- Generated ECC, SHA512, and PV benches remain blocked by tracked Icarus compatibility issues (#663, #664, #667, #670, #671, #672). No simulation starts for these rows.
- ML-DSA rows 87 and 102 staged and checked the pinned native Dilithium models, compiled, and then hit the AHB transfer cast tracked by #666. Row 105 timed out at 600 s after seed and signing-randomness writes. ML-KEM rows that need vector generation stop because the pinned Adams Bridge source lacks the expected Python model helper and input vectors.
- Authored Adams Bridge blockers are pinned missing MLDSA configuration headers, stale `compress_tb` DUT ports after the filelist repair, and two benches that finish without a usable result checker. UART, DOE CBC, ECC top, and several longer ML-KEM/ML-DSA flows are recorded as timeouts at the 600 s limit.
- The other functional failures are a KeyVault factory sequence type mismatch and a SoC-IFC testbench assertion about the SHA accelerator interrupt register changing over AXI.

## Intentionally out of M17 scope

These 29 rows remain `NOT_RUN` in the M17 columns because they were not part of the M17 remaining authored-stimulus or open-AHB/AAXI target set: `5, 6, 8, 11, 14, 15, 18, 19, 20, 39, 49, 50, 52, 53, 57, 59, 60, 62, 63, 66, 67, 68, 70, 71, 72, 74, 75, 76, 107`. Their earlier milestone records remain in the M15/M16 columns.

## Change verification

The focused runner suite passed all 71 tests on the Mac (Python 3.14.7, 0.20 s wall time, 30,834,688-byte peak RSS); an isolated mutation check confirmed the ML-DSA model selector test catches an inverted condition. Details are in [`unit-tests.txt`](unit-tests.txt). Final validation confirmed 108 unique matrix rows, terminal results for all 79 in-scope rows, and 63 archived run/source snapshots with matching checksums and resolvable result references.
