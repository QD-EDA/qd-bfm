# Errortrigger5 compatibility overlay retry

This one-row retry covers only source row 31, whose case directory is
`smoke_test_ecc_errortrigger5` while its YAML still names itself
`smoke_test_ecc_errortrigger4`. The original pinned-only build stops on missing
ABR service hooks. Job 823's first overlay attempt supplied those hooks and
then exposed a second stale name in shared `mldsa.c`: it reads
`abr_error`/`abr_notif`, while this case's interrupt record has
`mldsa_error`/`mldsa_notif`. That failed attempt and its raw compiler log are
preserved under the first rerun directory's `attempt-01-row31/`.

The retry's case-specific header aliases those two field names and retains the
no-op hooks. It changes no test source, vectors, result checks, or pass criteria.

## Pins and execution

- Job 826, array task 1; DAN-DESKTOP, one CPU, 3 GiB, one task.
- QD-BFM commit: `8e34e0c6d20b6f84a5a975ba6e3de7ccd9b1dc2b`.
- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source: `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
- Test timeout: 15,738 seconds, matching the original row's cap.
- Compatibility-header SHA-256: `6dfaaf78aae3793745246d814859a45ba8c3d4a5236b6ba02b81e25c671bc6cb`.

## Result

TIMEOUT. Job 826 passed source and toolchain preflight, completed the firmware
build, and started VVP. The runner exited 137 at the configured 15,738-second
per-test cap; `status.txt` records `outcome=TIMEOUT`, and `resource.log`
reports a 4:22:18 elapsed run with maximum RSS 1,852,516 KiB. The final
heartbeat was `wall_s=15600 mcycle=41872`. There is no result JSON or testcase
PASS/FAIL/completion marker, so this is a timeout rather than a firmware
testcase verdict. Earlier the mcycle decreased from 66,375 at wall 9,600 to
749 at wall 9,900; the evidence does not establish why.

At 08:12 MDT, it remained RUNNING at 3:59:53. The latest heartbeat was
`wall_s=14100 mcycle=31005`, advancing from 28,829 at wall 13,800. No terminal
marker or result JSON was present.

At 08:29 MDT, job 826_1 remained RUNNING at 4:16:38. Its latest heartbeat
was `wall_s=15300 mcycle=39698`, advancing from 37,526 at wall 15,000. No
terminal marker or result JSON was present.

By 08:40 MDT, the job had timed out at its configured cap. Selected logs,
status, resource, provenance, tool versions, and compatibility header were
copied under `runs/31-eaeb97287ce63194-1/`; every copied artifact matches the
remote hash listed in [`REMOTE-SHA256SUMS.txt`](REMOTE-SHA256SUMS.txt). The
remote `output/` build tree was then removed. The Slurm output is preserved at
[`logs/bfm-fw-compat31-826_1.out`](logs/bfm-fw-compat31-826_1.out).
