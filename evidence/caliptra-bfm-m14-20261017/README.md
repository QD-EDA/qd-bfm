# M14 block-level Icarus coverage

**Result: 22/44 block-level rows PASS on current-main Icarus with permitted overlays.** The M14 target is met.

## Counts

| Configuration | PASS | BLOCKED | FAIL | TIMEOUT |
|---|---:|---:|---:|---:|
| M13 baseline, pinned only | 11 | 30 | 1 | 2 |
| M13 baseline, with overlays | 19 | 20 | 2 | 3 |
| M14, pinned only | 11 | 30 | 1 | 2 |
| M14, with overlays | **22** | 17 | 2 | 3 |

The pinned-only totals are unchanged. The M14 overlay PASS set is exactly the M13 set of 19 plus `compress_tb`, `sigdecode_z_tb`, and `skencode_tb`; no prior PASS row was downgraded. The row-by-row comparison and assertions are in [`preservation-check.txt`](preservation-check.txt), and the complete 44-row table is [`m14-final-results.tsv`](m14-final-results.tsv).

The previous 19 PASS rows were carried forward from M13 rather than rerun. M14 made only row-local testbench, filelist, and setup changes for the three new rows. Caliptra RTL, firmware, the Icarus/VVP binaries, and pass criteria stayed fixed, so these overlays do not reach the existing rows.

## New PASS rows

- **`adams-bridge-v2-0-3-compress_tb` — job 2347.** Current-main pinned-only remains blocked by the missing `ntt_defines_pkg.sv` filelist entry and stale testbench interface. The run-local filelist and testbench overlays adapt the bench to the current `compress_top` interface and latch its `compress_done` event without weakening the scoreboards. Compile and simulation exited 0; all three modes passed with 32, 160, and 352 packed output words. [Full record and raw evidence](compress/attempt-2347/README.txt).
- **`adams-bridge-v2-0-3-sigdecode_z_tb` — job 2354.** The pinned RTL package was used unchanged. A testbench-only overlay uses the existing `ABR_MEM_ADDR_WIDTH` and removes an obsolete unused source-base argument. Protected Python 3.14.4 / NumPy 2.5.4 generated both nonempty vectors. Compile and simulation exited 0; the existing comparisons completed with no mismatch or runtime error. [Full record and raw evidence](mldsa-width/sigdecode-z/attempt-2354/README.txt).
- **`adams-bridge-v2-0-3-skencode_tb` — job 2355.** The pinned RTL package was used unchanged. A testbench-only overlay uses `ABR_MEM_ADDR_WIDTH` and connects the existing expected-error check to the DUT's `error_flag`; the data comparisons and negative-input expectation remain intact. Compile and simulation exited 0; all three comparisons and the expected error check passed. [Full record and raw evidence](mldsa-width/skencode/attempt-2355/README.txt).

The counted runs used current-main Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. The run records preserve compiler/tool hashes, exact sources and filelists, vector inputs, logs, and resource reports. Each job used one task, one CPU, and 3 GiB; job time limits were 15 minutes for compress and 30 minutes for each width bench. Jobs ran as one-row gates, below the six-task/four-CPU limits.

Superseded and failed setup attempts are retained for diagnosis but do not count. In particular, the earlier sigdecode and skencode trials that replaced a package were marked superseded and are excluded; the accepted runs use the pinned package unchanged. No simulator defect was found in these three rows, so M14 produced no simulator issue draft.

## Remote cleanup

After copying and hash-verifying the evidence, the M14 Slurm run trees were removed. The per-attempt cleanup records sum to **8,249,847 bytes (7.87 MiB) freed**. A final queue check found no A2 jobs and no M14 run directory; the remaining queued/running jobs belonged to other agents.

## Next milestone: runner coverage for 108 UVMF/authored rows

M13 classified 109 generated-UVMF/authored-stimulus rows: 52 generated UVMF and 57 authored stimulus. Only `HMAC_random_test` has an exact existing Icarus selector, and its compile gate is blocked; the other **108** have no exact test runner. See [`M13 classification`](../caliptra-bfm-m13-20261017/109-row-icarus-classification.tsv) and the [M13 analysis](../caliptra-bfm-m13-20261017/README.md).

The next milestone should first group those rows by shared environment and generated bench, then build shared runner support rather than 108 separate launchers:

1. Map each YAML test name to its environment/top, generated packages and sequences, required vectors/configuration, and current result checks.
2. Extend the existing UVMF-lite runner path with exact per-test selection, deterministic seed/config inputs, and a machine-readable result with separate compile, test failure, and timeout outcomes.
3. Add per-environment source staging and package-order/filelist definitions, plus only the testbench/runtime compatibility glue those environments need. Keep RTL, firmware, and test expectations unchanged.
4. Pilot one representative generated-UVMF test and one authored-stimulus test before scaling across the groups. Preserve each test's existing scoreboard and failure conditions.
5. Treat the existing HMAC selector as a separate blocked prerequisite: its elaboration currently hits wide automatic coverage bins, a generated string concatenation using a method reference, and nested class-property access. A3 owns any simulator fixes; upstream issue drafts remain for user review.

This is a runner/selection and environment-integration milestone, not a firmware or Verilator port. Some rows may prove unsupported or lack required inputs once mapped; the pilot and grouped inventory will reveal that before broad expansion.
