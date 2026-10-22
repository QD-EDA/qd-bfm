# Row 97 combined ML-DSA command-width gate

This one-row gate reuses the exact immutable source snapshot from `../mldsa-command-width-row93-c339-gate-20261020-04/` (SHA-256 `352fddead2b8fa45be98b6916b77cccb5f2cc0cc05e0ea5117a30d49fa154ef9`). The local hard links share the archived bytes without creating another source copy.

The per-run overlay sizes the predictor command expression and both sign/verify sequence command literals. It changes testbench setup only. The gate uses local Icarus c339, one thread, a 1,800-second row timeout, and a 2,100-second `localrun` cap.

Prepared after row 93 attempt04 started. Run only after row 93 reaches a terminal result, preserving one heavy local simulation at a time. Record command, host/tool hashes, exit code, wall time, peak RSS, result JSON, log, and archive SHA before updating M20 row 97.

Local preflight did not reach compile because the runner defaulted to the unavailable `/home/dsell/toolchains/...` path. The pinned Caliptra and Adams Bridge checkout is present at `/private/tmp/m20-caliptra-c339-20261020`; a follow-up attempt sets that root explicitly. The runner returned `BLOCKED` before simulation. This is setup evidence only and does not change row 97's M20 classification.
