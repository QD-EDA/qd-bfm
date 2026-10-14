> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated-name AAXI active/passive monitor smoke — 2026-10-04

This focused smoke runs the clean-room `aaxi_uvm_testbench` hierarchy against
the open Caliptra AXI manager and DMA SRAM target. The active `master[0]`
issues one SRAM write and one read. Both its monitor and the passive
`psv_master[0]` monitor must publish one completed record for each operation.
The test also checks that the passive agent has no sequencer or active driver
and that its `cfg_info.passive_mode` is set.

The run exited 0 with zero UVM errors or fatals. Icarus emitted its existing
timescale and object-property fallback warnings. The generated monitor record
VIF and the live `aaxi_intf` `ports` VIF are installed by
`aaxi_monitor_wrapper`. The active compatibility driver requires `ports`, passes
it to its AAXI driver, and waits for its reset to deassert before issuing the
command. Caliptra's generated `soc_ifc_environment` provides the same config-DB
key from `aaxi_uc.ports`. The passive monitor observes the same pin record
interface as the active monitor.

The original guarded run began at 81% free memory and observed an 81% minimum
with a 65% floor. After the default floor was raised to 70% and the driver
started requiring the `ports` VIF, the focused compile/simulation was rerun
under the guard with a 70% floor and 300-second timeout. It started at 81%,
observed an 80% minimum, and exited 0. The latest simulator output and guard
telemetry are in `run-with-ports-vif-guard.log` (raw artifact omitted from this checkpoint)
and `memory-guard-ports-vif.log` (raw artifact omitted from this checkpoint).

The captured output and structured result are in
`run.log` (raw artifact omitted from this checkpoint) and [`results.json`](results.json). Reproduce through the
memory guard after setting `IVERILOG_BIN` and `VVP_BIN` to the local UVM-enabled
Icarus fork:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=/path/to/vvp \
python3 scripts/run_with_memory_pressure_guard.py \
  --max-process-bytes 6442450944 --min-available-bytes 6442450944 \
  --timeout-seconds 300 \
  --log /tmp/caliptra-aaxi.log -- \
  sh dv/caliptra_bfm/uvm/tests/run_aaxi_compat.sh
```

This qualifies the local generated-name component path only; it does not
compile the full generated SoC-IFC environment or establish Avery VIP
equivalence.

The same compile/simulation was rerun through the reusable
[`memory-pressure guard`](../../scripts/run_with_memory_pressure_guard.py):
the guarded run began at 75% free memory, observed a 74% minimum, and exited 0
with zero UVM errors or fatals. Its simulator output is in
`run-with-guard.log` (raw artifact omitted from this checkpoint). This verifies the guard around an
actual BFM smoke, including its compiler and simulator child processes.
