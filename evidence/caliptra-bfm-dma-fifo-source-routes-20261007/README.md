# Generated DMA FIFO-source routes — 2026-10-07

## Result

Three new 65-word, non-recovery FIFO-source profiles completed through the
pinned Caliptra `axi_dma_top` and the open AXI target/UVM monitor:

| DCCM record | Route | Destination check | Observed target stalls |
| ---: | --- | --- | ---: |
| 32 | AXI2AXI | Every SRAM destination word matched the FIFO word consumed by the DMA | 209 cycles |
| 33 | AXI2MBOX | Every mailbox request matched the consumed FIFO word and route offset | 128 cycles |
| 34 | AXI2AHB | Every component data-register read matched the consumed FIFO word | 128 cycles |

Each run required exactly 65 FIFO pushes and pops, an empty FIFO at completion,
the expected AXI transaction counts, a normal DMA idle status, and the route
payload checks above. All three UVM summaries reported zero warnings, errors,
and fatals. The compile emitted the existing Icarus `eval_object_select`
warnings from `uvmf_lite`; these did not produce UVM runtime warnings.

The memory guard reported 62% minimum free memory against a 40% floor. No
Caliptra source files were modified. The test runner removed its temporary
image and log files on exit.

## Replay

Run from the QD-EDA repository root with the pinned source and the existing
Icarus compiler/runtime binaries:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=240 \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --fifo-source-routes-only
```

The compiler/runtime were invoked as existing binaries in `BFM WORK`; this run
did not modify that checkout. The runner compiled the pinned `axi_dma_top`,
generator and randomizer with the open FIFO/SRAM target, randomized AXI stalls,
and UVM transaction monitor. Caliptra revision:
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The QD-BFM source baseline was
commit `6d6de5c62664195595dde0bbdeb0d2f672263426`.

## Source hashes

| Input | SHA-256 |
|---|---|
| Caliptra `axi_dma_top.sv` | `caf763bd878eb4d03df01d528bf30da45280ae5df986384a0554a101adf9c0b1` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Generator replay overlay | `b17353330d4667ac06f9c244c2a4a73101f1fcf471922fba00bc5b2874eb2831` |
| Open DMA AXI subordinate | `3ef2180e298d7798c3b2caa5ac31587f623a817983075ef7556a5071f1f5b029` |
| Open AXI randomized stalls | `6c828f9112d2895ea9f67d2132c157545bd2ac22a49acd2ad7736dd4b24f1924` |
| DMA/UVM testbench | `b9092bf0ab3fa1e6a203a3d169400d750b76748b2ab7d2dcb24e79afb75ae211` |
| Replay runner | `f9e2ea71487c3cb0e215acfcfec22d1778ec1de9c9327ecf2a1adc1247acaee6` |
| Icarus compiler | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |

This qualifies the three listed block-level routes. Other generated FIFO
profiles, firmware-triggered warm reset, full-top firmware traffic, and full
generated UVMF environments remain unqualified.
