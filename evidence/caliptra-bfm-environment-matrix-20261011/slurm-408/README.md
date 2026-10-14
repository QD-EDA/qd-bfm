# Slurm array 408 evidence

`ntt_top_tb` compiled and simulated on DAN-DESKTOP with the pinned c339 toolchain. Both stages exited 0 after 410 seconds, but the simulation emitted no testcase pass marker. It also warned that `ntt_unmasked_input.hex` supplied fewer than the requested 16,384 words (the staged file contains 64 lines). The test reached `$finish` with `End of test`; the row remains setup-blocked because its input vector is incomplete and no pass verdict is asserted.

The duplicate masked NTT tasks were cancelled after earlier valid c339 compile/runtime-timeout evidence was reconciled. They are not new test results. The per-row archives and cancelled Slurm output are retained under `tasks/` and `logs/`.
