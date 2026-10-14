# AXI manager reset during stalled requests — 2026-10-09

The guarded `tests/run_master.sh` regression passed in Slurm job 107 using QD-BFM
base `00de2a636dd251d01c28a9dbddd7a5453bf7800d` plus the source files recorded
in `job107/qd-inputs.sha256`. Clean published Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` ran the complete manager suite.

The reset-abort case now resets the master during a stalled AR request, a
stalled AW request, and a W beat held after AW acceptance. It also retains the
existing read-data and write-response wait resets. Each operation returns
unsuccessful, clears the driven controls, and permits recovery. The existing
exclusive monitor is re-established after each reset before a locked write.

The first attempt, Slurm job 106, failed because the test attempted a locked
write after reset had correctly cleared the checker's exclusive-read state.
That test sequencing error and its raw diagnostic are preserved in
`attempt-106-fail/`; no BFM or checker behavior was changed to mask it.

Job 107 requested 256 MiB and one CPU, estimated from job 105's 17,600 KiB
MaxRSS for a similar Icarus test. It completed in 0.28 s with 17,568 KiB MaxRSS,
a maximum guarded process group reported as 0.00 GiB, and exit status zero. The
group cap was 150,000,000 bytes. `job107/` retains the Slurm script, output,
resource measurement, simulator hashes, and source manifest.

This adds reset coverage for these stalled request phases; it is not exhaustive
reset-at-every-cycle qualification or full Caliptra/UVMF qualification.
