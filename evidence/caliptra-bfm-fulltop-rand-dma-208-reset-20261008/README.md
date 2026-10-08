# Caliptra full-top 208-word DMA reset replay — diagnostic — 2026-10-08

**Result: incomplete diagnostic; no full-top firmware pass is claimed.** Both
guarded attempts reached the 3,600-second timeout (exit 124) without a firmware
pass or failure marker.

The traced run accepted the complete 208-beat AXI readback (AR=13, R=208)
after reset and entered the firmware's per-word payload comparison at PC
0x00001042. Its final trace had no fatal signal or recorded mismatch, but the
comparison and firmware testcase did not finish before timeout. Write totals
were AW=14, W=218, B=13: the 10 pre-reset W beats are included in W, and
the completed replay accounts for the 13 B responses.

The uninstrumented run also timed out. Its captured output ended after the
second ROM-flow announcement, so it provides no final CPU position or
pass/fail result. This does not establish an AXI failure. The traced run shows
that the remaining delay is after the AXI readback, in firmware execution.

This full-top result is separate from the passing four-word full-top reset
evidence and the passing 208-word DMA-block reset evidence. The full-top
208-word firmware path remains open.

## Run identity

| Input | Identity |
|---|---|
| Caliptra RTL | 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e |
| Icarus source HEAD | ac4532fab037e91df2f903e67fb40f59baedccca — dirty, unpublished |
| Icarus version | 13.0 (devel) (ac4532fa-dirty) |
| Firmware scenario | +CLP_REGRESSION +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=1 +CLP_SKIP_PQ_VECTOR_GENERATION |
| Guard | 3,600-second timeout; both attempts exited 124 |

These runs are diagnostic only because the Icarus build is dirty and
unpublished. Do not use them for qualification. Re-run on a clean, published
Icarus revision before making a qualification claim.

## Temporary log checksums

Raw logs remain in /private/tmp; they are not copied into this evidence
directory.

| Run | SHA-256 |
|---|---|
| Traced readback replay | 290f05cfa6576b834f5451bf1f116a872c1accd7745b114e886fb299e3a8a16f |
| Uninstrumented replay | 18ca01cfe318ad4d0ff5a72eb331f75d83bb6ed84e6f8d84860dfabc9a65ec48 |

## Current-state addendum — 2026-10-08

A later uninstrumented replay under a 5,400-second guard exited 0, emitted
`* TESTCASE PASSED`, and reached `$finish` (`minstret=7937`, `mcycle=28414`).
The earlier 3,600-second timeouts remain valid historical results; the later
run shows this full-top reset/replay scenario can complete with a longer bound.
It also logged `jtag0: Failed to bind socket: Operation not permitted (1)`.

This is still diagnostic only: it used the dirty, unpublished Icarus build
listed above, and the JTAG DPI socket bind warning remains. Do not use it for
qualification. The raw log remains in `/private/tmp`.

| Run | Guard result | SHA-256 |
|---|---|---|
| Uninstrumented replay, 5,400-second maximum | exit 0; testcase passed; `$finish` | e615d7e7a13090d2a249bfd5a7ef4b7cfc8c2d0f55c701912e0d63563b194ac3 |
