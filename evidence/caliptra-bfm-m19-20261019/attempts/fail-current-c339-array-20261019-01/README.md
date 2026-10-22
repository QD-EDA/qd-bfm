# Current-c339 comparison for inherited and queue-underflow FAIL rows (prepared)

This six-row array reruns inherited rows 31, 57, 62, and 71 on current c339, and captures an observation-only valid/zeroize/queue-depth trace for rows 56, 62, 69, and 71. Row 76 is included in the later pin-trace array as an uninstrumented current-pin comparison. Each test has a 600-second cap; the array uses four concurrent one-CPU, 2-GiB tasks.

- Rows: 31, 56, 57, 62, 69, 71.
- Queue trace mode: rows 56, 62, 69, 71. The expected result queue and checker logic remain unchanged.
- The pinned source snapshot and Icarus hashes are the same as array 3100; the source snapshot is reused by hash, not modified.
- `run.sbatch` SHA-256 `7ff15a77b6868fa936a68a6482033e5d2f7f7d3a92efff2144a91541d747d6e1`; `bash -n` passes. The trace helper passed the recorded self-check in `../trace-runner-20261019-01/README.md`.
- Row31's inherited M17 log excerpt is `row31-m17-log-excerpt.txt` (SHA-256 `7b1fa2acc96cfc8ef812bb6b82e56cd65baf95eac9a768ca41e336a0761551b2`); it shows the status read/write and later `error_internal_intr_r=0b1010`, but does not prove the bus write caused those status bits.
- This array is prepared but not submitted until row77 job3110 is terminal. The four queue-trace target source files were found on the protected Adams Bridge pin; each has the four required signals and exactly one `// Scoreboard` anchor. SHA-256s are recorded in `queue-trace-anchor-preflight-20261019.txt` (record SHA-256 `0da9a1144a0eb9f5487c36af8734ca55e01b19e28b16f2f09ea2fbd653abdf94`).

Result: pending.
