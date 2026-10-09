# Caliptra full-top AES/DMA BFM diagnostic — 2026-10-09

The guarded full-top runner passed the first short AES/DMA firmware vector
with the native Caliptra AXI checker enabled. Compilation and simulation
exited 0, the log has one `TESTCASE PASSED`, no failure or checker markers,
and a normal finish. The expected sandbox JTAG listener bind denial was
classified separately; the runner reported no JTAG server errors.

The trace recorded source AW/W/B at cycles 1348/1349/1351 and AR/R at
2907/2909, then destination AW/W/B at 2995/2996/2998 and readback AR/R at
3146/3148. Totals were two handshakes on each AXI channel. Firmware finished
at `minstret=1429`, `mcycle=3663`; the simulator finished at cycle 3802.

This is a diagnostic integration result: it uses one AES/DMA vector, fast
physical-TRNG cadence, verified `.data`/`.bss` preload, and skipped unrelated
post-quantum vector generation. It does not qualify stock firmware, the full
suite, or general AXI signoff.

## Command

```sh
env \
  CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  CALIPTRA_BFM_PROFILE=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/src/integration/config/caliptra_top_tb.vf \
  CALIPTRA_JTAGDPI_VPI=/private/tmp/caliptra-jtag-vpi-197f9ba/jtagdpi.vpi \
  CALIPTRA_GCC_PREFIX=/private/tmp/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-main-197f9ba.lhBG3v/install/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-main-197f9ba.lhBG3v/install/bin/vvp \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh \
  --case smoke_test_dma_aes_gcm_short_1_dword \
  --output /private/tmp/qd-bfm-top-main-197f9ba \
  --fast-trng --first-aes-case-diagnostic --trace-axi
```

## Revisions and fingerprints

- QD BFM source revision: `af3ee3f31b2d011ac3153a407e92cbf3fa454fc3`.
- Caliptra source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source archive: clean archive of locally available `origin/main`
  `197f9baece79e66d25524906fb7b54c9faa8f4e2`; UVM submodule
  `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. GitHub DNS resolution failed,
  so a newer remote head could not be confirmed.
- `iverilog` SHA-256:
  `2588169190d99543c79d8a8c58ff3e75f7e0a9679fa871e895e5c3f15af29ba5`.
- `vvp` SHA-256:
  `edbc97b6a9fec8d1425c16d0b1a6b32ad4cbdb0ad609dbfbca155cbc30eb5c6d`.
- JTAG VPI SHA-256:
  `1ff7ec3a466a6fac8afe2599b1b5c1901ad91bde48172423b1edb5470125f5fd`.
- Runner shell SHA-256:
  `046f05c732bba3fdc6a6b1e82acf4cc0910ffc657e9aebe2ff2a4ce4c101b741`.
- Runner Python SHA-256:
  `ec326729e62cc20c179d8608cb2b18ffcd9c907176b560393e83306a007d5b77`.
- Result JSON SHA-256:
  `d58bb6d78171b0b5c0bb396597ba56a6d7f04c750b81571840b8f5758413cb09`.
- Uncompressed compile-log SHA-256:
  `20fd0c144774ecc53b436103989c6f7651a2f63c9dbe16c0854f3b6f54f4d669`.
- Uncompressed simulation-log SHA-256:
  `80df4b21b6288568fe67fa0f69dd2385385fc7be6080281d11695e5d45204873`.

The complete run summary and compressed logs are retained as
[`result.json`](result.json), [`compile.log.gz`](compile.log.gz), and
[`sim.log.gz`](sim.log.gz).
