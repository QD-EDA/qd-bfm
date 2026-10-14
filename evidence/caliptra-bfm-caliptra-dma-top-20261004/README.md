> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra `axi_dma_top` BFM integration — 2026-10-04

## Scope

This focused test instantiates the pinned Caliptra `axi_dma_top` at the
48-bit-address, 32-bit-data/USER, 5-bit-ID profile. It includes the actual
generated DMA register block, control FSM, AXI read/write managers, and
Caliptra `axi_if`. The AXI ports connect to the clean-room
`axi4_caliptra_dma_if_subordinate`; its completed transactions pass through the
pin monitor and a passive native UVM agent.

The runner compiles Caliptra's Apache-2.0 `caliptra_top_tb_pkg` and its
`dma_transfer_randomizer` class. It creates a temporary compatibility copy of
that class changing only `$fatal("...")` to `$fatal(1, "...")`, which this
Icarus build requires at runtime; pinned Caliptra files remain unchanged. With
seed `0x00c0ffee`, the randomizer produced an AXI-to-AXI 65-word transfer with
source `0x0001_2344_0308`, destination `0x0001_2344_06d0`, and randomized
payload. The test programs byte count 260, block size 0, and `CTRL=0x0303_0001`
through the real `axi_dma_top` component request interface. That route pair
selects the external AXI read path into the DMA FIFO and the external AXI write
path out of it.

Caliptra limits each DMA request to the remainder of its current 256-byte
window. The successful run checks source reads split 62+3 beats and destination
writes split 12+53 beats, including IDs, USER, WSTRB, responses, LAST, payload,
destination SRAM contents, and idle/error status. A second run injects AXI
`SLVERR`; the actual DMA reports `DMA_ERROR` after a 62-beat read and 12-beat
write, and the monitor checks both error responses. The test verifies that
those first 12 destination words match the payload and the remaining 53 words
stay untouched.

This is an `axi_dma_top` block-level counterparty smoke. It does not run
Caliptra firmware, the full SoC/top testbench, generated UVMF, Avery, QVIP, or
ARM Axi4PC. The only direct memory access is the testbench's seed and final
inspection of the BFM's modeled SRAM; Caliptra DMA performs the copy over AXI.

## Inputs and toolchain

- Caliptra v2.1.2: commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; the pinned
  checkout was clean and unmodified.
- Icarus/VVP source revision:
  `246c58e4580f38a130ec08e5a7e6d93f110a5084`.
- Simulator: Icarus Verilog/VVP 13.0 devel, build `246c58e4-dirty`.
- UVM: Accellera 1800.2 UVM 2020.3.1, bundled with the selected Icarus build.
- `iverilog` SHA-256: `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392`.
- `vvp` SHA-256: `b7e9e2d0b994bdd5e17a2e8033dfe76ca9fafb9ec9fdca35f16a9d1b63c9cba9`.
- The runner uses `-DXCELIUM` for the optional `axi_if` helper-task branch;
  Caliptra assertion macros remain enabled (no `SYNTHESIS` or `VERILATOR`).

## Reproduction and result

Run from this clone's root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

The runner executes a successful transfer and a separate injected-error case;
both exited 0 and printed:

```text
INFO: Caliptra DMA randomizer seed=00c0ffee size=65 src=000123440308 dst=0001234406d0
PASS: actual Caliptra axi_dma_top copied 65 randomized payload words in boundary-limited INCR bursts through the open DMA target and UVM monitor
INFO: Caliptra DMA randomizer seed=00c0ffee size=65 src=000123440308 dst=0001234406d0
PASS: actual Caliptra axi_dma_top propagated injected AXI SLVERR to DMA_ERROR after the aligned partial write
```

Each UVM summary reported 0 warnings, 0 errors, and 0 fatals. Icarus printed a
warning that Caliptra's `randomize()` method is called as a task, a
mixed-timescale warning, and a generated DPI export note. The runner removes
its temporary compatibility copy, executable, and log.

