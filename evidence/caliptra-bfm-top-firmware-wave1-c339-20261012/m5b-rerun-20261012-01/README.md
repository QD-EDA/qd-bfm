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

At 10:58 MDT, tasks 799_19–24 remained RUNNING at `7200/50749`,
`6600/46476`, `5400/38195`, `4500/31576`, `3300/23730`, and `1800/13146`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [10:58 snapshot](heartbeat-snapshot-20261013-1058.txt).

At 11:09 MDT, tasks 799_19–24 remained RUNNING at `7800/55101`,
`7200/50833`, `6000/42603`, `5100/35932`, `4200/30299`, and `2400/17465`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [11:09 snapshot](heartbeat-snapshot-20261013-1109.txt).

At 11:20 MDT, tasks 799_19–24 remained RUNNING at `8700/61600`,
`8100/57353`, `6600/47024`, `5700/40292`, `4800/34727`, and `3000/21782`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [11:20 snapshot](heartbeat-snapshot-20261013-1120.txt).

At 11:31 MDT, tasks 799_19–24 remained RUNNING at `9300/65912`,
`8700/61687`, `7500/53633`, `6600/46844`, `5400/39166`, and `3900/28378`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [11:31 snapshot](heartbeat-snapshot-20261013-1131.txt).

At 11:42 MDT, tasks 799_19–24 remained RUNNING at `9900/70197`,
`9300/66015`, `8100/58021`, `7200/51209`, `6000/43613`, and `4500/32784`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [11:42 snapshot](heartbeat-snapshot-20261013-1142.txt).

At 11:52 MDT, tasks 799_19–24 remained RUNNING at `10500/74488`,
`9900/70304`, `8700/62423`, `7800/55567`, `6600/48068`, and `5100/37231`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [11:52 snapshot](heartbeat-snapshot-20261013-1152.txt).

At 12:03 MDT, tasks 799_19–24 remained RUNNING at `11100/78773`,
`10500/74581`, `9300/66831`, `8400/59923`, `7200/52520`, and `5700/41685`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [12:03 snapshot](heartbeat-snapshot-20261013-1203.txt).

At 12:13 MDT, tasks 799_19–24 remained RUNNING at `11700/83023`,
`11100/78833`, `9900/71236`, `9000/64258`, `7800/56955`, and `6300/46153`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [12:13 snapshot](heartbeat-snapshot-20261013-1213.txt).

At 12:24 MDT, tasks 799_19–24 remained RUNNING at `12300/87274`,
`11700/83079`, `10500/75633`, `9600/68579`, `8400/61352`, and `6900/50613`;
tasks 25–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was present for
active rows. See the [12:24 snapshot](heartbeat-snapshot-20261013-1224.txt).

At 12:35 MDT, task 799_19 reached its 13,210-second cap and is recorded as
TIMEOUT with final mcycle 91,549. The full log has 44 advancing heartbeats
through wall 12,900 and no 30-minute flat interval. Tasks 799_20–25 remained
RUNNING at `12600/89440`, `11100/80029`, `10200/72892`, `9300/67896`,
`7800/57293`, and `0/0`; tasks 26–42 remained PENDING. No terminal result was
found for active rows. See the [12:35 snapshot](heartbeat-snapshot-20261013-1235.txt).

At 12:49 MDT, task 799_20 reached its 13,341-second cap and is recorded as
TIMEOUT with final mcycle 93,689. Its log includes an internal `Test 1 PASSED`
line, but no row-level `* TESTCASE PASSED` marker or result JSON; the runner
was killed with exit 137 at the configured cap. Tasks 799_21–26 remained
RUNNING at `12000/86614`, `11100/2215`, `9900/72308`, `8400/61688`, `600/4244`,
and `0/0`; tasks 27–42 remained PENDING. Task 22's mcycle drop from wall 10,200
to 11,100 is unclassified; its latest sample had been unchanged for about 2.5
minutes, below the 30-minute hang criterion. See the
[12:49 snapshot](heartbeat-snapshot-20261013-1249.txt).

At 13:00 MDT, tasks 799_21–26 remained RUNNING at `12600/90981`,
`11700/6469`, `10800/78835`, `9300/68128`, `1500/10638`, and `600/4152`; tasks
27–42 remained PENDING. All six mcycle values advanced from the prior
snapshot. Task 22 advanced after its earlier mcycle drop, so the temporary
flat interval ended; no cause is inferred. See the
[13:00 snapshot](heartbeat-snapshot-20261013-1300.txt).

