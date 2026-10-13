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

Pending. Job 826 passed source and toolchain preflight, completed the firmware
build, and started VVP. At the 07:07 MDT queue check it had run 2:55:09. Its
latest heartbeat is `wall_s=10200 mcycle=2882`; the log reports mcycle 66,375
at wall 9,600 and 749 at wall 9,900, followed by 2,882 at wall 10,200. No
terminal marker or result JSON is present. The mcycle value decreases between
those samples; this note records the observed change without inferring its
cause. The final outcome and mcycle will
be recorded here after the row reaches a terminal result.
