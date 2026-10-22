# M10 assertion-enabled Verilator rerun

## Official 103-row run

The pinned Verilator 5.052 top model was built with `--assert` and `+define+CLP_ASSERT_ON`, matching the Icarus assertion enables (`-gassertions -D CLP_ASSERT_ON`). Its executable SHA-256 is `f99ad2b3b30fdf9d33435feff9d7f382d9db82f6949e55737b52331cf34aaae8`. Array 1630 ran the 103 M9 PASS rows, including all six exact M8 test/YAML matches. Results are in [array-1630-results.tsv](array-1630-results.tsv), with raw bundles in [array-evidence-1630.tar.gz](array-evidence-1630.tar.gz).

Reproduction inputs are [the 103-row selection](run-selection.tsv), [the six M8 matches](m8-matches.tsv), [the build script](build-model-overlay.sbatch), [the array script](run-array-overlay.sbatch), [the filelist helper](prepare-verilator-filelist.py), and [the pinned input manifest](input-manifest-overlay.txt). Version, model hash, resource use, filelist manifest, and build log are in [build-evidence-overlay](build-evidence-overlay/).

All 103 rows stopped before a firmware result marker: 102 at `AXI_SUB_AW_HSHAKE_ERR`, and `smoke_test_dma_aes_kv_large` at `SS_STRAP_KEY_SIZE_LTE_64`. No row reached final mcycle, so all `speedup_vs_c339` entries are `NA`; this run provides no performance comparison.

## Assertion findings

The common AW failure is a real sampled handshake violation in the pinned Caliptra testbench BFM, not a Verilator assertion false positive. The `smoke_test_sha256` diagnostic sampled AWVALID=1/AWREADY=0, followed by AWVALID=0/AWREADY=0 while reset stayed high. In pinned `axi_if.sv` (`axi_if.axi_write`), the Verilator branch uses blocking assignments plus a 100 ps alignment delay, then checks `awready` after `@(posedge clk)`. The driver can therefore observe a post-edge ready value that was low when the assertion sampled the edge. The source trace and hash are in [diagnostics/aw-handshake](diagnostics/aw-handshake/). A diagnostic-only build with just the AW check isolated then hit `AXI_SUB_W_HSHAKE_ERR` on the same initial fuse write; no separate sampled W trace was collected.

The remaining row selects `+STRAP_SS_KEY_RELEASE_KEY_SIZE_RAND_HIGH`; the run generated `0x63ec`, beyond the asserted `0x40` limit. This is a test configuration / assertion mismatch, not a simulator defect.

Two focused diagnostic-only runs isolated the common AW and W checks without changing firmware or pass classification. Both reached the same target assertion as assertion-enabled Icarus, using the same YAML and firmware images:

- `pv_hash_zeroize`: Icarus and Verilator both fire `ERR_SHA_BLOCK_NOT_STABLE`. The Verilator signal trace shows `block_reg` changing from zero to a nonzero word while `gen_hash_ip=1`. Pinned `sha512.sv` writes `block_reg` from `gen_hash_block_write_data` during that operation, while the assertion requires stability whenever the engine is not ready. The assertion guard includes a legitimate in-flight PCR block load; this is an overbroad RTL assertion window, not a simulator defect.
- `smoke_test_ecc_errortrigger2`: Icarus and Verilator both fire `ERR_ECC_PRIVKEY_NOT_STABLE`. The trace shows `privkey_reg` changing from zero to the injected key on the first busy sample (`dsa_busy=1`) after the test injects the key into KeyVault and starts PCR signing. The RTL assertion begins checking as soon as ECC is busy, so it covers the initial key capture; this is an overbroad RTL assertion window, not a simulator defect.

The matching Icarus/Verilator case YAML and firmware-image hashes, signal traces, model hashes, resources, and logs are retained in [array-diagnostic-after-aw-w-1743.tar.gz](array-diagnostic-after-aw-w-1743.tar.gz) and [array-diagnostic-target-events-1755.tar.gz](array-diagnostic-target-events-1755.tar.gz). The separate [AW-only diagnostic archive](array-diagnostic-after-aw-1740.tar.gz) records the next write-data handshake failure. The official array results remain unchanged by these diagnostic builds.

No simulator defect was found, so no simulator issue was filed. M9 scope remains the 162 stock-firmware rows; its 109 authored/generated-UVMF rows are `NOT_RUN_NON_FIRMWARE` and UVM benches stay on Icarus. M9's DMA word-15 and mailbox-lock findings are in [root-causes.md](../caliptra-bfm-verilator-m9-20261016/root-causes.md), and its 43 FAIL classifications are in [failure-groups.md](failure-groups.md).
