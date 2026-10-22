# Firmware build comparison for the three prior build failures

Source snapshots: Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; QD-BFM `d1529c922da402943148a0fb22648f347e30eed9`. Toolchain: protected c339 firmware bundle with xPack RISC-V GCC 15.2.0; all tasks used `GCC_PREFIX=riscv-none-elf` after correcting the first attempt's harness setup.

| Case | Pinned-only | With compatibility overlay | Cause |
|---|---|---|---|
| `smoke_test_kv_ecc_flow1` | BUILD_FAIL | BUILD_PASS | Source calls `srand` without its standard declaration; the case overlay includes `<stdlib.h>`. |
| `smoke_test_kv_ecc_flow2` | BUILD_FAIL | BUILD_PASS | Same missing `srand` declaration; same narrow stdlib overlay. |
| `smoke_test_ras` | BUILD_FAIL | BUILD_PASS | `caliptra_isr.c` calls the RAS handler through assembly, but the original header's inline definition is not emitted; the overlay copy marks that handler `static inline __attribute__((used))`. |

The first 1025/1032 attempts do not represent source build outcomes: their make invocation left the upstream default `GCC_PREFIX=riscv64-unknown-elf`, while the installed compiler is `riscv-none-elf`. The Makefile stopped at its toolchain preflight. The corrected 1038 overlay array and 1107 pinned-only array both pass through the same prefix and fixed source/toolchain SHAs. The overlay changes are mechanical and already reside under `docs/conformance/release_overlays/caliptra/environment/`; no test logic or pass criterion changed.

Results for array 1107 and byte verification are in `tasks/`, `logs/`, and `sha256.txt`. Corrected overlay results are in `../firmware-build-rerun-1038/`.
