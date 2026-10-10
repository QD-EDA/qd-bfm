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

## Actual Caliptra AXI manager BFM check — 2026-10-09

The focused `run_caliptra_axi_mgr_uvm_bfm.sh` smoke now passes on a clean
source archive of published Icarus main
`127b887dfdc09283ab0187a2e618421dee3d5dcc`, using the clean pinned Caliptra
tree `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. It connects the actual
Caliptra `axi_mgr_wr` and `axi_mgr_rd` modules through `axi_if` to the open DMA
target and passive UVM BFM adapter. The subscriber checked one two-beat write
and one two-beat read, including USER, data, strobe, response, and LAST fields.
The UVM report had zero warnings, errors, and fatals; the runner exited 0.
This is targeted AXI manager/agent integration evidence, not a generated
Caliptra environment or full protocol qualification.

Command:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
dv/caliptra_bfm/uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh
```

Current source fingerprints:

```text
a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602  iverilog
29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca  vvp
07b55cfc11b1b1c448bb28a98c08c6318de4481d1bdffa05e247ece69dc75694  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh
7f0882627751bb4100ba64fe8ea63c6cf5a925fb76c72321af27cdd13de1c5ee  dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_mgr_uvm_bfm.sv
d01deae87900d61b59cff34cf065a8999fa2b2c616d22b22ffdca5b768a7eb94  dv/caliptra_bfm/uvm/axi4_caliptra_uvm_pkg.sv
ea020134f12c9bdfa9068b3e3431b5dad340da667234c8776bc272ccf957f01f  Caliptra src/axi/rtl/axi_mgr_rd.sv
8b0d4c52996f1b19bb21a53c0d9103df853dccb0ddf10708a92c489d8b0bc157  Caliptra src/axi/rtl/axi_mgr_wr.sv
e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c  Caliptra src/axi/rtl/axi_if.sv
```

## Current-state diagnostic rerun — 2026-10-10

The interface smoke was rerun with the native UVM driver/proxy pipeline changes
on QD base commit `b6cf7a70a6007a94087a50b445444efeaa9d15d6` and a dirty working
tree. This is diagnostic evidence, not qualification. The run used the same
published Icarus source SHA `127b887dfdc09283ab0187a2e618421dee3d5dcc` from the
clean source archive recorded above and the clean Caliptra tree
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Its installed `iverilog` and
`vvp` hashes matched the 2026-10-09 run. The smoke passed with zero UVM
warnings, errors, or fatals; Icarus emitted its mixed-timescale warning. The
SRAM write scoreboard now expects LOCK clear, matching the sequence's
non-exclusive write.

Command:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
dv/caliptra_bfm/uvm/tests/run_uvm_axi_if.sh
```

Current source fingerprints:

```text
647a43eca2cc6b608b0f56eff509f00c5323050b1a05e9c39d06d7e23ce1b232  dv/caliptra_bfm/uvm/axi4_caliptra_master_cmd_if.sv
89419c2a21a4ed05a86f573ce245f5912729b01b62a461e21d419b5c19e6fb55  dv/caliptra_bfm/uvm/axi4_caliptra_uvm_master_proxy.sv
e98475132f09290c45453d0f3c191cc6aeec092acbdfb834d7c27be885178495  dv/caliptra_bfm/uvm/axi4_caliptra_uvm_pkg.sv
a168f695a5129b72bdded985b2e09c1627fe752bb831082eb954334f27ebf34d  dv/caliptra_bfm/uvm/tests/tb_axi4_caliptra_uvm_axi_if.sv
0622ccfe7839e676ceeb41f7691c4fa9ea3647f342216e89d097953d5a72bc55  dv/caliptra_bfm/uvm/tests/run_uvm_axi_if.sh
a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602  iverilog
29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca  vvp
```

## Actual Caliptra AXI manager rerun — 2026-10-10

The real `axi_mgr_rd` and `axi_mgr_wr` integration smoke passed with zero UVM
warnings, errors, or fatals. This diagnostic used QD commit
`73826a3` with unrelated worktree dirt, clean Caliptra
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and the published clean Icarus
source revision `127b887dfdc09283ab0187a2e618421dee3d5dcc`. Icarus emitted its
mixed-timescale warning; this result is not full BFM qualification.

Command:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
dv/caliptra_bfm/uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh
```

Current source fingerprints:

```text
afa63b20041ebef82ff585b449c06cfd208ddc95e8ba2bfd18396fc6ddd931c4  dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f
647a43eca2cc6b608b0f56eff509f00c5323050b1a05e9c39d06d7e23ce1b232  dv/caliptra_bfm/uvm/axi4_caliptra_master_cmd_if.sv
89419c2a21a4ed05a86f573ce245f5912729b01b62a461e21d419b5c19e6fb55  dv/caliptra_bfm/uvm/axi4_caliptra_uvm_master_proxy.sv
e98475132f09290c45453d0f3c191cc6aeec092acbdfb834d7c27be885178495  dv/caliptra_bfm/uvm/axi4_caliptra_uvm_pkg.sv
98da8c8e57dfe659f03612c80f258110ab2eaa29c5416d9f89bafc9225b7a224  dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv
07b55cfc11b1b1c448bb28a98c08c6318de4481d1bdffa05e247ece69dc75694  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh
7f0882627751bb4100ba64fe8ea63c6cf5a925fb76c72321af27cdd13de1c5ee  dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_mgr_uvm_bfm.sv
ea020134f12c9bdfa9068b3e3431b5dad340da667234c8776bc272ccf957f01f  Caliptra src/axi/rtl/axi_mgr_rd.sv
8b0d4c52996f1b19bb21a53c0d9103df853dccb0ddf10708a92c489d8b0bc157  Caliptra src/axi/rtl/axi_mgr_wr.sv
e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c  Caliptra src/axi/rtl/axi_if.sv
a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602  iverilog
29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca  vvp
```
