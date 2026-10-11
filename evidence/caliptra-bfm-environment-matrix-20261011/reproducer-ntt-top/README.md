# NTT top working-directory check

The pinned c339 build compiled `ntt_top_tb` and VVP finished in 1027.86 seconds, but the result is not a pass: `sim.log` has three `$readmemh` errors for `ntt_unmasked_input.hex`, followed by `$finish`, and no testcase pass marker. The missing vector is stored under `src/ntt_top/tb/test_vectors/`; the run used the testbench directory as its current working directory. Classify this row as setup-blocked until the harness supplies the vector at the path the testbench reads.

The earlier Slurm task 367 run of the same top exited with signal 11 after 0.58 seconds, but the local run did not reproduce that crash. With the working-directory error, this is not a minimized or confirmed Icarus defect.

Local tool and host provenance is in `host.txt`; full compile and simulation logs are in `local-mac/tasks/adams-bridge-v2-0-3-ntt_top_tb/`.
