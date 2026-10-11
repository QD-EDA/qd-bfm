# Caliptra BFM environment matrix: pinned c339 follow-up

The 44 frozen Caliptra/Adams Bridge filelists were classified against Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`) and the pinned Caliptra/Adams Bridge sources recorded in each run. The current matrix is in `docs/conformance/caliptra_bfm_dv_environment_matrix_2026-10-10.csv`.

## Current classifications

- PASS: 11
- BLOCKED: 32
- FAIL: 1
- UNVERIFIED: 0

PASS requires an explicit testcase pass marker, no error/failure diagnostics, and zero simulator exit. Several runs exited zero but could not qualify: the Adams Bridge testbenches lacked their generated vectors or Python dependencies (`python`/NumPy), and `ntt_top_tb` initially ran from a directory that did not contain `ntt_unmasked_input.hex`. The corrected CWD run found the file, but it contains only 64 words for a requested 16,384 and the test prints no pass marker, so the row remains setup-blocked. The csrng_tb filelist omits a required RAM package, and el2_veer_wrapper_tb has a testbench/RTL port mismatch. The caliptra_top_ss_mode_tb and caliptra_top_trng_tb filelists hit the intentional Axi4PC missing-VIP sentinel because the external ARM VIP source is unavailable. soc_ifc_tb omits the assignment-pattern apostrophe required before the associative-array initializer brace; adding it makes the minimal source compile on c339 ([Accellera committee guidance](https://www.accellera.org/images/eda/sv-ec/7572.html)). butterfly_top_tb exceeds VVP’s 512-flag code-generation limit. A reduced 505/506-element reproducer and boundary control are filed as [Icarus issue #538](https://github.com/dsellerbrock/iverilog-uvm/issues/538). The remaining FAIL is cbd_sampler_tb, which reports an explicit testcase failure. The two exhaustive masked NTT rows are BLOCKED on runtime: each compiled successfully and ran to the 6,900-second limit without a terminal result.

## Runs and host changes

- Ghost array 325 was cancelled after its RUNNING tasks outlived the host uptime and had no matching processes.
- Array 367 used a fresh run directory and produced evidence for 18 rows before the WSL host became unreachable. The user-directed Mac fallback began; its masked Barrett row was stopped when the host returned and a Slurm replacement started.
- After the host returned, 18 rows with existing Slurm/local c339 evidence were excluded. Fresh array 388 ran only `masked_barrett_redux_tb` and `mlkem_masked_gs_butterfly_tb`, two tasks at 1 CPU/3 GiB each, throttle 2. Both c339 compiles exited 0 (compile resource logs); both simulations reached the 6,900-second timeout with no terminal testcase result. No job 388 task remained at reconciliation.
- Array 408 was initially submitted with those two already-evidenced runtime rows plus `ntt_top_tb`. After reconciling against local/Slurm c339 evidence, the duplicate masked NTT tasks were cancelled. The corrected `ntt_top_tb` run staged its test-vector files in the runtime working directory, compiled and simulated to exit 0, but found an undersized input vector and printed no testcase pass marker. Its row remains setup-blocked; complete logs and tool provenance are preserved in `slurm-408/`.

The remote run archives, row manifests, submission records, local fallback logs, and tool provenance are preserved beside this report. The fresh source archive SHA256 is `193745f235f14c7095f876266b3b32b9999cb5a21483cbcac186e16388b7435b`.

## Corrected NTT top run

Array 408 staged the test-vector directory into the simulation CWD. Compile and simulation both exited 0 after 410 seconds, but `$readmemh` warned that `ntt_unmasked_input.hex` has only 64 words for the requested 16,384, and the test emitted no explicit pass marker before `$finish`. The row remains BLOCKED on setup; raw logs, hashes, tool versions, and host details are preserved in [slurm-408](slurm-408/README.md).
