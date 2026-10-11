# Caliptra BFM environment matrix: pinned c339 follow-up

The 44 frozen Caliptra/Adams Bridge filelists were classified against Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`) and the pinned Caliptra/Adams Bridge sources recorded in each run. The current matrix is in `docs/conformance/caliptra_bfm_dv_environment_matrix_2026-10-10.csv`.

## Current classifications

- PASS: 12
- BLOCKED: 29
- FAIL: 3
- UNVERIFIED: 0

PASS requires an explicit testcase pass marker, no error/failure diagnostics, and zero simulator exit. Several runs exited zero but could not qualify: the Adams Bridge testbenches lacked their generated vectors or Python dependencies (`python`/NumPy), and `ntt_top_tb` initially ran from a directory that did not contain `ntt_unmasked_input.hex`. The corrected CWD run found the file, but it contains only 64 words for a requested 16,384 and the test prints no pass marker, so the row remains setup-blocked. The csrng_tb filelist omits a required RAM package, and el2_veer_wrapper_tb has a testbench/RTL port mismatch. The caliptra_top_ss_mode_tb and caliptra_top_trng_tb filelists hit the intentional Axi4PC missing-VIP sentinel because the external ARM VIP source is unavailable. soc_ifc_tb omits the assignment-pattern apostrophe required before the associative-array initializer brace; adding it makes the minimal source compile on c339 ([Accellera committee guidance](https://www.accellera.org/images/eda/sv-ec/7572.html)). butterfly_top_tb exceeds VVP’s 512-flag code-generation limit. A reduced 505/506-element reproducer and boundary control are filed as [Icarus issue #538](https://github.com/dsellerbrock/iverilog-uvm/issues/538). The FAIL rows are cbd_sampler_tb and rej_bounded_tb, whose pinned generators overfeed the final SHAKE block, plus sigencode_z_tb, whose all-X outputs are now traced to a packed-struct assignment width bug in Icarus c339 (minimal comparison preserved under `reproducers/icarus-struct-assignment-width/`). The two exhaustive masked NTT rows are BLOCKED on runtime: each compiled successfully and ran to the 6,900-second limit without a terminal result.

## Runs and host changes

- Ghost array 325 was cancelled after its RUNNING tasks outlived the host uptime and had no matching processes.
- Array 367 used a fresh run directory and produced evidence for 18 rows before the WSL host became unreachable. The user-directed Mac fallback began; its masked Barrett row was stopped when the host returned and a Slurm replacement started.
- After the host returned, 18 rows with existing Slurm/local c339 evidence were excluded. Fresh array 388 ran only `masked_barrett_redux_tb` and `mlkem_masked_gs_butterfly_tb`, two tasks at 1 CPU/3 GiB each, throttle 2. Both c339 compiles exited 0 (compile resource logs); both simulations reached the 6,900-second timeout with no terminal testcase result. No job 388 task remained at reconciliation.
- Array 408 was initially submitted with those two already-evidenced runtime rows plus `ntt_top_tb`. After reconciling against local/Slurm c339 evidence, the duplicate masked NTT tasks were cancelled. The corrected `ntt_top_tb` run staged its test-vector files in the runtime working directory, compiled and simulated to exit 0, but found an undersized input vector and printed no testcase pass marker. Its row remains setup-blocked; complete logs and tool provenance are preserved in `slurm-408/`.
- Corrected shared Adams Bridge include paths were exercised by array 433 on `decompose_tb` and `norm_check_tb`. Both runs passed preprocessing and reached later compile errors: the testbenches refer to removed `MLDSA_MEM_ADDR_WIDTH`, and `decompose_tb` also connects the absent `w1_encode_done` port. The c339 logs and exact submitted script are preserved in `slurm-433/`. A follow-up audit found pinned c339 evidence for all 44 matrix rows, so no duplicate array was submitted.

The remote run archives, row manifests, submission records, local fallback logs, and tool provenance are preserved beside this report. The fresh source archive SHA256 is `193745f235f14c7095f876266b3b32b9999cb5a21483cbcac186e16388b7435b`.

## Corrected NTT top run

Array 408 staged the test-vector directory into the simulation CWD. Compile and simulation both exited 0 after 410 seconds, but `$readmemh` warned that `ntt_unmasked_input.hex` has only 64 words for the requested 16,384, and the test emitted no explicit pass marker before `$finish`. The row remains BLOCKED on setup; raw logs, hashes, tool versions, and host details are preserved in [slurm-408](slurm-408/README.md).

## Python setup repair

Array 414 supplied a run-local `python`/`python3` and NumPy environment. `power2round_tb` then passed all 2,048 cases. `rej_bounded_tb` generated its vector files and reported a testcase failure; `sigencode_z_tb` generated input/output files but reported output mismatches. Their archived logs and dependency provenance are in [slurm-414](slurm-414/README.md).

## Behavior-failure triage

The CBD and bounded-rejection failures are test-vector length mismatches. Both Python generators emit each full 136-byte SHAKE block into `input_vectors.txt`, while truncating `exp_results.txt` to 256 coefficients. The testbenches stream the full input block, then flag valid output groups after the 256 expected values have been consumed. The pinned c339 logs show 10 such queue-underflow events for CBD and 8 for bounded rejection; preceding expected/actual values match. This identifies the vector generator/testbench boundary as the cause, rather than a demonstrated RTL mismatch. For `sigencode_z_tb`, instrumented c339 output showed zero memory writes. The minimal reproducer confirms the cause: Icarus loses the enum member when a 32-bit address expression is assigned to the 14-bit packed-struct address field, leaving write requests idle. Verilator 5.051 preserves the enum; explicitly casting the address field also preserves it on c339. The standard requires each structure assignment-pattern member expression to be evaluated in the context of that member's type (IEEE 1800-2017 §10.9.2, [standard text](https://fpga.mit.edu/6205/_static/F25/documentation/1800-2017.pdf)).
