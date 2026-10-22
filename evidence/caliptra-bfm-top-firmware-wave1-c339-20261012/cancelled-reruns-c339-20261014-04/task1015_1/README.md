# Array 1015_1: source row 37

- Test: smoke_test_ecc_errortrigger4
- Outcome: TIMEOUT (raw status file: INFRA_ERROR; runner exit 137)
- Classification evidence: the timed command ran for exactly 17,281 seconds, matching its per-test `timeout` cap; Slurm reports this array element COMPLETED with ExitCode 0:0, not a job cancellation or allocation timeout.
- Endpoint mcycle: 6221 (latest-heartbeat)
- Last progress: wall 17100s, heartbeat mcycle 6221 (53 heartbeats)
- Per-test cap / elapsed: 17281s / 17281s
- Peak RSS: 1852632 KiB; the 3-GiB task allocation remained below its memory limit.
- Raw task evidence is checksum-verified in this directory; the simulator log and result JSON (when present) are preserved.
- Cleanup: 377,229,438 bytes of output/cache were removed after evidence was copied and checked.
