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
build, and started VVP. At the 07:55 MDT queue check it had run 3:42:43. Its
latest heartbeat is `wall_s=13200 mcycle=24461`, advancing from mcycle 22,278
at wall 12,900. No terminal marker or result JSON is present. Earlier the mcycle
value decreased from 66,375 at wall 9,600 to 749 at wall 9,900; the evidence
does not establish why. The final outcome and mcycle will be recorded here
after the row reaches a terminal result.

At 08:12 MDT, it remained RUNNING at 3:59:53. The latest heartbeat was
`wall_s=14100 mcycle=31005`, advancing from 28,829 at wall 13,800. No terminal
marker or result JSON was present.