At 13:11 MDT, tasks 799_21–26 remained RUNNING at `13500/97352`,
`12300/10602`, `11400/83086`, `9900/72405`, `2100/14725`, and `1200/8256`;
tasks 27–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, including task 22 after its earlier drop. No result JSON or
testcase PASS/FAIL marker was found for active rows. See the
[13:11 snapshot](heartbeat-snapshot-20261013-1311.txt).

At 13:21 MDT, tasks 799_21–26 remained RUNNING at `14100/101621`,
`13200/16875`, `12000/87383`, `10500/76706`, `2700/18811`, and `1800/12460`;
tasks 27–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was found for active
rows. See the [13:21 snapshot](heartbeat-snapshot-20261013-1321.txt).

At 13:32 MDT, tasks 799_21–26 remained RUNNING at `14700/105976`,
`13800/21123`, `12600/91737`, `11100/81086`, `3300/22990`, and `2400/16563`;
tasks 27–42 remained PENDING. All six mcycle values advanced from the prior
snapshot, and no result JSON or testcase PASS/FAIL marker was found for active
rows. See the [13:32 snapshot](heartbeat-snapshot-20261013-1332.txt).

At 13:47 MDT, task 799_21 (`jtag_tap_mbox`) exited 137 at its exact
15,212-second cap and is recorded as TIMEOUT. Its full log has 50 heartbeats
through `wall_s=15000 mcycle=108152`, no repeated adjacent mcycle, no testcase
terminal marker, and no result JSON. Maximum RSS was 1,852,512 KiB. Tasks
799_22–27 were RUNNING at `14700/27337`, `13500/98165`, `12000/87510`,
`4200/29214`, `3600/24759`, and `300/1921`; tasks 799_28–42 were PENDING. No
result JSON or exact testcase PASS/FAIL marker was found for active rows. See the
[13:47 snapshot](heartbeat-snapshot-20261013-1347.txt).

At 14:08 MDT, task 799_22 (`iccm_lock`) reached its exact 15,639-second
per-test cap (resource wall time 4:20:39), exited 137, and is recorded as
TIMEOUT. The status reports 47 heartbeats; the full simulator log contains 53
through `wall_s=15600 mcycle=33461`, with no repeated adjacent mcycle, testcase
terminal marker, or result JSON. Maximum RSS was 1,852,468 KiB. Tasks 799_23–28
were RUNNING at `14700/106536`, `13200/95971`, `5400/37445`, `4800/32965`,
`1500/10136`, and `300/1974`; tasks 799_29–42 were PENDING. No result JSON or
exact testcase PASS/FAIL marker was found for active rows. See the
[14:08 snapshot](heartbeat-snapshot-20261013-1408.txt).

At 14:32 MDT, task 799_23 (`smoke_test_ecc_keygen`) reached its exact
16,033-second cap and is recorded as TIMEOUT, with final mcycle 115,112. Task
799_29 (`smoke_test_kv_ecc_flow1`) is recorded as FAIL: firmware compilation
exited 1 after 36.47 seconds because GCC rejected an implicit `srand`
declaration at line 197. VVP did not start, so no mcycle was emitted. Tasks
799_24–28 and 799_30 were RUNNING at `14700/106772`, `6900/48065`,
`6300/43563`, `3000/20483`, `1800/12489`, and `0/0`; tasks 799_31–42 were
PENDING. Active logs had no result JSON or exact testcase PASS/FAIL markers, and
rows 799_24–28 had advancing mcycle samples; task 799_30 had only its
initial `0/0` sample. See the
[14:32 snapshot](heartbeat-snapshot-20261013-1432.txt) and
[failure evidence](failure-evidence-799/README.md).

At 14:43 MDT, tasks 799_24–28 and 799_30 remained RUNNING at
`15300/110979`, `7500/52216`, `6900/47760`, `3600/24579`, `2400/16538`, and
`900/6181`; tasks 799_31–42 remained PENDING. All active rows had advancing
mcycle samples and no result JSON or exact testcase PASS/FAIL marker. See the
[14:43 snapshot](heartbeat-snapshot-20261013-1443.txt).

