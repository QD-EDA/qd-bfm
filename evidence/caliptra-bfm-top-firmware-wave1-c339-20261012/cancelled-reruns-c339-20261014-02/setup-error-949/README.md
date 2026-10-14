# Slurm array 949 staging failure

All four array tasks exited with code 1 within two seconds of start on 2026-10-14. Each wrapper log reports `sed: can't read .../selection.tsv: No such file or directory`. The script reads `$ROOT/selection.tsv`, but the submit command had staged that file only in `$ROOT/submit/`. No test runner, compiler, VVP process, per-test output directory, or heartbeat was created. This is a staging/setup error and provides no test outcome.

The four raw task logs are included here. Slurm's live queue was empty after they exited; `scontrol show job` showed start 07:38:08 MDT, end 07:38:09–10 MDT, and exit `1:0` for all tasks.
