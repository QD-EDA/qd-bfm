# M5b instrumented rerun array

This fresh array will rerun the original 17 pending rows and all terminal TIMEOUT rows from the old uninstrumented run. It uses one CPU and 3 GiB per task, a six-task array throttle, a six-hour per-test cap with a 6h10m allocation, SIGINT followed by a 60-second kill grace, line-buffered VVP output, and the mcycle VPI heartbeat. Rows are ordered shortest first.

The selection is finalized after job 669 has no more running tasks and the separate `smoke_test_kv` heartbeat verification passes. This preserves the original running work and avoids overlapping reruns. Each task records its latest heartbeat in `status.txt` and `sim.log`; a timeout is called a hang only if mcycle remains flat for at least 30 minutes.

[`results.tsv`](results.tsv) is the live 42-row ledger for array 799. Terminal
rows include the verdict and final mcycle; active rows include their latest
heartbeat, and queued rows remain PENDING. Exit-137 timeout corrections and
their raw artifacts are detailed in [`timeout-reclassification-799/`](timeout-reclassification-799/).

Status: the final 42-row selection is prepared: 25 terminal timeouts plus the original 17 rows, sorted by expected mcycle cost. Job 669 is terminal. Smoke verification job 785 passed: the runner exited 0, the result JSON reports `passed=true` for `smoke_test_kv`, and the simulator has one PASS marker with no failure markers. Its two heartbeats show mcycle advancing from 0 to 1,722 by 300 seconds. The first submission attempt was rejected because Slurm no longer recognized completed job 785 as a dependency; no tasks started. Since the PASS is verified, the final array script omits that stale dependency. The 42-row array was submitted successfully as job 799 at 01:53 MDT on 2026-10-13 (1 CPU, 3 GiB, 6h10m, throttle 6). At 02:07, tasks 1–6 were RUNNING with three heartbeat records each; mcycle increased from 0 to 4,306–4,347 by 600 seconds. At 02:59, those same six tasks were still RUNNING with 14 heartbeats each, with mcycle at 27,381–27,548 at wall time 3,900 seconds; tasks 7–42 were pending at throttle 6. No terminal markers were present and no task met the hang condition. The [02:07 snapshot](heartbeat-snapshot-20261013-0207.txt) and [02:59 snapshot](heartbeat-snapshot-20261013-0259.txt) record the live values.

At 04:12 MDT, tasks 1–6 had each exited 137 at exactly their configured timeout (6,775–7,628 seconds). The wrapper's `INFRA_ERROR` label is therefore corrected to `TIMEOUT`; their last mcycles are recorded in [`timeout-reclassification-799/results.tsv`](timeout-reclassification-799/results.tsv), with raw status and resource logs alongside it. Peak RSS was about 1.85 GiB under the 3 GiB cap, and no adjacent heartbeat samples repeated mcycle. Tasks 7–12 were still running and advancing at the latest check; tasks 13–42 remained pending at the array throttle.

At 04:25 MDT, tasks 7–12 were still running. Their latest mcycles ranged from 10,431 to 14,979, with no repeated adjacent mcycle samples; tasks 13–42 remained pending at throttle 6. The [04:25 snapshot](heartbeat-snapshot-20261013-0425.txt) records the six heartbeat values and the overlay job progress.

At 06:49 MDT, task 11 had exited 137 at exactly its 10,091-second cap; its
latest simulator heartbeat was `wall_s=9900 mcycle=67671`, with no testcase
terminal marker. This is classified as TIMEOUT in
[`timeout-reclassification-799/results.tsv`](timeout-reclassification-799/results.tsv).
Tasks 12–17 were running with advancing heartbeats; their latest
`wall_s/mcycle` pairs were 10,200/71,202; 3,300/21,788; 3,000/20,147;
1,800/12,200; 900/5,864; and 300/1,945. Tasks 18–42 were pending at throttle 6.
Overlay retry 826_1 was also running, with latest heartbeat
`wall_s=9300 mcycle=64274`; no observed mcycle window was flat for 30 minutes.

At 07:07 MDT, task 799_12 (`c_intr_handler`) reached its 10,813-second
per-test timeout and is recorded as TIMEOUT with final heartbeat
`wall_s=10500 mcycle=73262`. Tasks 799_13–18 were running with advancing
heartbeats; tasks 19–42 remained pending at throttle 6. Overlay retry 826_1
remained active, with latest heartbeat `wall_s=10200 mcycle=2882`; its mcycle
value decreased between the 9,600- and 9,900-second samples, and no terminal
marker/result was present. See [`heartbeat-snapshot-20261013-0707.txt`](heartbeat-snapshot-20261013-0707.txt).

At 07:55 MDT, tasks 799_13–18 were still running with all six mcycle
heartbeats advancing; tasks 19–42 remained pending at throttle 6. Overlay
retry 826_1 was also running, at `wall_s=13200 mcycle=24461`. Current values
are in [`heartbeat-snapshot-20261013-0755.txt`](heartbeat-snapshot-20261013-0755.txt).

At 08:12 MDT, tasks 799_13–18 remained RUNNING with latest heartbeat pairs
`8100/55628`, `7800/54123`, `6600/45941`, `5700/38836`, `5100/35590`, and
`4200/29324`. Tasks 19–42 were PENDING; no active row had a result JSON or
testcase terminal marker. Overlay retry 826_1 was RUNNING at 3:59:53 with
latest heartbeat `wall_s=14100 mcycle=31005`, advancing from `28829` at
`wall_s=13800`. The [08:12 snapshot](heartbeat-snapshot-20261013-0812.txt)
records the queue and raw heartbeat values.

