# Caliptra short AES/DMA toolchain replay — 2026-10-08

**Status: diagnostic integration result; not qualification.** The short AES/DMA
first vector passed in the full Caliptra top using the open AXI target and
`CALIPTRA_BFM_CHECKER`. The run emitted one testcase pass marker, no fail
markers or bad diagnostics, and exited normally.

## Why this unblocked the run

The host's existing `/opt/riscv` GCC is an x86_64 binary whose Intel Homebrew
dependencies under `/usr/local/opt` are missing. The compiler driver fails
before firmware compilation can complete. Setting `CALIPTRA_GCC_PREFIX` to a
self-contained native ARM64 xPack RISC-V toolchain fixed firmware compilation;
the Caliptra Makefile built the actual test firmware and the top-level test
passed without a BFM or runner source change. The archived xPack GCC 15.2.0-1
package SHA-256 was
`6588e8351455fad8aca37551f0e5a5543f3346bfa9a837cf03cbd3bdd4989f8f`.

The runner invocation was:

```sh
CALIPTRA_GCC_PREFIX=/path/to/xpack/bin/riscv-none-elf \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh \
    --case smoke_test_dma_aes_gcm_short_1_dword \
    --output <new-output-directory> \
    --fast-trng --first-aes-case-diagnostic --trace-axi
```

`--first-aes-case-diagnostic` uses a one-vector firmware copy and automatically
enables the verified `.data`/`.bss` preload (CRT0 copy/clear loops are skipped).
It also uses fast TRNG cadence, quiet firmware output, and skips unrelated
MLDSA/ML-KEM vector generation. These changes make this a diagnostic, not a
stock-firmware or 12-vector qualification run.

## Result and provenance

- Firmware build, top compile, and simulation exits: 0.
- Firmware pass markers: 1; fail markers: 0; bad diagnostics: 0.
- Firmware finish: `minstret=1429`, `mcycle=3663`.
- AXI handshakes: payload AW/W/B at cycles 1,348–1,351; payload AR/R at
  2,907–2,909; destination AW/W/B at 2,995–2,998; destination AR/R at
  3,146–3,148.
- BFM checker: enabled.
- Guard: exit 0; minimum available memory 7.78 GiB; maximum process-group
  footprint 1.45 GiB.
- QD runner/BFM source: `77687ded657c4d06434af31262dfa619c3779cbf`.
- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source: `ac4532fab037e91df2f903e67fb40f59baedccca`, dirty and
  unpublished (`ac4532fa-dirty`); this cannot qualify the result.
- Icarus/VVP executable SHA-256 values and exact commands are in
  [`result.json`](result.json). The compile and simulation logs, plus the
  byte-preserved compressed firmware build log, are retained beside it.
- Simulation log SHA-256:
  `8b1fd204952f16250fb7c7dbdae3bdbfe97e23604991453039a8db4f175d541b`.

A clean, published Icarus replay is still required before any qualification
claim.
