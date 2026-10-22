# KeyVault M17 staging attempt 06

This attempt did not reach compilation or simulation. Slurm array job 2874 ran rows 7, 9, and 10; each `runner.log` reports that `scripts/run_with_memory_pressure_guard.py` is missing from the staged source snapshot. The exact runner command and result JSON are retained in `raw/job-2874.tar.gz`.

The archive hash is `619305d5f7881eacf73214e8f9c3e2749a4420c75b376c7171866c59209485c5`. This is a source-staging failure, not a DUT/test result, so these rows remain pending for a fresh run with the omitted tracked helper staged.
