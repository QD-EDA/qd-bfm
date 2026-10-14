> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# SoC-IFC AXI/AHB BFM runtime — 2026-10-04

This focused Icarus test runs the pinned Caliptra `soc_ifc_top` RTL with its
actual `axi_dma_top`, Caliptra `axi_if`, and the clean-room
`axi4_caliptra_dma_if_subordinate`. The test programs the real DMA register
window over the DUT's AHB-Lite port, and drives the DUT's SoC-facing AXI port
with the open single-beat manager; no internal request signals are forced.
The UVM-enabled runner swaps in the generated-name `aaxi_monitor_wrapper` and
`aaxi_uvm_testbench` hierarchy so a native UVM sequence uses the same host AXI
port and observes completed pin records.

In standalone mode, the open AXI manager writes `CPTRA_MBOX_VALID_AXI_USER[0]`
to `0xcafe51f0` and locks it. The AHB manager reads the mailbox lock to claim
the mailbox, then writes CMD, DLEN, DATAIN, and EXECUTE. The configured AXI
host reads DATAOUT, and the test checks both the returned word and the stored
SRAM word before writing the completion status and releasing EXECUTE. In
UVM-enabled mode, the generated-name AAXI sequence sends four words as the SoC
host; the active QVIP-compatible AHB sequencer reads and checks them as the uC,
writes a four-word response and completion status, and the UVM host reads the
response and releases EXECUTE. The same sequencer reads the initial mailbox
lock and programs all seven DMA registers. The task-based AHB manager performs
the final DMA status read. Both flows drive the actual SoC-IFC mailbox CSR,
ECC, SRAM request, and response path.

The test seeds four words in the BFM SRAM, uses the open serialized AHB manager
to write source/destination, byte count, and GO through the DUT's AHB port, then
checks the real DMA emits one four-beat AXI read and one four-beat write at the
programmed addresses. It checks each read and write payload, response, strobe,
and final-beat marker, verifies all four destination words, then reads the DMA
status register back over AHB and confirms idle/no-error. A second run injects
`SLVERR` at the open target and verifies the actual SoC-IFC DMA remains in
`DMA_ERROR` with the corresponding AHB status bits and FSM state set. The
target uses Caliptra's 48-bit address, 32-bit data/USER, 5-bit-ID profile and
the pinned SRAM/FIFO map.

## Reproduce

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-soc-ifc-dma-runtime-20261004/run.sh

IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-soc-ifc-dma-runtime-20261004/run_uvm.sh
```

Both runners check macOS free memory before starting and stop if free memory
drops below 60%. Each run has a five-minute runtime limit.

Success and injected-`SLVERR` runs passed in IEEE 1800-2012, 2017, and 2023.
The standalone runner prints:

```text
PASS: open AXI manager wrote/read CPTRA_MBOX_VALID_AXI_USER[0] through actual soc_ifc_top
PASS: actual soc_ifc_top transferred four mailbox words from AHB through the SRAM BFM to AXI DATAOUT
PASS: open AHB manager programmed actual soc_ifc_top; its DMA copied four SRAM words through the open AXI target
PASS: actual soc_ifc_top reported DMA_ERROR after the open AXI target returned SLVERR
```

The UVM-enabled runner passes the active AHB lock read, four-word mailbox
request/response, seven DMA-register writes, and both DMA cases under IEEE
1800-2012 with zero UVM warnings, errors, or fatals. The QVIP-compatible AHB
agent publishes completed `burst_transfer` records from actual SoC-IFC pins;
the success run records 6 reads/12 writes, and the injected-`SLVERR` run
records 12 reads/12 writes. It prints:

```text
PASS: active UVM AHB sequencer read the mailbox lock through actual soc_ifc_top
PASS: active UVM AHB sequencer transferred mailbox request/response words through actual soc_ifc_top
PASS: generated-path UVM AAXI observed all mailbox request/response transactions
PASS: generated-name UVM AAXI completed a four-word mailbox request/response through actual soc_ifc_top
PASS: active UVM AHB sequencer programmed seven DMA registers through actual soc_ifc_top
PASS: generated-name UVM AHB monitor observed actual soc_ifc_top traffic (reads=6 writes=12)
PASS: generated-name UVM AHB monitor observed actual soc_ifc_top traffic (reads=12 writes=12)
```

Caliptra RTL remains unmodified.

## Boundary

This is actual SoC-IFC RTL runtime evidence through the open host AXI manager,
the AHB manager, a four-word mailbox SRAM transfer, and the external DMA AXI
target. The generated-UVM mode separately checks its generated-name AAXI
hierarchy against the same DUT and mailbox BFM. This is not the full generated
Caliptra UVMF environment, firmware, full Caliptra top, or licensed QVIP/Avery
agents. The separate
[`generated-top overlay`](../caliptra-bfm-soc-ifc-axi-target-20261004/README.md)
provides a guarded replacement for the generated `hdl_top`'s all-zero manager
response block.

## Inputs

- Caliptra v2.1.2 commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- DUT: `src/soc_ifc/rtl/soc_ifc_top.sv`
- Filelist: `src/soc_ifc/config/soc_ifc_top.vf`
- DMA register base: `0x3002_2000`; test uses offsets `0x14` through `0x28` and
  control at `0x08`.
- SoC-IFC host address: `0x30048`, the `0x30030048` software-map register
  address minus `SOC_IFC_REG_OFFSET` (`0x30000000`).
- Mailbox CSR address: `0x20000`, the `0x30020000` software-map base minus
  `SOC_IFC_REG_OFFSET`; both modes transfer four request words starting with
  `0xb0f05eed` and four response words.
- Open target: `dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv`
- Testbench SHA-256: `abfd72dd1b2a983a7d3da142f6ee0800aa2283afd820b2f1bb2e1ce112f383aa`
- Runner SHA-256: `0fbdbb823efbbc8c0dd9291d5be159b0de28cf0f6f2d1abf0c29fc8967f35ea9`
- UVM runner SHA-256: `c7d150b38f8c6e011a2028bb8fab27e337d7dfd4892484cf12b18865d69c675e`
