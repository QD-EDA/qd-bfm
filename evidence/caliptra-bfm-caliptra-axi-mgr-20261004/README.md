> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra AXI manager BFM integration — 2026-10-04, revalidated 2026-10-05

## Scope

This smoke runs the pinned Caliptra `axi_mgr_wr` and `axi_mgr_rd` modules as
the AXI initiator. Their request-side Caliptra DMA interfaces are driven by the
testbench. The manager outputs connect through the pinned Caliptra `axi_if`
modports to the open SRAM/FIFO subordinate; a passive transaction monitor
publishes records through the native UVM agent. A two-beat ordinary SRAM write
and readback exercise the managers' address/control generation, USER, payload,
WSTRB, WLAST, responses, and monitor record path. The target uses a 5-bit AXI
ID width, matching Caliptra's DMA profile. Exclusive writes need a preceding
matching exclusive read, so this manager smoke leaves `LOCK` low; exclusive
success and failure are covered by the standalone target regression.

This is actual Caliptra AXI manager RTL plus BFM component evidence. It does
not instantiate `axi_dma_ctrl`, the DMA register block, `axi_dma_top`, or the
full Caliptra DUT. The default Caliptra assertion macros are compiled; the
runner does not define `SYNTHESIS` or `VERILATOR`.

## Inputs and toolchain

- Icarus/VVP source revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`.
- Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Simulator: Icarus Verilog/VVP 13.0 devel, build `246c58e4-dirty`.
- UVM: Accellera 1800.2 UVM 2020.3.1, bundled with the selected Icarus build.
- `iverilog` SHA-256: `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392`.
- `vvp` SHA-256: `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574`.

## Reproduction and result

Run from the repository root:

```sh
IVERILOG_BIN=./driver/iverilog \
VVP_BIN=./vvp/vvp \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh
```

The run exited 0 and printed:

```text
PASS: Caliptra AXI read/write managers completed monitored traffic through the open DMA target and UVM BFM adapter
```

The memory guard reported 75% free before launch and 75% minimum observed,
against its 70% floor. The UVM summary reported zero warnings, errors, and
fatals. Icarus printed its mixed-timescale warning and noted a generated DPI
export stub. Temporary executable and log files are removed by the runner.

## Source hashes

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh` | `38f99fb8883289a6ad7b4be3e4e597facf41964bfdd05621f356826f154c067a` |
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_mgr_uvm_bfm.sv` | `ab22a8c89fcad0bcdb594b37c9cd5f0936a13801fb4bdcb9e1e0bf72186ee88d` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_uvm_pkg.sv` | `e3b644122dea02c22beb10113f5b01b76527f734b3d3a12e8a82ac2134a6cbb0` |
| `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f` | `3692ba45254bf856a87a8f6ac33c0517e97c7cd17a965f9fc36931f7b209a9e8` |
| `dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv` | `3ef2180e298d7798c3b2caa5ac31587f623a817983075ef7556a5071f1f5b029` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv` | `28bbc17e1079f44d808599642a7317d1248b43fc1ba5e2a3ee067655aa005f58` |
| Caliptra `src/axi/rtl/axi_pkg.sv` | `07991843e3a2b77e6aae9c6903ae8ff08927ddbb517d83a23f96abd89be3af29` |
| Caliptra `src/axi/rtl/axi_if.sv` | `e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c` |
| Caliptra `src/axi/rtl/axi_dma_req_if.sv` | `ada340cb05a7da60444701ab6230d13be035724b082759b889b815f42eff9cf8` |
| Caliptra `src/axi/rtl/axi_mgr_rd.sv` | `ea020134f12c9bdfa9068b3e3431b5dad340da667234c8776bc272ccf957f01f` |
| Caliptra `src/axi/rtl/axi_mgr_wr.sv` | `8b0d4c52996f1b19bb21a53c0d9103df853dccb0ddf10708a92c489d8b0bc157` |
| Caliptra `src/libs/rtl/skidbuffer.v` | `ae4f49f18e1b635f6c8454abee5f1762e483ea21480f89e131102d35b5d8a523` |
| Caliptra `src/caliptra_prim/rtl/caliptra_prim_assert.sv` | `5f16fd78197b912bfddf3600c78e992a580911a286adda64e35eff04bf3d6a81` |
| Caliptra `src/caliptra_prim/rtl/caliptra_prim_assert_standard_macros.svh` | `8361440b529925ae32689364c5bc644019258b2111a85424ca9fa3d31243d6f2` |
| Caliptra `src/libs/rtl/caliptra_sva.svh` | `4822d70ecf29721a5f660c5e47cc257624a47d99b675f953980b038a96e4dddf` |