## Source hashes

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh` | `d43eda18e5ab5b8a594c35ce48b6f4275f3b4666a51ea091df7d4d6e6e0004ec` |
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_dma_top_uvm_bfm.sv` | `1b1bcd929df9167ca9117e6c942dee591b3332a4be5b9eaa8932e103cf441a2d` |
| `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f` | `3692ba45254bf856a87a8f6ac33c0517e97c7cd17a965f9fc36931f7b209a9e8` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_uvm_pkg.sv` | `8a09f371b68098b044e0c4282fa0131852b090cfd83cb5c55fa9e72cbe604a2b` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_record_if.sv` | `29520c4b28a47feaf60925b240f41b53012ef771e1ebbc6d53eea3ef152f248a` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv` | `28bbc17e1079f44d808599642a7317d1248b43fc1ba5e2a3ee067655aa005f58` |
| `dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv` | `3ef2180e298d7798c3b2caa5ac31587f623a817983075ef7556a5071f1f5b029` |
| `dv/caliptra_bfm/axi/axi4_caliptra_dma_subordinate.sv` | `d9eae8af43b2aedafbdb254afb3400120bd2e58176321b48b7aad17e1e96f34a` |
| `dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv` | `f151401a77219d5feb6808c56ff5e6bc10dfa7bdf3e07ca14c3e0cbd26b8109f` |
| `dv/caliptra_bfm/axi/axi4_caliptra_fifo_subordinate.sv` | `49416a58859e4664be14850e9f118191194d480a43d6459cc9842ceb7087fbf3` |
| `dv/caliptra_bfm/axi/axi4_caliptra_recovery_sequence.sv` | `49e9c8b74b1b74ffa41237ba180ff518971eb2799a693d816074b4d7d1250adf` |
| `dv/caliptra_bfm/axi/axi4_caliptra_recovery_avail.sv` | `ca4a3dadfc06c550722f489a40832fbfd6a8364cdcecb3816e363fc130476c8b` |
| `dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv` | `a14885494870c930551028cb681a7b2b51d0724780a48d77012c2ab0824a87b8` |
| Caliptra `src/caliptra_prim/rtl/caliptra_prim_util_pkg.sv` | `60daeb9bde8f8499c326809d03c6bcfc0d318442fd3bc81d84a915bf733fa0c2` |
| Caliptra `src/axi/rtl/axi_pkg.sv` | `07991843e3a2b77e6aae9c6903ae8ff08927ddbb517d83a23f96abd89be3af29` |
| Caliptra `src/axi/rtl/axi_if.sv` | `e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c` |
| Caliptra `src/axi/rtl/axi_dma_req_if.sv` | `ada340cb05a7da60444701ab6230d13be035724b082759b889b815f42eff9cf8` |
| Caliptra `src/axi/rtl/axi_dma_reg_pkg.sv` | `ffc32502b37813a0d609fe1b9afee7433ad5aeeb049b3f031f40355926a2d1d6` |
| Caliptra `src/axi/rtl/axi_dma_reg.sv` | `864d1fe1696872864903ea0f3448d9375607af7ddcddde23e8ecb54686a0da99` |
| Caliptra `src/axi/rtl/axi_dma_ctrl.sv` | `a7a1b7038b53505d85982bb03206b2729910ec56ef501d7326094bd976204fad` |
| Caliptra `src/axi/rtl/axi_dma_top.sv` | `caf763bd878eb4d03df01d528bf30da45280ae5df986384a0554a101adf9c0b1` |
| Caliptra `src/axi/rtl/axi_mgr_rd.sv` | `ea020134f12c9bdfa9068b3e3431b5dad340da667234c8776bc272ccf957f01f` |
| Caliptra `src/axi/rtl/axi_mgr_wr.sv` | `8b0d4c52996f1b19bb21a53c0d9103df853dccb0ddf10708a92c489d8b0bc157` |
| Caliptra `src/libs/rtl/skidbuffer.v` | `ae4f49f18e1b635f6c8454abee5f1762e483ea21480f89e131102d35b5d8a523` |
| Caliptra `src/soc_ifc/rtl/soc_ifc_pkg.sv` | `dd3c667d985e7cc26110e18abcc3b106a426ce5cc4e60bd5c886f1032edd4433` |
| Caliptra `src/integration/tb/caliptra_top_tb_pkg.sv` | `f4a46ecd06d0dd3dc333fe7f9d58d4813c8a0c2efa0ea5cde2534f0de4702425` |
| Caliptra `src/integration/tb/dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Caliptra `src/integration/rtl/config_defines.svh` | `eca39a996de31dd717a5d45327ccb5343c3e33178898495362a55d1fb5967c38` |
| Caliptra `src/integration/rtl/caliptra_reg/caliptra_reg_defines.svh` | `732ebd6cf41678011b0584da2289c035bcc88e6404a021190b15c2ebfae4b96f` |
| Caliptra `src/integration/rtl/caliptra_reg/caliptra_reg_field_defines.svh` | `24717b633f63c0907d8fcc209621e45356fc1469436c19c82f862bfa173681c6` |
| Caliptra `src/keyvault/rtl/kv_defines_pkg.sv` | `3f56086b198367cc2573ad8f0dc5d57d24706f10aba838868c41de9ece845216` |
| Caliptra `src/caliptra_prim/rtl/caliptra_prim_fifo_sync_cnt.sv` | `e9f28201d841d7208274c7efcdab8eb18c4317487635933b6151dab73d4fb008` |
| Caliptra `src/caliptra_prim/rtl/caliptra_prim_fifo_sync.sv` | `5b882ca84173e887c8103aa9faddb3fa4bd267186cda4b237cb57c93f8f4bd24` |
| Caliptra `src/keyvault/rtl/kv_fsm.sv` | `9331536a98baeac2be428241e6b405867b75db24b14a968e7f59b432ec7719e4` |
| Caliptra `src/keyvault/rtl/kv_read_rule_check.sv` | `4a3f14cf4aeb5b6e69f8353dee4e998e672a213cf65e72e82cf7a287ef470afe` |
| Caliptra `src/keyvault/rtl/kv_read_client.sv` | `dbc90eaa6c654b89c4e2b762bc84d18a9ee43b78a38ad9fd0b5220c366d2872c` |
