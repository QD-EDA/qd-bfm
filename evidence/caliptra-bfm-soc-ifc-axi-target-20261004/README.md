> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# SoC-IFC open DMA AXI target overlay — 2026-10-04

The pinned generated SoC-IFC `hdl_top.sv` instantiates Caliptra's `soc_ifc_top`
and its typed 48-bit-address, 32-bit-data/USER, 5-bit-ID `axi_if`, but drives
the DMA manager responses to zero. That prevents the DUT's external DMA AXI
manager from completing transactions.

`prepare_overlay.py` makes a disposable copy of that generated top and replaces
only the guarded tie-off block with the open
[`axi4_caliptra_dma_if_subordinate`](../../dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv).
The target connects through `m_axi_if.w_sub` and `m_axi_if.r_sub`, maps the
pinned SRAM base/size (`0x0001_2344_0000`, 256 KiB) and FIFO base/capacity
(`0x0000_fa57_0000`, 64 KiB), and uses the Caliptra 18-bit region decode.
Stalls, injected errors, autonomous FIFO traffic, and recovery emulation are
held inactive for this default integration.

The disposable top also connects the generated `default_reset_gen` pulse to
all seven BFM interface bundles. The pinned generated top tied each `dummy`
reset input high, so the driver BFMs' reset initialization blocks never ran
and their outputs remained high impedance at startup. This overlay change is
hash guarded and does not alter the pinned Caliptra checkout.

The pinned Caliptra source is not modified. The generator requires the exact
`hdl_top.sv` SHA-256 below and fails closed if the file or tie-off block differs.

## Generate

```sh
python3 evidence/caliptra-bfm-soc-ifc-axi-target-20261004/prepare_overlay.py \
  --output /tmp/caliptra-soc-ifc-hdl-top-open.sv
```

Use the generated file in place of the pinned `hdl_top.sv` in the local SoC-IFC
simulation filelist, and include
`dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv` after Caliptra's
`axi_if.sv` plus the generic BFM modules in `dv/caliptra_bfm/caliptra_bfm.f`.
The proprietary UVMF/QVIP/Avery APIs are not replaced by this AXI target
overlay. Icarus runtime experiments use the repository's clean-room UVMF-lite
and AAXI compatibility surfaces; full compatibility remains unqualified.

## Verification boundary

The generator validates the pinned source hash, exact AXI tie-off cardinality,
all seven BFM reset connections, and the generated target. The existing typed-interface test
`dv/caliptra_bfm/axi/tests/run_caliptra_axi_if.sh` exercises the same target
through Caliptra's real `axi_if` manager/subordinate modports, including a
monitored 256-beat SRAM round trip. The generated SoC-IFC packages and top have
also been compiled and exercised with the open compatibility surfaces, but
the runtime reset/predictor/scoreboard flow still fails; see the
[`generated runtime evidence`](../caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md).

A separate direct-RTL test does run the actual `soc_ifc_top` with the open AHB
manager and AXI target, programming the DMA registers over AHB and checking a
four-word copy plus the final DMA status read under IEEE 2012/2017/2023. See
the [SoC-IFC AHB-to-DMA runtime evidence](../caliptra-bfm-soc-ifc-dma-runtime-20261004/README.md).

## Source identity

- Caliptra RTL: v2.1.2, commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Source: `src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/project_benches/soc_ifc/tb/testbench/hdl_top.sv`
- Source SHA-256: `a875a33b09abe09b9bed9220c8de0494917891da68442c943915c1e942fe7f84`
- Overlay generator SHA-256: `d9db8022632ca373b9d33f6334f52ecc9a9ad3d471553d97b92a6f2a2b71497f`
