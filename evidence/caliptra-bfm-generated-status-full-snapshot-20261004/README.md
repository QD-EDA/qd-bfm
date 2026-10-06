> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated Caliptra status monitor full-snapshot probe — 2026-10-04

## Scope

This probe runs the pinned generated `cptra_status_agent` in passive mode and
checks every field in its 17-field `cptra_status_transaction`. It verifies the
initial reset-deassertion record plus two later records triggered by distinct
interrupt edges. Each record checks reset polarity, seven interrupt/status
bits, the firmware-update window, all four packed entropy/key arrays, the NMI
vector, NMI pending, and ICCM lock.

The generated `cptra_status_transaction_coverage` subscriber is connected to
the same `monitored_ap`. The probe confirms its generated `write()` method
receives all three records and invokes the generated sampling path.

The initial record is expected behavior: `cptra_noncore_rst_b_o` starts low in
the generated monitor BFM, while the testbench reset input starts high. Its
`any_signal_changed()` function treats that reset deassertion as a change and
publishes an initial snapshot. The probe checks that record instead of
discarding it.

The runner uses the named hash-guarded disposable overlay for three generated
trailing-empty `$psprintf` arguments. Pinned Caliptra sources are not modified.
The compile reports seven coverage-stub warnings per edition; runtime reports
zero UVM warnings, errors, or fatals under IEEE 2017 and 2023. Icarus compiles
the generated covergroups as stubs, so this proves subscriber delivery and
sampling calls, not functional bin hits or coverage percentages.

This is generated passive-agent field-sampling and coverage-subscriber
delivery evidence. It does not measure functional coverage bins or run the
Caliptra DUT. Separate [generated SoC-IFC runtime evidence](../caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md)
exercises the status monitor and scoreboard against `soc_ifc_top` through
reset. The pinned SoC-IFC environment configures this agent as `RESPONDER`;
its generated driver task is a timing/copy skeleton, not a pin stimulus
implementation.

## Reproduce

From the `BFM WORK` repository root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-generated-status-full-snapshot-20261004/run.sh
```

## Inputs and hashes

- Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus/VVP revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`, with
  Accellera UVM 2020.3.1.
- Overlay helper and the three modified source hashes are recorded in
  [`status runtime evidence`](../caliptra-bfm-generated-status-runtime-20261004/README.md).

| Probe input | SHA-256 |
| --- | --- |
| `full_snapshot_probe.sv` | `732beedaa07ae9bad32fd4a925b0f394222ab44501afcb282fe9a1dceffa574d` |
| `run.sh` | `239fdcb9835e65689feea664c0a84cc128c02632533903c3dd16ab8d223f2bcc` |
| `verify.log` | `25445338c1b8b42bd675dd67adaaf834ce3a27651757cf3b8be07c10829c619e` |