At 14:54 MDT, task 799_24 (`smoke_test_ecc_sign`) reached its exact
16,033-second cap and is TIMEOUT with final mcycle 115,159. Task 799_31
(`smoke_test_kv_ecc_flow2`) is FAIL: firmware compilation exited 1 after
26.31 seconds on the implicit `srand` declaration at line 197, before VVP
started; no mcycle was emitted. Tasks 799_25–28, 799_30, and 799_32 were
RUNNING at `8100/56344`, `7500/51916`, `4200/28689`, `3000/20544`,
`1500/10338`, and `0/0`; tasks 799_33–42 were PENDING. Active logs had no
result JSON or exact testcase markers. See the
[14:54 snapshot](heartbeat-snapshot-20261013-1454.txt) and
[failure evidence](failure-evidence-799/README.md).

At 15:06 MDT, tasks 799_25–28, 799_30, and 799_32 remained RUNNING at
`9000/62579`, `8100/56126`, `5100/34969`, `3600/24679`, `2100/14501`, and
`600/4109`; tasks 799_33–42 remained PENDING. All six active logs had advancing
mcycle samples with no flat interval; none had a result JSON or testcase
terminal marker. See the [15:06 snapshot](heartbeat-snapshot-20261013-1506.txt).

At 15:16 MDT, tasks 799_25–28, 799_30, and 799_32 remained RUNNING at
`9600/66869`, `8700/60408`, `5700/39327`, `4200/28921`, `2700/18736`, and
`1200/8451`; tasks 799_33–42 remained PENDING. All active logs had advancing
mcycle samples, no flat interval, and no result JSON or testcase terminal
marker. See the [15:16 snapshot](heartbeat-snapshot-20261013-1516.txt).

At 15:27 MDT, task 799_26 (`smoke_test_ecc_errortrigger2`) is recorded as
FAIL: the result JSON says `passed=false`, with a fatal
`ERR_ECC_PRIVKEY_NOT_STABLE` assertion. Its wrapper status ended at
`8700/60408`, but the full simulator log continues to final mcycle 62,553 at
wall 9,000. Tasks 799_25, 799_27–28, 799_30, and 799_32–33 were RUNNING at
`10200/71164`, `6300/43704`, `5100/35396`, `3300/23045`, `1800/12826`, and
`0/0`; tasks 799_34–42 were PENDING. Active logs had no result JSON or exact
testcase terminal marker and no flat-mcycle window. See the
[15:27 snapshot](heartbeat-snapshot-20261013-1527.txt) and
[failure evidence](failure-evidence-799/README.md).

At 15:39 MDT, tasks 799_25, 799_27–28, 799_30, and 799_32–33 remained
RUNNING at `10800/75322`, `6900/47965`, `5700/39576`, `4200/29375`,
`2700/18999`, and `900/6100`; tasks 799_34–42 remained PENDING. All active
logs had advancing mcycle samples with no flat window, result JSON, or testcase
terminal marker. See the [15:39 snapshot](heartbeat-snapshot-20261013-1539.txt).

At 15:49 MDT, tasks 799_25, 799_27–28, 799_30, and 799_32–33 remained
RUNNING at `11400/79446`, `7800/54273`, `6300/43758`, `4800/33563`,
`3300/23075`, and `1500/10161`; tasks 799_34–42 remained PENDING. All active
logs had advancing mcycle samples with no flat window, result JSON, or testcase
terminal marker. See the [15:49 snapshot](heartbeat-snapshot-20261013-1549.txt).

At 16:00 MDT, tasks 799_25, 799_27–28, 799_30, and 799_32–33 remained
RUNNING at `12300/85619`, `8400/58438`, `6900/47940`, `5400/37765`,
`3900/27194`, and `2100/14179`; tasks 799_34–42 remained PENDING. All active
logs had advancing mcycle samples, no flat interval, result JSON, or testcase
terminal marker. See the [16:00 snapshot](heartbeat-snapshot-20261013-1600.txt).

At 16:10 MDT, tasks 799_25, 799_27–28, 799_30, and 799_32–33 remained
RUNNING at `12900/89730`, `9000/62561`, `7500/52080`, `6000/41957`,
`4500/31304`, and `2700/18129`; tasks 799_34–42 remained PENDING. All active
logs had advancing mcycle samples, no flat interval, result JSON, or testcase
terminal marker. See the [16:10 snapshot](heartbeat-snapshot-20261013-1610.txt).

