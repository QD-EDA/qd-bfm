# Gate 2663 invocation error

This was a harness invocation error, not a simulator result. The job passed `m15-results.tsv` to `run_m15_test.py`; that runner requires `m15-test-to-environment.tsv`, which contains the per-filelist hashes. It exited with `KeyError: filelist_sha256_json` before creating a row result or invoking Icarus.

The Slurm log, batch script, and job metadata are preserved here. No PASS/FAIL/BLOCKED/TIMEOUT status is assigned to row 96 from this attempt. The run directory will be removed after preserving these files.
