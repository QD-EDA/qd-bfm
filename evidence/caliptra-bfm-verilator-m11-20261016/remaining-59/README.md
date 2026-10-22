# M11 remaining stock-firmware rows

This run contains only the 59 of 162 stock-firmware cases not present in the completed, verified overlay-v2 array 1835. The 103 prior rows are reused only after exact test ID, name, YAML, timeout, and Icarus baseline matches. Rows are reindexed for this partial Slurm array; `row-mapping.tsv` retains original M11 indices.

The `smoke_test_hw_config` c339 matrix label is normalized to `UNVERIFIED`, following the closed M9 record that excludes it for lacking a terminal run artifact.

Pinned QD-BFM commit: `ffc12ab427e961f40354f32a8e7a147e5d4e5764`. Pinned Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Overlay v2 source is reused byte-for-byte from the verified 103-row run.

The one-row gate already passed on the same v2 model SHA (`2fd1bdfde761a04ea5905384badcb3a927677545e383368a42c77f978d6659a3`), with 600-second outer cap. A fresh build is hash-checked before the array; if its binary SHA differs, run a one-row gate first.

## Fresh build and gate

Build job 1961 completed successfully on DAN-DESKTOP with Verilator 5.052, assertions enabled, 4 CPUs, and 4 GiB requested. Wall time was 1:29.91 and peak RSS was 2,381,308 KiB. The generated overlay hash matches v2 (`d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`); the executable SHA is `3c4d5541ff5f8e8642d0017a414fcf1b216467703b62aaf98df5d7ffd14efb1f`, different from the prior gated binary, so this build is being gated separately.