At 16:21 MDT, tasks 799_25, 799_27–28, 799_30, and 799_32–33 remained
RUNNING at `13500/93993`, `9600/66795`, `8100/56329`, `6600/46297`,
`5100/35597`, and `3300/22217`; tasks 799_34–42 remained PENDING. All active
logs had advancing mcycle samples, no flat interval, result JSON, or testcase
terminal marker. See the [16:21 snapshot](heartbeat-snapshot-20261013-1621.txt).

At 16:31 MDT, tasks 799_25, 799_27–28, 799_30, and 799_32–33 remained
RUNNING at `14100/98309`, `10200/71171`, `8700/60660`, `7200/50764`,
`5700/40009`, and `3900/26493`; tasks 799_34–42 remained PENDING. All active
logs had advancing mcycle samples, no flat interval, result JSON, or testcase
terminal marker. See the [16:31 snapshot](heartbeat-snapshot-20261013-1631.txt).

At 16:42 MDT, tasks 799_25, 799_27–28, 799_30, and 799_32–33 remained
RUNNING at `14700/102619`, `10800/75544`, `9600/4430`, `7800/55217`,
`6300/44427`, and `4500/30741`; tasks 799_34–42 remained PENDING. Task 28's
mcycle fell from 60,660 at wall 8,700 to 4,430 at wall 9,600; the evidence
does not identify why. It is not flat. All active logs lacked a terminal marker
or result JSON. See the [16:42 snapshot](heartbeat-snapshot-20261013-1642.txt).

At 16:52 MDT, tasks 799_25, 799_27–28, 799_30, and 799_32–33 remained
RUNNING at `15300/106937`, `11400/79930`, `10200/8745`, `8400/59669`,
`6900/48866`, and `5400/37240`; tasks 799_34–42 remained PENDING. Task 28's
mcycle rose from 4,430 to 8,745 after its earlier drop; the cause remains
unknown. All active rows remained non-flat and had no terminal markers or result
JSON. See the [16:52 snapshot](heartbeat-snapshot-20261013-1652.txt).

At 17:03 MDT, task 799_25 (`smoke_test_ecc_verify`) reached its exact
16,033-second cap and is TIMEOUT with final mcycle 111,247. The wrapper status
reports 53 heartbeats; the full log contains 54 through wall 15,900, with no
flat interval or testcase terminal marker. Tasks 799_27–28, 799_30, and
799_32–34 were RUNNING at `12000/84315`, `10800/13049`, `9300/66247`,
`7800/55508`, `6000/41577`, and `0/0`; tasks 799_35–42 were PENDING. All active
rows had no result JSON or terminal marker. See the
[17:03 snapshot](heartbeat-snapshot-20261013-1703.txt).


At 17:20 MDT, task 799_32 (`smoke_test_ecc_flow1_kv_ocp_progress`) completed PASS. Its result JSON reports `passed=true`; the full log has 29 heartbeats through `8400/59912`, one `* TESTCASE PASSED`, no fail marker, and `$finish` at mcycle 60,927. The wrapper status stops at `7800/55508`, so the ledger uses the later full-log heartbeat. Tasks 27, 28, 30, 33, 34, and 35 remained RUNNING; tasks 36–42 were PENDING. Active rows were advancing or had only a recent initial heartbeat, with no 30-minute flat interval. See [the 17:20 snapshot](heartbeat-snapshot-20261013-1720.txt).

At 18:42 MDT, the supervisor cancelled tasks 799_28 and 799_30 for maintenance, after the user had directed cancellation of 799_34 and 799_35. Slurm logs show all four jobs terminated by signal at 18:42:09. They are recorded as `CANCELLED-FOR-MAINTENANCE`, with final heartbeats `16800/56216`, `15000/107664`, `5700/40947`, and `5100/37091`; none is classified as TIMEOUT. Tasks 799_36–42 remain held by `JobHeldUser`. Re-run all eleven rows after the supervisor announces Slurm has reopened. See the [18:42 snapshot](heartbeat-snapshot-20261013-1842.txt) and [cancellation evidence](cancelled-evidence-799/README.md).
