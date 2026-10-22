# SHA512 block-clear edge trace attempt 2

This focused diagnostic follows the inconclusive event trace in attempt 1. It arms on `zeroize_reg`, records up to 64 clock edges, and logs block-register transitions and their hardware-clear/write controls. The bounded monitor is read-only: firmware, assertions, pass classification, and operational RTL are unchanged. It retains the M10b AXI handshake overlay.

Row 91 is `smoke_test_sha512` (test ID `7acba2db04d9935d`): c339 PASS versus Verilator FAIL at `ERR_SHA_BLOCK_NOT_STABLE` near 6.296 us. The first edge-trace attempt reproduced the assertion but emitted no monitor lines because its absolute `$time` output filter never matched; that attempt and its archive are preserved in [`../sha512-assert-edge-trace-20261016-02/README.md`](../sha512-assert-edge-trace-20261016-02/README.md).

Pinned Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
Pinned SHA512 source SHA-256: `5656d5a09d1570a567bb674b1b419775a83a08b37ee70792d28ab72ae0510d82`.
M10b AXI overlay SHA-256: `d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`.
Source testbench repository commit: `cc257387205f8410a1806f161afcadcd2c4a360a`.

## Run evidence

Build job 1953 passed with Verilator 5.052, `--assert`, and `CLP_ASSERT_ON`; elapsed time was 3:28.27, peak RSS 2,381,480 KiB, model SHA-256 `5b5ed06f7a20145713eb95808bb976274e99c33d5f34a7b0709328aa4d22431c`. Its read-only trace overlay SHA-256 is `f0c23bfddf20aada206cc0afbbaa59864e85164d9c3bc7b6277acf5aeee56938`.

Simulation job 1954 used DAN-DESKTOP, Verilator 5.052, riscv-none-elf-gcc 15.2.0, Python 3.12.15, and a 600-second wrapper cap. It reproduced the assertion in 40.00 seconds (42.196 seconds total runner time), peak RSS 27,868 KiB. The ordered `M10_SHA_*` records show software ZEROIZE asserting the SHA block hardware clear, followed by block zeroization and `ready_reg` dropping in the same reported time slot as the assertion. The result remains FAIL at the assertion; it does not have a final `mcycle`. The detailed, source-checked finding is in [`root-cause.md`](root-cause.md).

The archived run is `trace-run-1954-sha512-zeroize.tar.gz`, SHA-256 `f7a1caf35bd44fec135effc588fc87cec28c122a98f0929ab18935b18931b3c0`. The archive includes the simulation/build logs, result JSON, resource reports, filelist manifest, model hash, and the exact diagnostic SHA512/AXI overlay files. The result's `FILE-SHA256SUMS` and the local archive checksum both passed. The testbench input snapshot is `source-snapshot.tar.gz`, from clean repository commit `cc257387205f8410a1806f161afcadcd2c4a360a`, SHA-256 recorded in `source-snapshot.sha256`. After verification, the remote run directory was deleted, freeing 729,172,675 bytes.
