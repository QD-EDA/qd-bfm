# Caliptra default mixed DMA replay on local `iverilog-uvm` main — 2026-10-09

The guarded `--default-mixed-replay-only` run passed all 25 seeded records
through Caliptra's actual `axi_dma_top`. The runner verified coverage of all
five DMA routes and the FIFO, fixed-burst, randomized-delay, and recovery
block profiles. Each completed run reported zero UVM warnings, errors, and
fatals. The exact captured output is compressed in [`run.log.gz`](run.log.gz);
the uncompressed log SHA-256 is
`df40087dd67e5923bec45bc951003c7efa2c92f59d85261de7bddc183a67270e`.

The run used the clean source archive for the newest locally available
`dsellerbrock/iverilog-uvm` `origin/main` reference,
`197f9baece79e66d25524906fb7b54c9faa8f4e2`, with UVM submodule
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. GitHub DNS resolution failed, so
this SHA could not be confirmed as the current remote head. Caliptra RTL was
pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

## Command

```sh
env \
  CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-main-197f9ba.lhBG3v/install/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-main-197f9ba.lhBG3v/install/bin/vvp \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --default-mixed-replay-only
```

## Fingerprints

| Input | SHA-256 or revision |
| --- | --- |
| Icarus source | `197f9baece79e66d25524906fb7b54c9faa8f4e2` |
| UVM submodule | `78c06547a2a0a29b3dc9dcafae62b75b2ff61544` |
| `iverilog` | `2588169190d99543c79d8a8c58ff3e75f7e0a9679fa871e895e5c3f15af29ba5` |
| `vvp` | `edbc97b6a9fec8d1425c16d0b1a6b32ad4cbdb0ad609dbfbca155cbc30eb5c6d` |
| Runner | `de2a0710d264d0a3c58435e81dac78aab9d073e4fd09754668c0c3e1ed69a2d5` |
| Testbench | `c37cc6439091575cd8b4db9416754f3efcfb8dbf25b893938b0d60b421b49a3a` |
| Generator overlay | `34baac88fd62405b800f3f5e2ee00399a2b6b32f98ce168fe6b4d873e6a4c2be` |
| Uncompressed captured log | `df40087dd67e5923bec45bc951003c7efa2c92f59d85261de7bddc183a67270e` |
