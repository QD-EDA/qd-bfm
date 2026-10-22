# SoC-IFC row 43 overlay gate, retry 5

Fresh one-row gate after retry 4 reached another generated sequence with an implicit one-bit return type and failed before simulation. The overlay now supplies explicit `void` returns to `create_seqs`, `randomize_seqs`, and `create_and_randomize_seqs` throughout the pinned SoC-IFC sequence include tree. The change is limited to testbench method signatures; no method bodies, stimulus, transaction values, assertions, or pass criteria change.

Source pin and c339 binaries are unchanged. Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds. This is a one-row gate before running any other row with the updated overlay.

Job 3245 failed before the harness because its `source/` directory had not been extracted before `sbatch`; the archive, scheduler message, runner traceback, resource report, and job metadata are preserved under `raw/`. Archive `raw/job-3245_43.tar.gz` SHA-256: `e78c27e4af1cdf45ed4e30de45cc86f805c9a85734c4848b05ae4e8b67dd813d`. This is a staging failure, not a row result. Retry 6 will verify `source/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py` exists before submitting.
