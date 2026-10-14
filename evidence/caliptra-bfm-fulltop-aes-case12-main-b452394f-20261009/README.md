# Caliptra full-top AES/DMA case 12 — 2026-10-09

The guarded firmware run passed AES/DMA case 12, the final and widest entry in
the short AES/DMA vector table, through the Caliptra top with the open AXI
target and native checker enabled. The run emitted one `TESTCASE PASSED`, no
failure or checker diagnostics, and a normal `$finish`. AXI totals were four
AW/B transactions, 24 accepted W beats, and 24 accepted R beats across two AR
requests. The first source transfer contained 12 W beats; the source read
returned 12 beats. The run finished at `minstret=1840`, `mcycle=5137`, simulator
cycle 5276.

This is a targeted integration diagnostic, not stock-firmware or full-suite
qualification. It uses fast physical-TRNG cadence, a verified `.data`/`.bss`
preload, and skips unrelated post-quantum vector generation. The expected
sandbox JTAG listener bind denial was classified separately; no JTAG server
error was reported.

## Command

```sh
env \
  CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  CALIPTRA_BFM_PROFILE=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/src/integration/config/caliptra_top_tb.vf \
  CALIPTRA_JTAGDPI_VPI=/private/tmp/caliptra-jtag-vpi-197f9ba/jtagdpi.vpi \
  CALIPTRA_GCC_PREFIX=/private/tmp/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-b452394f/install/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-origin-main-b452394f/install/bin/vvp \
  IVERILOG_VPI_BIN=/private/tmp/iverilog-uvm-origin-main-b452394f/install/bin/iverilog-vpi \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh \
    --case smoke_test_dma_aes_gcm_short_1_dword \
    --limit-aes-cases 1 --start-aes-case 11 \
    --fast-trng --trace-axi \
    --output /private/tmp/qd-bfm-fulltop-aes-case12-b452394f-20261009
```

## Revisions and fingerprints

- QD BFM source revision: `93edc2a564410d248bf029faf57f379ecdf72827`.
- Caliptra source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source: clean archive of the locally recorded `origin/main` SHA
  `b452394f148af5a5bcfa744e615f4681d6b80e5e`; bundled UVM submodule pin
  `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. A fresh remote-head check was
  unavailable because GitHub DNS resolution failed, so this records the latest
  locally available published ref, not a live-verified remote head.
- Build used Icarus 13.0 (devel), Bison 3.8.2, Homebrew libffi/Z3, and
  `--enable-libveriuser`. Autoconf stalled at `autom4te`; the temporary source
  archive reused the generated `configure` and gperf outputs from the clean
  `197f9ba` source build because `configure.ac`, its `m4` inputs, and both
  gperf inputs are unchanged between those revisions. No Icarus checkout or
  branch was modified.
- `iverilog` SHA-256:
  `211d47b1fec6835477ad0e6f0e8b5822e9d1dd0bf806308c0d01956d96ed5e80`.
- `vvp` SHA-256:
  `55b26201cee80bab131a44d23686d4b08c153159df5a1d81a6db7b7541e00b02`.
- `iverilog-vpi` SHA-256:
  `7d748beb1b3150b266e244418f7ffb4ecb7218f78e8b5aa4a76a0cf32df65f81`.
- JTAG VPI SHA-256:
  `1ff7ec3a466a6fac8afe2599b1b5c1901ad91bde48172423b1edb5470125f5fd`.
- Runner result: compile/firmware/simulation exit 0; pass markers 1, fail
  markers 0, bad diagnostics 0, JTAG server errors 0; one sandbox bind denial.
- `result.json` SHA-256:
  `f92c73fa293ed127c8e1b54b7a026c5b5268040596b8723be5271ef4723d5766`.
- `compile.log` SHA-256:
  `13b215eddb37186842afd700c46fe9e0b7816d69b281d22756b786143516fcba`.
- `sim.log` SHA-256:
  `a9b3391ffdd164891c7193a13bff231a8bc535c8500fe19aaf4ab140409c5acf`.

See [`result.json`](result.json), [`compile.log.gz`](compile.log.gz), and
[`sim.log.gz`](sim.log.gz) for the complete run record. The 351 MiB compiled
simulation image and firmware build products remain outside the repository.
