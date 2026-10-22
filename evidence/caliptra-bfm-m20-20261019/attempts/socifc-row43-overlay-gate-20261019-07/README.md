# SoC-IFC row 43 overlay gate, retry 7

One-row gate for the expanded testbench compatibility overlay. It handles the remaining observed Icarus issues: filtered bins over 4,096 values, wide coverpoint bins, and one generated empty `$psprintf` argument. The overlay changes coverage representation only; no functional RTL, firmware, stimulus, expected values, assertions, or pass criteria change.

Source pin and c339 compiler are unchanged. Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds. This is a one-row gate before any other row uses the updated overlay. The extracted source tree and input hashes passed preflight before submission.

Submitted as Slurm job 3248 with 17/20 CPUs allocated. Input hashes are in `input-sha256.txt`.

## Result

Job 3248 ended `OUT_OF_MEMORY` after 51.988 seconds. Icarus exited 137 at 2 GiB with 2,101,292 KiB peak RSS; no simulation ran. The result remains `BLOCKED`.

Verified compile blockers still present in `compile.log`: automatic bins on a wide coverpoint in `soc_ifc_ctrl_transaction_coverage.svh:36`, plus trailing empty `$psprintf` arguments in `cptra_ctrl_pkg`, `ss_mode_ctrl_pkg`, and `soc_ifc_status_pkg`. The prior overlay had handled only the `soc_ifc_ctrl_pkg` formatter. Ask-intern also flagged those diagnostics; I checked each against the archived log. It reported the wide-bin diagnostic at line 36 and formatter calls at line 149; the OOM kill is independently confirmed by `compile.resource` and the Slurm output.

Archive: `raw/job-3248_43.tar.gz`; SHA-256 `089e42ad20315bc7af2e0370f55f72aaded097138f6be7b2116405ef47428fce`, matching the remote sidecar. Raw `result.json`, `compile.log`, `compile.resource`, `runner.log`, `runner.resource`, Slurm output, and checksum are saved under `raw/`.
