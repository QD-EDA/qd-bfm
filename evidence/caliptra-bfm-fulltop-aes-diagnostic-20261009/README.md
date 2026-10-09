# Published Caliptra full-top AES diagnostic

Date: 2026-10-09

Command: sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh --case smoke_test_dma_aes_gcm_short_1_dword --fast-trng --first-aes-case-diagnostic

The retained full-top firmware runner passed one selected AES-DMA smoke case.
It ran with the Caliptra BFM checker enabled and exited normally:

- Case: smoke_test_dma_aes_gcm_short_1_dword
- Result: simulation exit 0, one testcase pass marker, zero fail markers
- Caliptra source: clean commit 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
- Icarus source: clean published commit 127b887dfdc09283ab0187a2e618421dee3d5dcc
- Runner modes: fast TRNG, fast boot-data preload, first AES case only, PQ vector generation skipped
- The JTAG DPI listener logged one sandbox bind denial; there were no JTAG server errors and the test did not require a client.

This is a diagnostic pass for one intentionally narrowed firmware case. It is not
stock-firmware, full regression, generated-UVMF, or full-profile qualification.
The source and binary details, command vectors, input hashes, and run summary are
preserved in results.json; the simulation log is preserved in sim.log.

## Recompiled and rerun on published main — 2026-10-09

The same full-top RTL and one-case AES/DMA scenario compiled and ran on the
newest locally cached published Icarus `main`,
`4b3f3424c440aca6af92153b6860a7253b925234`. The compile exited 0 with the
native Caliptra-profile AXI checker enabled. Simulation exited 0 with one
`TESTCASE PASSED`, no failure marker, and `minstret=1429`, `mcycle=3663`.

The firmware image and generated profile were reused from the earlier,
hash-verified `127b887` run because the installed RISC-V compiler's preflight
fails on a missing Intel `libisl.23.dylib`. Their hashes match the earlier
`results.json`; only the full-top compile and simulation used `4b3f342`. This
is diagnostic integration evidence, not a regenerated firmware build or a
stock-firmware qualification. The JTAG DPI plugin was rebuilt from the pinned
Caliptra sources with `4b3f342`'s `iverilog-vpi`.

The current simulator run log is `sim-published-main-4b3f342.log`; the exact
commands and fingerprints are in `results-published-main-4b3f342.json`.
