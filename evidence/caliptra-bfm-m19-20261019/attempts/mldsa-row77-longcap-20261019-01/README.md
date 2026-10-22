# M19 row 77 longer-cap rerun

Row 77 was cancelled only for a diagnostic snapshot in array 3100 and has no terminal verdict. The first submission, job 3109, was invalid: a path replacement miss left `RUN`, `--chdir`, and `--output` pointed at the previous 3100 run root. It reused row 77's existing `native-models/dilithium-ref` directory, returned a `BLOCKED` setup error in 0.013 seconds, and did not simulate. Its archive and the submitted script are preserved below; do not count it as a row result.

The corrected `run.sbatch` now points all three paths at the dedicated `m19-row77-longcap-20261019-01` root. It retains the pinned c339 binaries and source snapshot, unchanged inputs, 1 CPU / 2 GiB, and a 3,600-second runner cap. `bash -n` passed.

- Job 3109 submitted script: `run-3109-submitted.sbatch`, SHA-256 `ff768f27f0dbe95c4967a82b4d47a6da19b8d18b1fe75c1cfeb20cfff0c9db9c`.
- Corrected `run.sbatch` SHA-256: `0d7d8dedb1e0315f0b6bdcc138f5d47585c02f970f314b21cb041634cd9b4f73`.
- Source snapshot SHA-256: `ce5ba73163820aea5c9c065f81bbd5758365f8fb0d78c5a2ca9949f300c2c284`.
- Job 3109's setup-error archive is `raw/job-3109_77-staging-error.tar.gz`, SHA-256 `5ce88c71d74a3bcc73e7bf5ff5a56cbda5095592e1e26e85925637b7cf1b8bc1`.
- Corrected job 3110 was RUNNING at 10:16:55 MDT in the dedicated root; its verified queue/workdir/compile snapshot is `slurm-status-3110-initial.txt` (SHA-256 `3581899391efe4e94f869b14a2071a080832ee7fc78339f369098b103c05e124`). Full submission pins and resource allocation are in `resubmission-3110.txt`.
- At 10:29:50 MDT, job 3110 was RUNNING at 12:59 elapsed / 1:02:01 remaining on its Slurm allocation. VVP was at 99.9% CPU / 378,688 KiB RSS; `sim.log` had not changed since 10:17:17 and ended at 200 ns waiting for the reset event trigger. This is not treated as a hang. Snapshot `slurm-check-20261019-1032.txt` SHA-256 is `6b0cf1cde1d1f0b3e3ded0615b15c070e834ccb9c4e743ba19874c70d15a2166`.
- At 10:42:07 MDT, job 3110 was RUNNING at 25:16 elapsed / 49:44 remaining on its Slurm allocation. VVP was at 99.9% CPU / 380,704 KiB RSS and had advanced through `MLDSA_PRIVKEY_OUT[1210]` at 230,395 ns; a trailing line reached 230,435 ns. No result JSON yet. This confirms simulation progress. Snapshot `slurm-check-20261019-1042.txt` SHA-256 is `4a534bce07f3a3b49c122b2552d9d0cf315ce5cbd0cd08ab47ce6b191e5f2e4a`.
