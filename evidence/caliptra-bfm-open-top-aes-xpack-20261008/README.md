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

## First two vectors in one simulator execution — 2026-10-08

The one-case run above was followed by a single top-level execution of vectors
1 and 2 (`--limit-aes-cases 2 --start-aes-case 0`). Both completed through the
same BFM and checker instance. The test emitted one overall pass marker, no
fail markers or bad diagnostics, and finished at `minstret=2872`,
`mcycle=7279`.

| Vector | AXI source transfer | AXI source readback | AXI destination transfer | AXI destination readback |
| ---: | --- | --- | --- | --- |
| 1 (one beat) | AW/W/B 1,475–1,478 at `0x123440000` | AR/R 2,940–2,942 | AW/W/B 3,028–3,031 at `0x123460000` | AR/R 3,154–3,156 |
| 2 (two beats) | AW/W/B 5,071–5,075 at `0x123440000` | AR/R 6,510–6,514 | AW/W/B 6,600–6,604 at `0x123460000` | AR/R 6,722–6,726 |

The two-beat W bursts asserted `WLAST` only on the second beat. Combined
counts were AW=4, W=6, B=4, AR=4, and R=6. The guard exited 0 with a minimum
of 7.64 GiB available and maximum process-group footprint of 1.65 GiB.

This is still a diagnostic run: it uses fast TRNG cadence, the two-vector
firmware copy with fast data preload, PQ-vector suppression, and the dirty,
unpublished Icarus source SHA recorded above. The QD source revision was
`90af876124e958ae010928ac3203d3606f9599fa` (documentation-only relative to the
runner/BFM revision above). Exact provenance and retained artifacts are in
[`two-vector-result.json`](two-vector-result.json),
[`two-vector-sim.log`](two-vector-sim.log),
[`two-vector-compile.log`](two-vector-compile.log), and
[`two-vector-firmware.log.gz`](two-vector-firmware.log.gz). Simulation log
SHA-256: `3bf2f4d0e16e42699d421dc043f5266e84818dd20250c40ad9a42603e9da8791`.

## First three vectors in one simulator execution — 2026-10-08

The three-case run initially stopped at the runner's 1,800-second guard while
the third vector was still executing; its trace had no failure marker and had
not reached the third source read. Replaying the retained top image with a
2,400-second guard completed all three vectors through one BFM/checker
instance. Firmware emitted one pass marker, no fail markers or bad
diagnostics, and finished at `minstret=4333`, `mcycle=11110`. Combined AXI
counts were AW=6, W=12, B=6, AR=6, and R=12; the 1-, 2-, and 3-beat vectors
completed their readbacks. This localizes the earlier symptom to the timeout,
not a third-vector AXI failure.

This remains diagnostic: fast TRNG, verified fast boot data preload, PQ-vector
suppression, and dirty/unpublished Icarus `ac4532fa-dirty` were used. The
2,400-second run replayed the retained top image rather than compiling a new
one. Its SHA-256 is recorded in
[`three-vector-result.json`](three-vector-result.json); the image itself is
not bundled. Logs and result are in
[`three-vector-sim.log`](three-vector-sim.log),
[`three-vector-timeout-sim.log`](three-vector-timeout-sim.log),
[`three-vector-compile.log`](three-vector-compile.log),
[`three-vector-firmware.log.gz`](three-vector-firmware.log.gz), and
[`three-vector-result.json`](three-vector-result.json). A clean, published
Icarus build is still required before qualification.
