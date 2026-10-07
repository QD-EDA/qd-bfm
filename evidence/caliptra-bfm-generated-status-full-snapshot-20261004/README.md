> Checkpoint copy: reports and JSON summaries are preserved here. The compact verification output for the merged-simulator replay is retained; generated binaries and verbose simulator logs are not.

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

From the QD-BFM repository root:

```sh
CALIPTRA_ROOT=/path/to/caliptra-rtl \
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN=/path/to/merged-iverilog/bin/iverilog \
VVP_BIN=/path/to/merged-iverilog/bin/vvp \
  sh evidence/caliptra-bfm-generated-status-full-snapshot-20261004/run.sh
```

The runner, probe, and `verify.log` are now checked in together. A replay on
2026-10-07 used the current QD-BFM source and Icarus merge commit
`ac4532fab037e91df2f903e67fb40f59baedccca`, containing fetched
`origin/main` tip `197f9baece79e66d25524906fb7b54c9faa8f4e2`. Both IEEE 2017 and
2023 runs passed: all 17 status fields matched in all three snapshots, the
generated coverage subscriber received all three, and UVM warning/error/fatal
counts were zero. The memory guard measured 50% free at preflight and 47% at
minimum against its 40% floor. Seven compile warnings per edition are the
expected generated covergroup stubs; this still does not measure functional
coverage bin hits.

## Inputs and hashes

- Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus/VVP revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`, with
  Accellera UVM 2020.3.1.
- Overlay helper and the three modified source hashes are recorded in
  [`status runtime evidence`](../caliptra-bfm-generated-status-runtime-20261004/README.md).

| Original `BFM WORK` capture input | SHA-256 |
| --- | --- |
| `full_snapshot_probe.sv` | `732beedaa07ae9bad32fd4a925b0f394222ab44501afcb282fe9a1dceffa574d` |
| `run.sh` | `239fdcb9835e65689feea664c0a84cc128c02632533903c3dd16ab8d223f2bcc` |
| `verify.log` | `25445338c1b8b42bd675dd67adaaf834ce3a27651757cf3b8be07c10829c619e` |

The 2026-10-07 replay hashes and simulator binary identities are in
[`result.json`](result.json); its captured output is [`verify.log`](verify.log).
