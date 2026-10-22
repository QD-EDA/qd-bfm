# Corrected row 97 AHB pin-trace gate

The first M19 trace wrapper used `runpy.run_path()` and then replaced a function in the returned dictionary. Python gives the loaded functions a different globals dictionary, so the compiler hook did not run. The prior row 97 and row 93 results remain valid terminal functional outcomes, but neither contains the requested pin trace and neither is used to attribute the mismatch to DUT or monitor behavior.

This corrected wrapper executes the pinned base runner in a shared globals dictionary, then intercepts the actual `run_logged()` compile call. A local insertion self-check passed against the archived generated `hdl_top.sv`; the one-row Slurm gate below checks the emitted manifest and runtime trace before row 93 is repeated.

- Row: 97 (`ML_DSA_randomized_two_verif_on_fail_test`), one array task, 1 CPU, 2 GiB, 3,600-second runner cap, 4,500-second Slurm limit.
- Source snapshot SHA-256: `ce5ba73163820aea5c9c065f81bbd5758365f8fb0d78c5a2ca9949f300c2c284`.
- Icarus source pin: `cae035642e056644274a01e98d4422ce286685b4`; binary SHA-256: `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`.
- The prior row 97 run (job 3140) produced one scoreboard UVM error while all 32 `MLDSA_VERIFY_RES` reads logged zero. Its output-only archive is `../mldsa-result-pintrace-array-20261019-02/raw/job-3140_97-output-only.tar.gz`; the complete task archive is `../mldsa-result-pintrace-array-20261019-02/raw/job-3140_97-complete.tar.gz`.

Final gate job ID, manifest, trace evidence, verdict and cleanup size are appended after completion.

## Job 3147: hook worked, event filter did not

Job 3147 completed in 820.529 s with runner status `FAIL`, one `[SCBD_AHB]` / UVM_ERROR, zero UVM_FATAL, and the testbench's `* TESTCASE PASSED` marker. The compile-time trace manifest is present and the generated `hdl_top.sv` contains the observation code, but the runtime log has zero `M19_AHB_PIN` lines because the HSEL/HTRANS/address predicate never matched. The full archive is `raw/job-3147_97.tar.gz`, SHA-256 `41a3a69ea351800f55f8fc79e7c55803ea402d85ad3f730c7d0e8a668c61f841`; filtered intern triage is `job-3147-log-triage-intern.txt` and manually checked against the log. This is a trace miss; it adds no root-cause evidence.

The always-on per-clock observer is the next one-row gate at `../mldsa-row97-ahb-fullclock-gate-20261019-02/` (job 3151). It prints pre/post raw AHB pins without address/select filtering.
