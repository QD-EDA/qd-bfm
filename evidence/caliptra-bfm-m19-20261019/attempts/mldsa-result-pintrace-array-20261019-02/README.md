# M19 current-c339 row76/93/97 comparison

Array job 3140 runs row 76 without the AHB trace and rows 93/97 with observation-only AHB pin traces around reads at `0xd8–0x114`. DAN-DESKTOP resources: 1 CPU and 2 GiB per task, at most two concurrent tasks, 75-minute Slurm limit; runner caps are 600 seconds for row 76 and 3,600 seconds for rows 93/97. The trace helper does not change RTL, firmware, test sequences, expected values, or pass criteria.

- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.
- Pinned Icarus: `cae035642e056644274a01e98d4422ce286685b4`, `iverilog` SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`.
- Source snapshot SHA-256: `ce5ba73163820aea5c9c065f81bbd5758365f8fb0d78c5a2ca9949f300c2c284`; trace helper SHA-256: `5ef352494b596a273a2c3da7237d79108d1fe9516ead496408fa3564089f8318`; submitted script SHA-256: `37abd17844dbc23ff39872ea4fecbbf0baf8ad7ed422e468a8e4bcab3691883f`.
- Local submission copy and hashes: `run.sbatch`, `input-sha256.txt`, and `submission.txt`.

## Row 76

Row 76 finished FAIL on current c339 in 0.145 seconds, with compile/simulation exit 0. Its existing testbench-only expected-vector overlay loaded `kyber_stage0_out.hex` into `out_val`; the log still reports NTT `out_observed[0]=0x595` vs `out_val[0]=0x815`, and INTT `out_observed[0]=0` vs `out_val[0]=0x815`. The vector files fill only 256 of 1,021-entry arrays. In `butterfly2x2_test`, the outer block loop iterates offsets 0, 64, 128, and 192, but input indexing uses only `j*4..j*4+3`, so after the first block it repeats the same 256 values. The checker only captures 256 outputs while the driver has four blocks. This is a testbench stimulus/vector-scope defect; it does not alone prove the cause of the first mismatch, whose exact stage/order mapping remains unverified. Archive: `raw/job-3140_76.tar.gz`, SHA-256 `881e1b927c43729d4c9448a00add3310c03ffcdc796578ce70964dc79e20e237`. The intern's filtered summary and manually checked full excerpt are saved beside this README. M16's older pinned-only gate also failed, so this is not evidence of a c339-specific compatibility defect.

The row76 output tree was removed after archive verification; cleanup freed 1,652,271 bytes (`remote-cleanup-row76-3140.txt`).

## Rows 93 and 97

Both tasks were still running when this note was written. Prior M18 log excerpts and verified intern summaries are saved as `row93-m18-log-excerpt.txt`, `row93-m18-log-triage-intern.txt`, `row97-m18-log-excerpt.txt`, and `row97-m18-log-triage-intern.txt`. Append terminal pin observations, result archives/hashes, and cleanup data here after the jobs finish.

## Terminal outcomes; trace wrapper defect

Array 3140 completed. Row 93 is a runner `FAIL` in 1,415.732 s: 16 scoreboard AHB mismatches at 0xd8–0x114, each actual value zero and expected value nonzero; UVM_ERROR=16, UVM_FATAL=0. Row 97 is a runner `FAIL` in 824.59 s: one scoreboard UVM error comparing the two verification runs; UVM_FATAL=0. Its sequence logged all 32 `MLDSA_VERIFY_RES` words as zero, and the log contains `* TESTCASE PASSED`; the runner still correctly classifies the nonzero UVM error as FAIL. Neither output contains `M19_AHB_PIN` lines or a `m19_trace_manifest.json`.

The trace wrapper did not intercept `run_logged()`: `runpy.run_path()` returns a mapping separate from the globals mapping captured by loaded functions. These two functional outcomes are terminal evidence, but they do not answer the pin-level attribution question. Row 93 triage is `row93-log-triage-intern.txt`; row 97 triage is `row97-log-triage-intern.txt`. Both were checked against their archived logs.

- Row 93 full task archive: `raw/job-3140_93.tar.gz`, SHA-256 `43b50e8661553e8d2caf6751f0e48f3c8044b64156865c6d000b3df24fb2ca10`.
- Row 97 full task archive: `raw/job-3140_97-complete.tar.gz`, SHA-256 `8308c3ea5a94fdbeb729ad3524be60c8980fd7a2ce01c140797a95d748f2e8c6`.
- Row 76 remains a separate terminal FAIL archive `raw/job-3140_76.tar.gz`, SHA-256 `881e1b927c43729d4c9448a00add3310c03ffcdc796578ce70964dc79e20e237`.
- The helper defect is corrected and insertion self-checked in `../mldsa-row97-ahb-pintrace-gate-20261019-01/`; its one-row gate runs row 97 before repeating row 93.
