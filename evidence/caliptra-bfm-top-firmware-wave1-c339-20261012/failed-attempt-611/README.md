# Job 611 setup failure

All 44 array tasks exited before simulation. Their wrapper logs say `outcome=FAIL`, but each per-task `runner.log` has the same 86-byte message: `Caliptra full-top BFM run failed: missing native vector inputs: ['openssl_libcrypto']`. No `result.json` or simulator log was produced, so these are setup failures and carry no firmware verdict. The distinct runner-log hash occurred 44 times.

The runner derives the OpenSSL prefix from `shutil.which('openssl')`. With the system executable at `/usr/bin/openssl`, it derived `/usr` and looked for `/usr/lib/libcrypto.so`; this host instead installs it under `/usr/lib/x86_64-linux-gnu/libcrypto.so`. A protected prefix was added at `/home/dsell/toolchains/iverilog-c339/openssl`, and the runner's native-vector preparation later succeeded as Slurm job 659. Job 660 is the corrected retry for rows 8–51; see [`../resubmission-20261012-04/README.md`](../resubmission-20261012-04/README.md).

`summary.tsv` lists all 44 failed setup attempts. The 44 raw Slurm output logs are in `logs/`; `task-8-diagnostic/` preserves one representative runner error and provenance.
