> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra AXI UVM interface smoke — 2026-10-04

## Scope

The native Caliptra AXI UVM agent drives the pinned Caliptra `axi_if` through
its manager proxy. The open DMA SRAM/FIFO target connects using the actual
`w_sub` and `r_sub` modports. A passive monitor on the same interface publishes
completed records to a UVM analysis subscriber. The smoke checks a two-beat
SRAM write/readback, fixed-burst FIFO write/read, and a 256-beat SRAM
write/readback, and a one-beat injected `SLVERR` read. The sequence and monitor
check response propagation as well as transaction IDs, payload, framing and
LAST.

This is BFM/interface component evidence. It does not instantiate the Caliptra
DMA engine, run the top-level Caliptra DUT or qualify the generated UVMF
environment. `-DXCELIUM` excludes optional dynamic-array helper tasks from the
Caliptra interface source; signal declarations and modports remain compiled.

## Inputs and toolchain

- Repository commit: `246c58e4580f38a130ec08e5a7e6d93f110a5084` (working tree has local BFM changes).
- Caliptra v2.1.2 commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Simulator: Icarus Verilog/VVP 13.0 devel, build `246c58e4-dirty`.
- UVM: Accellera 1800.2 UVM 2020.3.1, bundled with the selected Icarus build.
- `iverilog` SHA-256: `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392`.
- `vvp` SHA-256: `b7e9e2d0b994bdd5e17a2e8033dfe76ca9fafb9ec9fdca35f16a9d1b63c9cba9`.

## Reproduction and result

Run from the repository root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  dv/caliptra_bfm/uvm/tests/run_uvm_axi_if.sh
```

The run exited 0 and printed:

```text
PASS: UVM AXI agent, DMA target and monitor completed SRAM/FIFO, SLVERR and 256-beat traffic through Caliptra axi_if
```

The UVM summary reported zero warnings, errors and fatals. Icarus printed its
mixed-timescale warning. The runner removes its temporary executable and log;
this record preserves the command, hashes, and observed summary.

## Source hashes

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvm/tests/run_uvm_axi_if.sh` | `069ce6a4c4078a4aa8e47226ed2c962ef85af814e63e279fae5e67b360ba8d38` |
| `dv/caliptra_bfm/uvm/tests/tb_axi4_caliptra_uvm_axi_if.sv` | `3db61b86584af0c92b9d80662396a23dbbe6208f6ebd10a76cb088d0a32c8ec0` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_uvm_master_proxy.sv` | `dfbe0507af98b42e6ba65529bc8177fa704d5e563d0eb37a87f7b7467484342d` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_uvm_pkg.sv` | `8a09f371b68098b044e0c4282fa0131852b090cfd83cb5c55fa9e72cbe604a2b` |
| `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f` | `3692ba45254bf856a87a8f6ac33c0517e97c7cd17a965f9fc36931f7b209a9e8` |
| `dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv` | `3ef2180e298d7798c3b2caa5ac31587f623a817983075ef7556a5071f1f5b029` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv` | `28bbc17e1079f44d808599642a7317d1248b43fc1ba5e2a3ee067655aa005f58` |
| Pinned Caliptra `src/axi/rtl/axi_pkg.sv` | `07991843e3a2b77e6aae9c6903ae8ff08927ddbb517d83a23f96abd89be3af29` |
| Pinned Caliptra `src/axi/rtl/axi_if.sv` | `e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c` |
