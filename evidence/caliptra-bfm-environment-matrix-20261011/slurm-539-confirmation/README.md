# Shared-fix reruns and #539 confirmation

## One-array shared setup rerun

Array 511 ran four tasks on DAN-DESKTOP with Icarus c339 `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, one CPU and 3 GiB per task, throttle 4, and a 600-second test timeout. Python 3.14.4 and NumPy 2.5.4 were available for the Adams vector testbenches. The source snapshot records Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.

- `csrng_tb`: PASS. The run-local filelist moved the existing RAM package ahead of its importer and added `src/integration/rtl/caliptra_reg` to include paths. Compile and simulation exited 0; the log has one pass marker.
- `power2round_tb`: PASS with Python/NumPy present; compile and simulation exited 0 with one pass marker.
- `cbd_sampler_tb`: compile and simulation exited 0, but the test failed with 10 `Not enough valid samples in the queue` events after expected results were consumed.
- `rej_bounded_tb`: compile and simulation exited 0, but the test failed with 8 of the same queue-underflow events.

The two vector failures reproduce the documented generator/testbench boundary: each generator emits a full 136-byte SHAKE block while the expected result vector ends at 256 coefficients. The newly generated vectors and their hashes are retained in each task's `runtime/` and `generated-files.sha256`. The exact task results, logs, resources, versions, manifests and host snapshot are under `results-511/`.

Run directory on DAN-DESKTOP: `/home/dsell/slurm-runs/caliptra-bfm/a2/sharedfix-rerun-c339-20261011-01`. Submission: job 511. No task remains in the Slurm queue.

## Isolated #539 check

Job 510 used a fresh copy of the pinned source and Icarus c339. The testbench's stale `.MEM_ADDR_WIDTH(...)` override was removed in that copy to permit compilation. The only RTL change for the #539 experiment was an explicit `ABR_MEM_ADDR_WIDTH'(...)` cast around the two `pkdecode` write-address expressions.

The uncast array 502 baseline produced 4,096 mismatch lines whose `Got:` values were all X. With the casts, the test produced 2,048 output words, none X; 887 values were distinct and 1,790 comparisons still mismatched. Both compile and simulation exited 0, but there is no pass marker and the mismatch count disqualifies the run. This is a controlled confirmation that the packed assignment bug explains the all-X symptom, not a claim that pkdecode passes.

The isolated source patch and complete job 510 output are under `run-02/`; the failed wrapper-only setup attempt 509 is retained under `run-01/` and is not counted as test evidence. `attribution.md` records the corresponding trigger patterns in `pkdecode`, `sigdecode_z`, and `skencode`. The pinned source and Icarus were left untouched.

## Existing Axi4PC adapter run

The narrow QD-BFM `Axi4PC` adapter already exists at `dv/caliptra_bfm/axi/arm_axi4pc_compat/Axi4PC.sv`. Array 464's evidence in `slurm-vip-adapter/` shows it was accepted by both actual-top compiles; Icarus then rejected mixed continuous/procedural drivers and the testbench clock generator. Neither simulation ran. The adapter and both reruns are documented in the main matrix report.
