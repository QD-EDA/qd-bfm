# Job 823 row 31 first overlay attempt

Job 823 task 3 used QD-BFM commit `0b5efd3fa67ee7e68d62914c403128ba8f400948`
and the first errortrigger5 overlay (`caliptra-errortrigger5-abr-compat.h`,
SHA-256 `fba9c26c4f768cecf2b32a6753c829d555adc2d532a6b4565d1640e59ade029b`).
The header was force-included and supplied both missing no-op ABR hooks, but
firmware compilation then failed in shared `mldsa.c` because this case's
interrupt record has `mldsa_error`/`mldsa_notif`, not the stale
`abr_error`/`abr_notif` names.

The runner reported `FAIL`, reason `firmware_build_failed`, exit 1, elapsed 36
seconds, and no heartbeat. The compiler did not reach firmware link, HDL
compilation, or simulation. The raw firmware log, resource log, status, copied
compatibility header, and Slurm output are preserved here. This is a failed
overlay development attempt; job 826 is the corrected final retry for row 31.
