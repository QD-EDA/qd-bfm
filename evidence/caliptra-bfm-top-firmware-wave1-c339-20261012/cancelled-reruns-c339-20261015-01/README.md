# Fresh rerun of array-799 maintenance cancellations

This array reruns original tasks 799_28, 799_30, 799_34, and 799_35 (source rows 37, 39, 43, and 44) in a new Slurm run directory after the supervisor reopened DAN-DESKTOP. Earlier post-reopen runs remain preserved separately; these are fresh results for the latest cancellation request. Each task uses the pinned QD-BFM, Caliptra RTL, Adams Bridge, Icarus c339 toolchain, and original per-test timeout. Resource request: 1 CPU and 3 GiB per task; array throttle: 6.

`selection.tsv` maps new array tasks to source rows; `results.tsv` will hold the terminal outcome and final mcycle. Each task's evidence will be copied and checksum-verified before its remote output tree is removed.

Array 1426 was submitted on DAN-DESKTOP on 2026-10-15 at 19:59:53 local time; all four tasks entered RUNNING by 20:00:01. The first live snapshot is in `submission-queue.txt`. No local duplicates were active. The prior maintenance-cancellation heartbeats and classifications remain in the original array-799 evidence; this array is a separate fresh run.

The 20:11 MDT heartbeat snapshot records all four fresh runs progressing at wall 600s, with mcycle 4,376 / 4,342 / 4,317 / 4,351 for source rows 37 / 39 / 43 / 44. The live values are preserved in `heartbeat-snapshot-20261015-2011.txt` and `results.tsv`; final mcycle remains blank until each run terminates.

At the 20:42 MDT check, all four tasks remained RUNNING and their heartbeats advanced to wall 2,400s: source rows 37 / 39 / 43 / 44 reached mcycle 17,381 / 17,257 / 17,178 / 17,302. See `heartbeat-snapshot-20261015-2042.txt` and the live fields in `results.tsv`.

At the 20:54 MDT check, all four tasks remained RUNNING and their heartbeats advanced to wall 3,000s: source rows 37 / 39 / 43 / 44 reached mcycle 21,491 / 21,342 / 21,252 / 21,410. See `heartbeat-snapshot-20261015-2054.txt` and the live fields in `results.tsv`.

At 21:16 MDT, all four fresh reruns remain RUNNING. Their latest heartbeat is at wall 4,500 seconds: rows 37 / 39 / 43 / 44 reached mcycle 32,075 / 31,866 / 31,743 / 32,003. See `heartbeat-snapshot-20261015-2116.txt`; final mcycle remains blank until terminal completion.
At 21:27 MDT, all four jobs remain RUNNING. Their latest heartbeat is wall 5,100 seconds; source rows 37 / 39 / 43 / 44 are at mcycle 36,093 / 35,881 / 35,744 / 36,022. The M9 array is using two slots for its active rows, and the one-row parser retry is dependency-held until that array completes.
At 21:38 MDT, all four c339 reruns remain RUNNING. Latest heartbeat wall time is 5,700 seconds; source rows 37 / 39 / 43 / 44 reached mcycle 40,366 / 40,164 / 40,019 / 40,293. The M9 `infinite_loop` row is intentionally running under its 21,600-second test timeout; do not classify it before the timeout.

At 21:48 MDT, the four c339 runs remain active and progressing at wall 6,300 seconds: rows 37 / 39 / 43 / 44 reached mcycle 44,480 / 44,334 / 44,181 / 44,461. Final results have not been emitted.

At 21:59 MDT, all four fresh c339 jobs remain active and progressing at wall 6,900 seconds. The latest mcycles for source rows 37 / 39 / 43 / 44 are 48,511 / 48,406 / 48,249 / 48,535.

At 22:09 MDT, all four runs remain active at wall 7,500 seconds. Latest mcycles for source rows 37 / 39 / 43 / 44 are 52,657 / 52,585 / 52,421 / 52,716.

At 22:20 MDT, all four reruns remain RUNNING. Latest heartbeat wall times for rows 37 / 39 / 43 / 44 are 7,800 / 7,800 / 8,100 / 7,800 seconds, with mcycles 54,726 / 54,673 / 56,594 / 54,805.

