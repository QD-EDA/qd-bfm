# M12 DOE reset-corner assertion overlay

Draft 5's one-row gate targets `smoke_test_doe_scan` (`8f9e58bda7a24230`). The pinned M11 row reaches firmware PASS at mcycle 62,260, then the runner reports FAIL on `DOE STATUS valid bit not set after clear obf secrets cmd`. The c339 result is unverified.

The candidate build-time checker overlay adds one sampled clock after the existing `|=>` in the pinned DOE reset-corner property. The source generator verifies the pinned checker SHA-256 (`6bd2ade137a90c0701aab28951ba6f8918724e0467c21756b0c308e6e9081c89`), requires one exact property match, and checks the resulting property and diagnostic string. The generated checker overlay SHA-256 is `9c80af9817a1eccc6a54e2888b55a10809c8dd7902e25ef572c777779bd3f3b5`.

The first candidate changed the consequent to `|=> ##1`, delaying it by one extra sampled clock. Its one-row gate (job 2109) still reports two DOE assertion errors, although firmware reaches `TESTCASE PASSED` at mcycle 62,260; the result remains FAIL. The candidate did not fix the row.

The pinned checker comment describes a reset-release corner where `clear_obf_secrets` is already high and DOE status updates one cycle later. The diagnostic trace gate (Slurm job 2115) reached firmware PASS at mcycle 62,260 but did not emit samples. A local trace gate then captured the failure at `time=24464000`: the previous/current sampled top-level and DOE reset values were high; `clear_obf_secrets` changed 1→0; DOE `VALID` and `DEOBF_SECRETS_CLEARED` changed 1→0. The simulation log places a `cptra_rst_b` assertion/deassertion at cycles 244628/244638 immediately before the failure. This supports a reset-release sequence crossing the assertion, but the sample does not show the reset low at either adjacent sample.

A follow-up candidate added the top-level `cptra_rst_b` to `disable iff`. Its local one-row gate still reported one DOE assertion error, although firmware reached mcycle 62,260; see [`generated/local-mac-guard-01/`](generated/local-mac-guard-01/README.md). The reset guard by itself is not validated. The additional-delay-only candidate from job 2109 also failed. A combined delay and reset guard remains to be gated before the row can count as PASS. No RTL, firmware, or pass criteria are changed.

## Gate selection

| Row | Baseline | Gate status |
| --- | --- | --- |
| `8f9e58bda7a24230` | Firmware PASS, then 2 DOE assertion errors | FAIL: job 2109, firmware `TESTCASE PASSED`, mcycle 62,260 |

`gate-selection.tsv` records the row identity and original 21,600 s per-test timeout. `generated/` contains the prepared filelist and overlay manifests. The full affected-row rerun and 162-row comparison remain part of M12.
