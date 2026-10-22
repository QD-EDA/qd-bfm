# Draft: DOE status assertion after obfuscation clear

**Status:** Local review draft only; not posted.

## Observation

In assertion-enabled Verilator 5.052, `smoke_test_doe_scan` (pinned RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`) reports:

```text
SVA ERROR: DOE STATUS valid bit not set after clear obf secrets cmd
```

The message appears immediately after reset deassertion and before the firmware-ready/fuse-download sequence. Firmware continues and prints its pass marker at `mcycle=62260`; the simulation exits 0, but the runner records `FAIL` because `sim_scan.bad=1` for the SVA error.

The assertion source (`src/integration/asserts/caliptra_top_sva.sv:192-198`) documents a reset corner: if `clear_obf_secrets` remains high through reset deassertion, DOE status takes an extra cycle to update. The prior c339 result is `UNVERIFIED`, so the M11 result does not establish a simulator disagreement.

The M11 result row and sim log are preserved in [`batch-01-results.tsv`](../batch-01-results.tsv) and [`completed-1964-01.tar.gz`](../completed-1964-01.tar.gz), under result `8f9e58bda7a24230`.

## M12 trace and remaining question

The build-time delay-only candidate changed the consequent to `|=> ##1`, adding one sampled clock. Slurm job 2109 still recorded two copies of the DOE assertion error, although firmware printed `TESTCASE PASSED` at mcycle 62,260; the runner correctly classified the row as FAIL.

The failure-action trace in [`diagnostic-trace/`](../../../caliptra-bfm-verilator-m12-20261017/doe-reset-delay/diagnostic-trace/README.md) captured `time=24464000`: the previous/current sampled top-level and DOE reset signals were high, while `clear_obf_secrets`, `DOE_STATUS.VALID`, and `DEOBF_SECRETS_CLEARED` changed from 1 to 0. The simulation log records a `cptra_rst_b` assertion and deassertion at cycles 244628/244638 immediately before the failure. This supports a reset-release sequence crossing the property, but does not show the reset low at either adjacent sample.

A reset-guard-only candidate added top-level `cptra_rst_b` to `disable iff`; its local one-row gate still recorded one DOE assertion error and firmware PASS at mcycle 62,260. See [`local-mac-guard-01`](../../../caliptra-bfm-verilator-m12-20261017/doe-reset-delay/generated/local-mac-guard-01/README.md). Neither delay-only nor reset-guard-only is validated.

A combined delay and reset guard was gated on the pinned Slurm toolchain in job 2121. It still recorded two copies of the assertion error at `time=24464000` and `time=24465000`, with `sim_scan.bad=2`, although the firmware printed `TESTCASE PASSED` at mcycle 62,260. The first failure sample has reset high and shows `clear`, `VALID`, and `DEOBF_SECRETS_CLEARED` changing from 1 to 0; at the next sample all three remain 0. The runner correctly classified this as FAIL. The combined candidate did not resolve the assertion, so no affected-row array is justified from this overlay. See the checksum-verified [job output](../../../caliptra-bfm-verilator-m12-20261017/doe-reset-delay/generated/gate-2121/).

The reset-release sequence is correlated with the failing sample, but the available trace still does not establish whether Verilator sampling or the assertion's expected hardware behavior is the cause. The c339 result remains UNVERIFIED; retain the row as FAIL until a specific testbench-portability cause is demonstrated. No functional RTL, firmware, or pass criteria were changed, and nothing has been posted upstream.
