# Full-top random-DMA reset-window diagnostic — 2026-10-10

This is a diagnostic reset-timing experiment, not Caliptra or BFM qualification.
It uses one `rand_test_dma` transfer with the fast-TRNG and fast-boot-data
options. The runner requires both a completed testcase and an AXI write still
outstanding when reset asserts.

## Pinned inputs

- QD-BFM source: `708e51cd304422f367a61064449c5617fc97fec6` (clean)
- Runner SHA-256: `ea57294b045c7cae66a8aa6b93692a4c1ae8b343160624e0f137b71d855c6cb0`
- AXI trace source SHA-256: `cf378ed88ab6c3ec39fd38d3767d64a5598ad05a7afee63e90b5799743e09ae5`
- Icarus: `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, clean and contained in
  `origin/main`
- UVM core: `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`
- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`

## Job 216: early-reset calibration

The job requested 1 CPU, 4 GB, and two hours. Reset asserted at cycle 2577
(`start=2511`, `wait=64`) with zero outstanding AXI writes. The runner therefore
reported `reset_in_flight=false`; this run does not exercise reset during an
AXI write. The simulator exited `-11` before a finish marker, after trace output
had progressed to cycle 28700. The runner result is FAIL (`runner_exit=1`).
The cause of the simulator exit is not determined here.

`/usr/bin/time -v` measured a maximum RSS of 1,859,452 KiB. The earlier live VVP
snapshot was about 1,051,936 KiB, so it understated the completed run's peak.

Raw logs, result JSON, source revisions, tool hashes, and the Slurm resource
record are in [`job-216/`](job-216/); `SHA256SUMS` records their hashes.

## Job 218: completed reset-window attempt

Job 218 ran delays 3127 and 3150 cycles with 1 CPU and 2 GB per task, at most
two concurrent. Both simulations exited 0 and printed one testcase pass marker,
but the runner correctly returned FAIL because the reset was not in-flight. The
trace shows AW6 at cycle 5327 and B6 at 5356; reset asserted later at cycles
5640 and 5663, after all six writes had completed. Each result records
`outstanding_writes_at_reset=[0]` and `reset_in_flight=false`.

The measured MaxRSS values were 1,860,292 KiB and 1,860,328 KiB. The complete
array script and raw run records are in [`job-218/`](job-218/).

## Job 227: targeted reset run inconclusive

Job 227 used the calibrated delays 567 and 2822 with 1 CPU and 3 GB per task.
Both VVP processes exited `-11` before the scheduled reset request at cycle
2511. Neither log contains a reset assertion, testcase pass/fail marker, or
finish record; the last CPU trace samples were cycles 100 and 600. These runs
provide no evidence about in-flight reset behavior; the crash cause is not
localized. Their measured MaxRSS values were 1,860,240 KiB and 1,860,224 KiB.
Raw records and the exact submitted script are in [`job-227/`](job-227/).

The trace calibration remains valid: reset delay 567 targets cycle 3080 between
AW1 at 3066 and B1 at 3106. The separate delay 2822 targets cycle 5335 between
AW6 at 5327 and B6 at 5356.

## Job 231: control and first in-flight reset window

The no-reset control passed with `sim_exit=0`, one testcase pass marker, and no
reset assertion. The 567-cycle reset run also passed: reset asserted at cycle
3080, after AW1 at 3066 and before its response, with
`outstanding_writes_at_reset=[1]` and `reset_in_flight=true`. It exited 0 with
one testcase pass marker and a finish record. This is diagnostic full-top
in-flight-reset evidence under fast-TRNG/fast-boot overlays, not qualification.

The measured MaxRSS values were 1,859,936 KiB for control and 1,860,128 KiB for
the reset run. Raw results, logs, revisions, and the exact array script are in
[`job-231/`](job-231/).

The later write-response window at delay 2822 (assert cycle 5335 between AW6 at
5327 and B6 at 5356) remains unverified; job 227 exited before reaching it.
