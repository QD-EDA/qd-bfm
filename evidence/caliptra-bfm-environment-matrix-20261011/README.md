# Caliptra BFM environment matrix: pinned c339 follow-up

The 44 frozen Caliptra/Adams Bridge filelists were classified against Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`) and the pinned Caliptra/Adams Bridge sources recorded in each run. The current matrix is in `docs/conformance/caliptra_bfm_dv_environment_matrix_2026-10-10.csv`.

## Current classifications

- PASS: 11
- BLOCKED: 30
- FAIL: 1
- UNVERIFIED: 2

PASS requires an explicit testcase pass marker, no error/failure diagnostics, and zero simulator exit. Several runs exited zero but could not qualify: the Adams Bridge testbenches lacked their generated vectors or Python dependencies (`python`/NumPy), and `ntt_top_tb` ran from a directory that did not contain `ntt_unmasked_input.hex`. Those rows are setup-blocked. The csrng_tb and el2_veer_wrapper_tb compile failures are also setup/filelist blockers. soc_ifc_tb omits the assignment-pattern apostrophe required before the associative-array initializer brace; adding it makes the minimal source compile on c339 ([Accellera committee guidance](https://www.accellera.org/images/eda/sv-ec/7572.html)). butterfly_top_tb exceeds VVP’s 512-flag code-generation limit. The remaining FAIL is cbd_sampler_tb, which reports an explicit testcase failure. The two remaining UNVERIFIED rows are exhaustive masked NTT tests that ran for the full 6,900-second per-test limit without a terminal result.

## Runs and host changes

- Ghost array 325 was cancelled after its RUNNING tasks outlived the host uptime and had no matching processes.
- Array 367 used a fresh run directory and produced evidence for 18 rows before the WSL host became unreachable. The user-directed Mac fallback began; its masked Barrett row was stopped when the host returned and a Slurm replacement started.
- After the host returned, 18 rows with existing Slurm/local c339 evidence were excluded. Fresh array 388 ran only `masked_barrett_redux_tb` and `mlkem_masked_gs_butterfly_tb`, two tasks at 1 CPU/3 GiB each, throttle 2. Both c339 compiles exited 0 (compile resource logs); both simulations reached the 6,900-second timeout with no terminal testcase result. No job 388 task remained at reconciliation.

The remote run archives, row manifests, submission records, local fallback logs, and tool provenance are preserved beside this report. The fresh source archive SHA256 is `193745f235f14c7095f876266b3b32b9999cb5a21483cbcac186e16388b7435b`.
