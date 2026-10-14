# Corrected reruns after host restart

This fresh array reruns the four original array-799 maintenance cancellations: 799_28, 799_30, 799_34, and 799_35. They map to source rows 37, 39, 43, and 44, respectively. Prior job 936 was interrupted by a host restart; job 949 failed before any test started because `selection.tsv` was staged in the wrong directory. Both are infrastructure attempts, not test outcomes, and their evidence is preserved in the neighboring run folders.

This submission stages `selection.tsv` both at `$ROOT/selection.tsv` (the exact path used by the array script) and under `submit/`. The tasks use the original per-test timeouts, 1 CPU and 3 GiB each, 6h10m allocation, and array throttle 6. The pinned source/toolchain inputs were re-verified before submission. No local duplicates are running.

[`selection.tsv`](selection.tsv) maps the array tasks; [`results.tsv`](results.tsv) records terminal outcomes only after complete run evidence is collected.


## Initial submission state

Slurm accepted array 955 at 07:39:17 MDT. At 07:39:21, all four tasks were RUNNING on DAN-DESKTOP, each with one CPU, 3 GiB, and a 6h10m limit; `ArrayTaskThrottle=6`. The 07:39:32 queue/resource snapshot is in [`initial-queue-20261014-0739.txt`](initial-queue-20261014-0739.txt). The four task logs show the expected source-row mappings and pinned QD commit.


At the 07:52 MDT check, all four array-955 tasks remained RUNNING. Each simulator emitted three heartbeats through `wall_s=600`; final observed mcycles were 4,500, 4,500, 4,512, and 4,512 for tasks 1–4. VVP processes were using about 99.9% CPU and 1.04 GiB RSS each. No result JSON, status file, or testcase terminal marker exists yet. The 30-minute flat-heartbeat rule is not met; the exact snapshot is [`heartbeat-snapshot-20261014-0752.txt`](heartbeat-snapshot-20261014-0752.txt).


At 08:03 MDT all four array-955 tasks remained RUNNING. Each had five heartbeats through `wall_s=1200`; latest mcycles were 9,185, 9,185, 9,231, and 9,238 for tasks 1–4. VVP was still consuming about 99.9% CPU per task. No result JSON, status file, or terminal marker was present. The latest heartbeat had been written about 3.5 minutes earlier, so no task meets the 30-minute flat-heartbeat rule. See [`heartbeat-snapshot-20261014-0803.txt`](heartbeat-snapshot-20261014-0803.txt).


At 08:14 MDT, all four tasks were still RUNNING with no result/status file or testcase marker. Their last heartbeat remains `wall_s=1800`, with mcycles 13,882; 13,880; 13,939; and 13,953. The last simulator log write was 07:59:50 MDT, about 14 minutes before this check; each VVP was still using 99.9% CPU at about 1.04 GiB RSS. This is below the 30-minute flat-heartbeat threshold, so no row is classified as a hang. Snapshot: [`heartbeat-snapshot-20261014-0814.txt`](heartbeat-snapshot-20261014-0814.txt).


At 08:25 MDT all four tasks remained RUNNING and advanced to `wall_s=2700`. Latest mcycles for tasks 1–4 are 20,838; 20,837; 20,913; and 20,939. Each simulator log has ten heartbeats, the result/status files remain absent, and no testcase terminal marker is present. VVP processes were still near 100% CPU. The exact queue and log snapshot is [`heartbeat-snapshot-20261014-0825.txt`](heartbeat-snapshot-20261014-0825.txt).


At 08:36 MDT all four tasks remained RUNNING and advanced to `wall_s=3300`. Latest mcycles for tasks 1–4 are 25,630; 25,628; 25,708; and 25,738. Each simulator log has twelve heartbeats; no status/result JSON or terminal testcase marker exists. VVP processes remain near 100% CPU. Snapshot: [`heartbeat-snapshot-20261014-0836.txt`](heartbeat-snapshot-20261014-0836.txt).


At 08:46 MDT all four tasks remained RUNNING and advanced to `wall_s=3900`. Latest mcycles are 30,335; 30,319; 30,412; and 30,446. Each log has fourteen heartbeats; no result JSON, status file, or terminal testcase marker exists. VVP processes remain near 100% CPU. See [`heartbeat-snapshot-20261014-0846.txt`](heartbeat-snapshot-20261014-0846.txt).


At 08:57 MDT all four array-955 tasks remained RUNNING, with sixteen heartbeats through `wall_s=4500`. Latest mcycles are 35,184; 35,164; 35,259; and 35,299. No result JSON, status file, or testcase terminal marker is present. VVP remains near 100% CPU. The captured queue/log state is [`heartbeat-snapshot-20261014-0857.txt`](heartbeat-snapshot-20261014-0857.txt).


At 09:08 MDT the four tasks remained RUNNING with eighteen heartbeats through `wall_s=5100`. Latest mcycles are 39,977; 39,950; 40,054; and 40,094. Result/status files and terminal markers remain absent. VVP processes remain active near 100% CPU. Snapshot: [`heartbeat-snapshot-20261014-0908.txt`](heartbeat-snapshot-20261014-0908.txt).


At 09:19 MDT all four tasks remained RUNNING with twenty heartbeats through `wall_s=5700`. Latest mcycles are 44,777; 44,743; 44,851; and 44,897. No result JSON, status file, or terminal testcase marker exists. VVP processes remain active near 100% CPU. See [`heartbeat-snapshot-20261014-0919.txt`](heartbeat-snapshot-20261014-0919.txt).


