# AR overlay v2 build and one-row gate

Pinned Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
Pinned `axi_if.sv` SHA-256: `e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c`.
Generated overlay SHA-256: `d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`.

The v2 change adds the AR channel to the existing AW/W/B handshake fix. Its only RTL source edit is the Verilator BFM's `axi_read` AR drive/wait/cleanup block and matching local macros; the R channel, firmware, RTL, assertions, and pass criteria are unchanged. The generator rejects any source SHA or exact-block count mismatch. Regenerating from the pinned file reproduced the candidate byte-for-byte. The diff from v1 contains only AR macros, AR task operations, and their `undef` entries.

## Build job 1833

- Host: DAN-DESKTOP; Verilator 5.052 (`v5.052`, 2026-09-05); riscv-none-elf-gcc 15.2.0; Python 3.12.15.
- Assertion-enabled build passed (`--assert`, `CLP_ASSERT_ON`); elapsed 3:25.76; peak RSS 2,381,356 KiB; model SHA-256 `2fd1bdfde761a04ea5905384badcb3a927677545e383368a42c77f978d6659a3`.
- Complete build command, filelist manifest, resource report, and Slurm log are in `probe-1834-evidence.tar.gz`.

## Probe job 1834

- Row: `smoke_test_ahb_mux` (`cadf43c78de6a454`), pinned Icarus outcome PASS with `mcycle=3973`.
- The wrapper enforced a 600-second outer cap; the simulation returned **PASS** in 2.788 seconds, with `firmware_exit=0` and `mcycle=3973`. Total job resource time was 5.08 seconds and peak RSS was 55,428 KiB.
- Runtime host and exact tool versions are in `probe-environment-1834.txt` inside the archive; all per-result checksums verified.
- The first-fuse-write AW/W/B trace remains the traced job 1812 evidence in `../run-1812/`: it shows AW address `0x30200`, the W beat, and the B handshake. The v2 diff leaves AW/W/B code unchanged from the traced and passing v1 candidate.

Array 1816 had previously exposed `AXI_SUB_AR_HSHAKE_ERR` in two rows at 32 ns. This passing v2 probe clears the one-row gate; the full 103-row array may now run with the same v2 model and a six-task throttle.

## Full array 1835

After the probe PASS was verified and its checksums were recorded, array `1835[0-102]` was submitted. The initial snapshot showed six rows running and the remaining rows queued at `%6`; each requests 1 CPU and 3 GiB with a 7-hour Slurm limit. Submission details and the exact selection/model hashes are in `array-submission-1835.txt`.

Array 1835 completed all 103 rows. The final table has 84 overlay PASS and 19 FAIL; c339 outcomes are 18 PASS, 25 TIMEOUT, 58 UNVERIFIED, and 2 FAIL. Seventeen rows passing on both simulators have measured speedups of 180.703x–257.722x; the 11 shared-pass rows with c339 mcycle data have matching final mcycle values. The only c339 PASS / Verilator FAIL is row 91, `smoke_test_sha512`. The [verified trace](../../sha512-assert-edge-trace-20261016-03/root-cause.md) shows software ZEROIZE asserting `SHA512_BLOCK[*].BLOCK.hwclr` as `ready_reg` falls; the assertion guard omits a ZEROIZE exception, so Verilator reports `ERR_SHA_BLOCK_NOT_STABLE` during this legitimate clear. The full result set is in array-1835/partial-results.tsv and the verified archives completed-1835-01.tar.gz through completed-1835-07.tar.gz.