Gate job 1962 runs `smoke_test_ahb_mux` with a 600-second outer cap. The earlier trace for the same v2 write-channel implementation is in [run 1812's record](../../caliptra-bfm-verilator-m10b-20261016/diagnostics/array-1772-hang/run-1812/README.md): first fuse write AW address `0x30200`, AW/W/B handshakes, then firmware PASS at `mcycle=3973`.

Gate 1962 passed on the fresh model in 5.059 seconds total (simulation 2.829 seconds), firmware exit 0, final `mcycle=3973`, peak RSS 55,372 KiB. Its output and tool-version record are preserved under [`gate/`](gate/), with `FILE-SHA256SUMS` verified. Only after that result, array 1964 was submitted for indices 0–58 at `%6` (1 CPU and 3 GiB per row, 7-hour Slurm limit). Submission hashes and the live snapshot are in [`array-submission.txt`](array-submission.txt) and [`queue-snapshot-1964.txt`](queue-snapshot-1964.txt).

## Collection 01

The first 47 terminal rows were copied to [`completed-1964-01.tar.gz`](completed-1964-01.tar.gz) (SHA-256 `354bb1eea828e7e55e12e273fb94dc2f679e460088e3f96e9e25b6a03739c8f1`); all 47 internal file manifests and the local/remote archive hash matched. The row table is [`batch-01-results.tsv`](batch-01-results.tsv) (SHA-256 `ea69a39e593ea384a0f2c48c87c1cbe8a2107f1fa53cc7f69f3df8f3b12a6c8e`). Counts are 12 `FIRMWARE_BUILD_FAIL` and 35 `FAIL`.

The 35 simulation failures group as 32 LMS cases stopping at the pinned DCCM `$readmem` bounds check, one `smoke_test_mbox` at `AXI_SUB_AR_HSHAKE_ERR`, one `smoke_test_doe_scan` with `DOE STATUS valid bit not set after clear obf secrets cmd`, and `smoke_test_kv_lock_use_mid_read` with the known result-scanner false positive (firmware prints PASS, but the runner's broad `ERROR` match counts expected `error=0x1`). The 12 firmware build failures and their checked compiler/linker diagnostics are listed in [`firmware-build-failures.md`](firmware-build-failures.md). The mailbox row is c339 PASS versus overlay FAIL; v3/v4 traces confirm the AR valid-drop sequence, with the exact BFM scheduling cause still unresolved; see the [local draft](issue-drafts/mbox-first-read-sampling-race.md). The DOE observation has a separate [local draft](issue-drafts/doe-status-after-obf-clear.md); c339 is UNVERIFIED for that row.

The local [LMS DCCM bounds draft](issue-drafts/lms-dccm-readmem-bounds.md) records that the failed generated `dccm.hex` files were not retained, so oversized image versus preload-range mismatch remains unresolved.

After transfer verification, only those 47 terminal result/resource/log trees were removed from the remote run, freeing 34,335,288 bytes. The 12 unfinished tasks were left alone. The cleanup snapshot is [`collection-01-cleanup.txt`](collection-01-cleanup.txt).

## Collections 02 and 03

Collection 02 preserves array index 23, `cptra_ss_test_rom` (`f1991acb7ebadfe1`), as `TIMEOUT` at 6,873.005 simulation seconds with no final mcycle. Its last firmware message is `Sending payload via AHB i/f` at the recorded 5,859,000 timestamp. The root cause is the already-closed M9 DMA stall at FIFO word 15; see the existing [M9 root-cause record](../../caliptra-bfm-verilator-m9-20261016/root-causes.md). The row archive is [`completed-1964-02.tar.gz`](completed-1964-02.tar.gz) (SHA-256 `8bdec74c4d389bc1aa0ef1734c984da64f9b1f1587810b4c5834e66c5721b0ff`), with all 13 row-manifest files verified; its table is [`batch-02-results.tsv`](batch-02-results.tsv). The completed result/resource directories were removed after verification, freeing 85,518 bytes; see [`collection-02-cleanup.txt`](collection-02-cleanup.txt).

Collection 03 preserves array index 53, `smoke_test_uart` (`1e057b20d3564828`), as `FIRMWARE_BUILD_FAIL` before simulation (firmware exit 2, total elapsed 0.886 seconds). The pinned firmware source references 12 UART register/field macros absent from the pinned generated headers. The closed M9 record confirms c339 had the same 12 missing symbols and the same pre-simulation failure, reported under its older `FAIL` label; this is an outcome-label difference, not a simulator behavior change. The row archive is [`completed-1964-03.tar.gz`](completed-1964-03.tar.gz) (SHA-256 `d5ea1e7c29922707e0755427d38da44290a4ea4e13ea0ab31d07f6c4beef2f7b`), with all 11 row-manifest files verified; its table is [`batch-03-results.tsv`](batch-03-results.tsv). The c339 evidence and closed M9 comparison are linked from the [M11 cause index](../cause-groups.md). The completed result/resource directories were removed after verification, freeing 2,071,965 bytes; see [`collection-03-cleanup.txt`](collection-03-cleanup.txt).

## Collection 04

Collection 04 records nine additional terminal rows from array 1964 in [`completed-1964-04.tar.gz`](completed-1964-04.tar.gz) (SHA-256 `c86ecb4741b4b1b030f2d4ce909c3bf5d1b165823f00af691b41feb43463df81`). All 115 files listed by the nine row manifests were verified against the archive; build work directories were excluded. The per-row table is [`batch-04-results.tsv`](batch-04-results.tsv).

Four rows (`infinite_loop`, `smoke_test_mldsa_sign_rnd`, `randomized_pcr_ecc_signing`, and `smoke_test_kv_parallel_access`) stopped at the testbench's 20,000,000-cycle limit. `jtag_tap_mbox` also reached that limit while writing its mailbox payload; its root cause reuses the closed M9/#13 diagnosis and is not re-audited here. `smoke_test_dma` reached its persistent test failure after reset. Its source calls `soc_ifc_axi_dma_read_mbox_payload` as a boolean even though the `uint8_t` helper has no return statement; the archived log does not capture the returned byte. Two LMS rows fail on the DCCM `$readmemh` bounds check. `smoke_test_kv_crypto_flow2` fails before simulation because argument 3 of `mldsa_keygen_flow` is an integer where the declaration requires `uint32_t *`.

This collection added the 32nd c339 terminal disagreement: `jtag_tap_mbox` is c339 `TIMEOUT` and overlay `FAIL`. The other eight rows have no completed c339 run. At that collection point, the interim table had 161 unique test IDs: 103 reused rows plus 58 terminal array-1964 rows. The final row and 162-row table are recorded below.

## Final row and complete table

Array task 1964_54 completed `smoke_test_mbox_cg` (`79b6f2f02c78683d`) with firmware build exit 0 and overlay `FAIL` at the testbench 20,000,000-cycle assertion (`caliptra_top_tb_services.sv:2408`). The simulation ran 13,896.044 seconds (13,898.583 seconds total); there is no final mcycle or firmware PASS marker, and c339 is `UNVERIFIED`. The terminal result and all raw logs have a verified checksum manifest in [`final-row-1964_54/raw/`](final-row-1964_54/raw/).

The final table has 162 unique rows with outcomes 84 `PASS`, 63 `FAIL`, 14 `FIRMWARE_BUILD_FAIL`, and one `TIMEOUT`; see [`final-162-results.tsv`](final-162-results.tsv). No M11 tasks remain queued or running. Cause memberships and all 32 terminal c339 disagreements are in [`../cause-groups.md`](../cause-groups.md).
