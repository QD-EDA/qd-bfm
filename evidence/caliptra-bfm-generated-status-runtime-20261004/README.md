> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated Caliptra status agent runtime probe — 2026-10-04

These probes extend the status package compile/elaboration slice. The active
probe creates the actual generated `cptra_status_agent` with the clean-room
UVMF base, registers the actual generated driver/monitor BFMs in
`UVMF_VIRTUAL_INTERFACES`, and checks that both BFM proxy handles point back
to their generated UVM components. The active agent also has its expected
driver, monitor, and sequencer.

The passive monitor probe changes `soc_ifc_error_intr` and `nmi_vector` on
testbench-driven pins. It checks that the generated monitor publishes the
error event and exact vector through the agent's `monitored_ap` analysis
stream.

The generated driver's `initiate_and_get_response` task is only a timing
skeleton: it waits four clock edges and copies a transaction struct, but does
not assign transaction fields to BFM output pins. Caliptra's SoC environment
configures `cptra_status_agent_config.initiator_responder = RESPONDER`. The
agent-construction check therefore proves proxy wiring only; it does not
qualify active signal driving. The passive monitor probe covers the named
observation subset.

The pinned generated configuration/driver/monitor contain three `$psprintf`
calls with trailing empty actual arguments. The run uses the named
[hash-guarded disposable overlay](../../docs/conformance/release_overlays/caliptra/cptra_status_psprintf_empty_arg_overlay.py)
from the [compile probe evidence](../caliptra-bfm-generated-status-20261004/README.md).
No pinned Caliptra files are changed.

## Reproduce

From the `BFM WORK` clone root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-generated-status-runtime-20261004/run_probe.sh

IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-generated-status-runtime-20261004/run_monitor_probe.sh
```

The monitor probe also passes in both editions, with the analysis record at
35 simulation time units, two published records total, and zero UVM warnings,
errors, or fatals. Its captured output is in
`verify_monitor.log` (raw artifact omitted from this checkpoint).

Expected result under IEEE 1800-2017 and 2023:

```text
PASS: generated active status agent installed driver/monitor proxies under IEEE 2017 (7 compile warnings).
UVM_INFO ... [STATUS_PROBE] PASS: generated active status agent installed driver and monitor proxies
UVM_WARNING :    0
UVM_ERROR :    0
UVM_FATAL :    0
PASS: generated active status agent installed driver/monitor proxies under IEEE 2023 (7 compile warnings).
UVM_INFO ... [STATUS_PROBE] PASS: generated active status agent installed driver and monitor proxies
UVM_WARNING :    0
UVM_ERROR :    0
UVM_FATAL :    0
```

The compile warnings are calls to `set_inst_name` on Icarus's generated
coverage stubs. This checks generated component construction, config-DB VIF
retrieval, and proxy installation. It does not start a sequence, send status
transactions through the driver, sample coverage, or instantiate the Caliptra
DUT. The monitor probe covers only the named status fields and one event
shape; full status transaction/runtime qualification remains open.

The captured runner output is in `verify.log` (raw artifact omitted from this checkpoint). The probe source
SHA-256 is `2a8cc823c31490282ea6bb9a2308f294e3db1d9c1132e929d00aea2891e5d10e`;
the runner SHA-256 is
`332789cb51775cb1c8080caf7f4d10d2098382694730c30294a163183e73b82c`.

The run uses the pinned Caliptra v2.1.2 checkout at commit
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Accellera UVM 2020.3.1, and the
clean-room `uvmf_base_pkg.sv` SHA-256
`afc5c560036229a6416d788cb9b35a34de434c8fcd5e879722ed917d9a9609c8`.

| Probe input | SHA-256 |
| --- | --- |
| `runtime_probe.sv` | `2a8cc823c31490282ea6bb9a2308f294e3db1d9c1132e929d00aea2891e5d10e` |
| `run_probe.sh` | `332789cb51775cb1c8080caf7f4d10d2098382694730c30294a163183e73b82c` |
| `verify.log` | `1c28c74d43bc5cd01a7f31f4f7685c94bce61284167cd430a439938aa709d6ac` |
| `monitor_probe.sv` | `b671d07b90001a8709c1bd26fcfde3b2931f7d764a093dce034c5963cbd8ef53` |
| `run_monitor_probe.sh` | `edeb0b563f6408a6d2a10dd90523d69b03c3c9786d6fabc52ded1ae4327803f5` |
| `verify_monitor.log` | `5856633d8083d1e0f51b0a4d5bc9d3c5a7060c5ffd9e01768538ff91bc5e274c` |