At 22:29 MDT, fresh rerun task 1426_4, source row 44 (smoke_test_ecc_flow2_kv_ocp_progress), completed PASS at final mcycle 62,472. Full job wall time was 8,951 seconds (2:29:11), with 1,852,708 KiB peak RSS; Slurm reports COMPLETED, exit 0. Checksum-verified evidence is in task-1426_4/. Three fresh runs remain active. With one c339 slot free, M9 array 1430's throttle was raised from 2 to 3, keeping A2 at at most six active tests.

At 22:32 MDT, row 44 is recorded PASS (final mcycle 62,472; wall 8,951s). Rows 37 / 39 / 43 remain RUNNING with latest mcycles 58,855 / 60,829 / 58,674. M9 task 57 started after array throttle increased to 3; total A2 active jobs remain capped at six.
The completed task-1426_4 build/output tree and its Slurm log were removed after the local checksum-verified evidence was saved, freeing 377,312,092 bytes (359.78 MiB).

At 22:38 MDT, tasks 1426_1 through 1426_3 remained RUNNING at heartbeat wall time 9,300s. Latest mcycles were 2,247 / 64,978 / 62,668 for source rows 37 / 39 / 43; row 37's mcycle restarted after wall 8,700s, and its latest heartbeat confirms continued progress. The current snapshot is `heartbeat-snapshot-20261015-2238.txt`. M9 runs tasks 47, 55, and 59 at throttle 3; retry 1493 is dependency-held on completion of 1426_1.

At 22:49 MDT, the three c339 reruns remained RUNNING at heartbeat wall time 9,900s, with mcycles 6,236 / 68,923 / 63,665 for source rows 37 / 39 / 43. All three heartbeats advanced since the prior snapshot. M9 runs tasks 47, 55, and 62 at throttle 3; retry 1493 remains dependency-held on 1426_1.

At 23:03 MDT, all three c339 reruns remained RUNNING at wall time 10,800s, with mcycles 12,249 / 74,942 / 65,152 for source rows 37 / 39 / 43. M9 runs tasks 47, 55, and 63 at throttle 3; retry 1493 remains dependency-held on 1426_1.

At 23:15 MDT, the three reruns remained RUNNING at wall time 11,400s and advanced to mcycles 16,261 / 78,953 / 66,147 for rows 37 / 39 / 43. No terminal results have appeared. M9 tasks 47, 55, and 63 remain active; task 1493 is still dependency-held on 1426_1.

At 23:25 MDT, the three c339 runs remained RUNNING at wall time 12,300s, with mcycles 22,556 / 85,240 / 67,673 for rows 37 / 39 / 43. M9 tasks 47, 55, and 63 are still active; the process check found each simulator using 99.9% CPU despite quiet logs.

At 23:36 MDT, all three c339 runs advanced to wall 12,900s, with mcycles 26,971 / 89,627 / 68,729 for rows 37 / 39 / 43. No terminal outcomes appeared. M9 tasks 47, 55, and 63 remain active, and the retry remains dependency-held on 1426_1.

At 23:46 MDT, all three reruns advanced to wall 13,500s, with mcycles 31,404 / 94,020 / 69,786 for rows 37 / 39 / 43. The M9 active tasks remain 47, 55, and 63; their simulator processes remain CPU-active despite quiet logs.

At 23:57 MDT, c339 rows 37 / 39 / 43 remain active and advanced to wall 14,100s, with mcycles 35,816 / 98,391 / 70,842. M9 still has three active tasks, 47 / 55 / 63, and retry 1493 remains dependency-held.

At 00:07 MDT on 2026-10-16, all three reruns advanced to wall 14,700s, with mcycles 40,215 / 102,747 / 71,898 for source rows 37 / 39 / 43. No terminal results are ready. M9 tasks 47, 55, and 63 remain active; retry 1493 still waits on 1426_1.

At 00:17 MDT, all three reruns advanced to wall 15,300s, with mcycles 44,602 / 107,087 / 72,950 for rows 37 / 39 / 43. M9 tasks 47, 55, and 63 remain active and CPU-running; retry 1493 is still held on 1426_1.

At 00:28 MDT, array 1426 tasks 1–3 remained RUNNING and advanced to wall 15,900s, with mcycles 48,990 / 111,436 / 74,005 for source rows 37 / 39 / 43. Task 1426_4 (source row 44, original task 799_35) is already recorded as PASS at mcycle 62,472 and wall time 8,951s; its verified remote output tree was removed. The M9 array has tasks 63, 67, and 75 RUNNING, leaving all six A2 slots occupied. Retry 1493 remains dependency-held on 1426_1.
