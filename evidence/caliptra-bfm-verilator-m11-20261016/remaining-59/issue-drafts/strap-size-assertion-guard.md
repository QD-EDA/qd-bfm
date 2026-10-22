# Draft: high strap-size test leaves the size-limit assertion enabled in Verilator

**Status:** Local draft for user review only; not posted.

The `smoke_test_dma_aes_kv_large` case passes `+STRAP_SS_KEY_RELEASE_KEY_SIZE_RAND_HIGH`, which intentionally chooses a DWORD-aligned value greater than `0x40`. In `caliptra_top_tb_soc_bfm.sv`, that plusarg disables `SS_STRAP_KEY_SIZE_LTE_64` only under `CLP_ASSERT_ON && !VERILATOR`. The RTL assertion in `soc_ifc_top.sv` still requires the strap size to be at most `0x40`; therefore assertion-enabled Verilator terminates this row at simulation time 3,000, before firmware runs.

This is a testbench assertion-guard portability issue. The row is `smoke_test_dma_aes_kv` (`5fd86f6ad2b1e78a`) from the `smoke_test_dma_aes_kv_large.yml` case; c339 has no completed baseline for this row. The verified result is in [collection 01](../completed-1964-01.tar.gz), and the case YAML and assertion source are in the pinned Caliptra RTL at commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

The intended correction should preserve the high-range test while disabling or adapting the limit assertion for this deliberately invalid strap case across simulators.

M12 one-row gate: build-time SoC BFM overlay `evidence/caliptra-bfm-verilator-m12-20261017/strap-guard/` removes only the `ifndef VERILATOR` fence around the existing assertion suppression. Row `5fd86f6ad2b1e78a` passed with assertions enabled and the high-size selection intact (`TESTCASE PASSED`, mcycle 60,405); the gate took 42.14 s. This row is the full affected set. The evidence is local and the draft has not been posted.
