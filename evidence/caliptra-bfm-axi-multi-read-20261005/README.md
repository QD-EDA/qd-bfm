> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# AXI multi-read transaction monitor evidence

## Scope

This probe qualifies the Caliptra AXI transaction monitor's read-side
outstanding-context behavior. It does not qualify multiple outstanding writes
or replace the full Avery AXI agent.

The monitor now accepts up to eight read contexts by default. The directed
probe covers interleaved beats for two IDs, completion in a different order
from AR acceptance, in-order completion of two requests sharing an ID, context
capacity overflow, and the existing W-before-AW/write framing checks.

## Results

Both commands passed under the local UVM-enabled Icarus fork:

```sh
sh dv/caliptra_bfm/axi/tests/run_transaction_monitor.sh
env IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh dv/caliptra_bfm/uvm/tests/run_uvm_dma_agent.sh
```

The transaction-monitor run printed
`PASS: AXI records, W-before-AW, multi-ID reads, and capacity/error checks`.
The native UVM DMA-agent run drove the SRAM/FIFO map and propagated SLVERR;
the UVM summary had zero errors and fatals. Its two `PREDICT_NOK` warnings
correspond to the expected error-response cases in that test.

Both runs were protected by `scripts/run_with_memory_pressure_guard.py` with a
70% free-memory floor and a 0.5-second polling interval. The standalone
monitor run observed 79% minimum free memory; the UVM DMA-agent run observed
72% minimum free memory. The guard killed no processes.

Toolchain: Icarus Verilog 13.0 devel, `246c58e4-dirty`, with bundled Accellera
UVM 2020.3.1. Workspace HEAD at the time of the runs was
`246c58e4580f38a130ec08e5a7e6d93f110a5084` on
`claude/caliptra-bfm-plan-cxc8gn`.

## Source hashes

| File | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv` | `92bf5a5c490c13f2ab6ed469099499e4715a56dc40b1be22316dbda223577ff1` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_transaction_monitor.sv` | `d49ddff6cc2ee80b6d21a20b7ba57b51916822253e2ca3d2af704824112a34e1` |
| `dv/caliptra_bfm/axi/tests/run_transaction_monitor.sh` | `7b08d280f89aba0b8180971074f32da7cd8a077d65367171280309d02c211988` |
| `dv/caliptra_bfm/uvm/tests/run_uvm_dma_agent.sh` | `5cc94602de18b1707d2f7f7d3d383d90ae8f8a95d4b04d1ad987c0474b404266` |
| `scripts/run_with_memory_pressure_guard.py` | `1695c427d2aff61a205c7062ad487395181c5ec90f6fe28bd090d2ee9708e0aa` |
| `scripts/caliptra_bfm_memory_guard.sh` | `b15f9eeda7b61f036fe28b183a0c51461e7d7507e82252a28a24b756bf1e0593` |
