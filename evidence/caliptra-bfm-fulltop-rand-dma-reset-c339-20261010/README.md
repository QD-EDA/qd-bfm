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

## Reset-window array

Slurm job 218 runs two independent timing points, with at most two tasks
concurrent. Each task requested 1 CPU and 2 GB, based on the live VVP snapshot
plus headroom available when submitted:

| Task | Reset delay | Run directory |
|---|---:|---|
| `218_0` | 3127 cycles | `runs/window-3127` |
| `218_1` | 3150 cycles | `runs/window-3150` |

The runner has no seed override, so these tasks vary reset timing. Job 216's
completed peak (1,859,452 KiB) became available after job 218 had started; the
2 GB requests leave only about 232 MiB against that measured peak. Do not alter
these running jobs; use at least 3 GB per task for comparable future runs.
Append their final results and resource peaks here when both tasks finish.