At 08:29 MDT, tasks 799_13–18 remained RUNNING with latest heartbeat pairs
`9300/64205`, `8700/60601`, `7800/54614`, `6900/47367`, `6000/42083`, and
`5100/35759`; tasks 19–42 remained PENDING. The six log pairs were advancing,
with no result JSON or testcase terminal markers. Overlay retry 826_1 remained
RUNNING at 4:16:38, with `wall_s=15300 mcycle=39698` and no terminal result.
See the [08:29 snapshot](heartbeat-snapshot-20261013-0829.txt).

At 08:40 MDT, tasks 799_13–18 remained RUNNING with latest heartbeat pairs
`9900/68484`, `9300/64893`, `8400/58958`, `7500/51642`, `6600/46409`, and
`5700/40070`. Tasks 19–42 remained PENDING. Each latest mcycle advanced from
its prior sample; no result JSON or testcase terminal marker was present.
Overlay retry 826_1 reached its 15,738-second per-test cap and is recorded as
TIMEOUT, with final heartbeat `wall_s=15600 mcycle=41872`; see the overlay
rerun evidence for status and resource logs. The [08:40 snapshot](heartbeat-snapshot-20261013-0840.txt)
records this queue state.

At 09:03 MDT, task 799_13 reached its 10,846-second cap and is recorded as
TIMEOUT with final mcycle 74,961. Tasks 799_14–18 remained RUNNING with latest
heartbeat pairs `10800/75743`, `9600/67713`, `8700/1983`, `8100/57470`, and
`7200/51137`; task 799_19 (`smoke_test_aes_gcm`) had started and reached
`wall_s=300 mcycle=2034`. Tasks 20–42 remained PENDING. No terminal markers
were found for active rows. Task 16's mcycle decreased from 58,129 at wall
8,400 to 1,983 at wall 8,700; the evidence does not identify why. See the
[09:03 snapshot](heartbeat-snapshot-20261013-0903.txt).

At 09:15 MDT, task 799_14 reached its 11,010-second cap and is recorded as
TIMEOUT with final mcycle 75,743. Tasks 799_15–18 were RUNNING at
`10500/74302`, `9600/8523`, `8700/61906`, and `7800/55590`; task 799_19
(`smoke_test_aes_gcm`) was at `1200/8478`, and task 799_20
(`smoke_test_dma_aes_gcm_short_1_dword`) was at `600/4198`. Tasks 21–42 were
PENDING. The mcycle drop for task 16 noted earlier has since increased; no
cause is inferred. See the [09:15 snapshot](heartbeat-snapshot-20261013-0915.txt).

At 09:34 MDT, task 799_15 reached its 11,240-second cap and is recorded as
TIMEOUT with final mcycle 78,702. Tasks 799_16–21 remained RUNNING with latest
heartbeat pairs `10800/17148`, `9900/70757`, `9000/64463`, `2100/14865`,
`1500/10649`, and `300/2071`; tasks 22–42 were PENDING. Task 16's mcycle had
fallen at wall 8,700 in the earlier sample, then rose to 17,148 by wall 10,800;
the evidence does not establish the reason for the earlier decrease. See the
[09:34 snapshot](heartbeat-snapshot-20261013-0934.txt).

At 09:51 MDT, task 799_16 reached its 11,240-second cap and is recorded as
TIMEOUT with final mcycle 19,222. Tasks 799_17–22 were RUNNING with latest
heartbeat pairs `11100/79384`, `9900/70883`, `3300/23093`, `2700/18891`,
`1500/10584`, and `300/2054`; tasks 23–42 were PENDING. Task 16's earlier
mcycle drop had been followed by advancing samples through its timeout; its
cause remains unknown. See the [09:51 snapshot](heartbeat-snapshot-20261013-0951.txt).

At 10:14 MDT, task 799_17 reached its 11,601-second cap and is recorded as
TIMEOUT with final mcycle 81,461. The wrapper status last shows mcycle 53,013 at
wall 7,500, while the full simulator log advances through wall 11,400; the
full log is used for the final mcycle. Tasks 799_18–23 remained RUNNING at
`11400/81586`, `4500/31335`, `3900/27117`, `2700/18809`, `1800/12542`, and
`600/4285`; tasks 24–42 were PENDING. No result JSON or testcase terminal
marker was present for active rows. See the
[10:14 snapshot](heartbeat-snapshot-20261013-1014.txt).

At 10:19 MDT, tasks 799_18–23 remained RUNNING at `11700/83780`,
`5100/35660`, `4500/31389`, `3000/20929`, `2100/14653`, and `1200/8693`;
tasks 24–42 remained PENDING. All six mcycle values advanced from the prior
snapshot. No result JSON or explicit PASS/FAIL marker was found for active
rows. See the [10:19 snapshot](heartbeat-snapshot-20261013-1019.txt).

At 10:44 MDT, task 799_18 reached its 12,257-second cap and is recorded as
TIMEOUT with final mcycle 85,975. The wrapper reports INFRA_ERROR and exit 137;
elapsed time matches the configured cap. The full log has 41 advancing
heartbeats through wall 12,000, with no 30-minute flat interval. Tasks 799_19–24
remained RUNNING at `6300/44228`, `5700/39945`, `4500/31617`, `3600/25138`,
`2700/19386`, and `900/6543`; tasks 25–42 remained PENDING. See the
[10:44 snapshot](heartbeat-snapshot-20261013-1044.txt).