At 09:29 MDT all four tasks remained RUNNING with twenty-two heartbeats through `wall_s=6300`. Latest mcycles are 49,641; 49,602; 49,715; and 49,764. No result JSON, status file, or terminal marker exists. VVP is still active near 100% CPU. Snapshot: [`heartbeat-snapshot-20261014-0929.txt`](heartbeat-snapshot-20261014-0929.txt).


At 09:40 MDT all four tasks remained RUNNING. Tasks 1–3 have 24 heartbeats through `wall_s=6900` (mcycles 54,491; 54,453; 54,567); task 4 has 25 through `wall_s=7200` (mcycle 57,034). No result JSON, status file, or terminal marker exists. VVP processes remain active near 100% CPU. See [`heartbeat-snapshot-20261014-0940.txt`](heartbeat-snapshot-20261014-0940.txt).


## Task 4 (955_4) — PASS

The fresh rerun of original task 799_35 / source row 44 passed. It has 26 heartbeats and final heartbeat `wall_s=7500 mcycle=59434`; the runner exited 0 after 2:11:49 with 1,852,844 KiB maximum RSS. `result.json` and `sim.log` both confirm one pass marker and zero failures. The selected raw evidence is SHA-verified in [`pass-evidence-955/`](pass-evidence-955/). At the 09:53 MDT checkpoint, tasks 955_1–3 remained RUNNING; their latest heartbeats are recorded in `results.tsv` and [`heartbeat-snapshot-20261014-0953.txt`](heartbeat-snapshot-20261014-0953.txt).


After commit `722c0ea`, I removed task 955_4's completed remote output and Python cache trees. Their recorded size was 377,301,648 bytes (about 0.351 GiB). Tasks 955_1–3 remained active, and the protected shared toolchain was untouched. See [`pass-evidence-955/cleanup-task955_4-20261014.txt`](pass-evidence-955/cleanup-task955_4-20261014.txt).


At 10:05 MDT tasks 955_1–3 remained RUNNING. Task 1's heartbeat mcycle reset from 59,285 at wall 7,500 to 1,333 at wall 8,100, then advanced to 6,195 at wall 8,700; this is recorded as observed without assigning a cause. Task 2 reached wall 8,400 / mcycle 66,338, and task 3 wall 8,700 / mcycle 63,534. Task 4 remains recorded PASS. See [`heartbeat-snapshot-20261014-1005.txt`](heartbeat-snapshot-20261014-1005.txt).


At 10:16 MDT tasks 955_1–3 remained RUNNING. All three advanced to `wall_s=9300`; mcycles are 11,003, 73,443, and 64,612, with 30, 30, and 28 heartbeats respectively. Their result/status files remain absent and no terminal markers were found. Task 4 remains recorded PASS. See [`heartbeat-snapshot-20261014-1016.txt`](heartbeat-snapshot-20261014-1016.txt).


At 10:30 MDT tasks 955_1–3 remain RUNNING and each advanced to `wall_s=10200`; mcycles are 18,179, 80,516, and 66,228. Each log has 35 heartbeats, no terminal markers, and no result JSON. All three VVP processes are active near 100% CPU. Task 4 remains PASS. See [`heartbeat-snapshot-20261014-1030.txt`](heartbeat-snapshot-20261014-1030.txt).


At 10:41 MDT tasks 955_1–3 remain RUNNING and each advanced to `wall_s=10800`; mcycles are 22,846, 85,119, and 67,291. Each log has 37 heartbeats, no terminal markers, and no result JSON. All three VVP processes remain active near 100% CPU. Task 4 remains PASS. See [`heartbeat-snapshot-20261014-1040.txt`](heartbeat-snapshot-20261014-1040.txt).


At 10:51 MDT tasks 955_1–3 remain RUNNING and each advanced to `wall_s=11400`; mcycles are 27,564, 89,767, and 68,364. Each log has 39 heartbeats, no terminal markers, and no result JSON. All three VVP processes remain active near 100% CPU. Task 4 remains PASS. See [`heartbeat-snapshot-20261014-1051.txt`](heartbeat-snapshot-20261014-1051.txt).


At 11:02 MDT tasks 955_1–3 remain RUNNING and each advanced to `wall_s=12000`; mcycles are 32,304, 94,428, and 69,438. Each log has 41 heartbeats, no terminal markers, and no result JSON. All three VVP processes remain active near 100% CPU. Task 4 remains PASS. See [`heartbeat-snapshot-20261014-1101.txt`](heartbeat-snapshot-20261014-1101.txt).


At 11:13 MDT tasks 955_1–3 remain RUNNING and each advanced to `wall_s=12600`; mcycles are 37,023, 99,066, and 70,511. Each log has 43 heartbeats, no terminal markers, and no result JSON. All three VVP processes remain active near 100% CPU. Task 4 remains PASS. See [`heartbeat-snapshot-20261014-1112.txt`](heartbeat-snapshot-20261014-1112.txt).


At 11:23 MDT tasks 955_1–3 remain RUNNING and each advanced to `wall_s=13200`; mcycles are 41,829, 103,783, and 71,589. Each log has 45 heartbeats, no terminal markers, and no result JSON. All three VVP processes remain active near 100% CPU. Task 4 remains PASS. See [`heartbeat-snapshot-20261014-1123.txt`](heartbeat-snapshot-20261014-1123.txt).


At 11:34 MDT tasks 955_1–3 remain RUNNING and each advanced to `wall_s=13800`; mcycles are 46,499, 108,373, and 72,657. Each log has 47 heartbeats, no terminal markers, and no result JSON. All three VVP processes remain active near 100% CPU. Task 4 remains PASS. See [`heartbeat-snapshot-20261014-1133.txt`](heartbeat-snapshot-20261014-1133.txt).
