# Fresh array 895 tasks 1–2 TIMEOUT evidence

Fresh tasks 895_1 and 895_2 reran source rows 37 and 39 (original tasks 799_28 and 799_30), which remain `CANCELLED-FOR-MAINTENANCE` in the historical array-799 ledger.

Both runs reached the per-test `timeout` command's configured limit exactly. Task 895_1 used a 17,281-second limit and resource wall time was 4:48:01 (17,281 seconds); task 895_2 used a 17,543-second limit and wall time was 4:52:23 (17,543 seconds). Both resource records show exit status 137. Their run-level `status.txt` files say `INFRA_ERROR` / `runner_terminated_by_signal`, which records how the timeout was surfaced by the wrapper. The timeout command, exact elapsed time, and per-test limit identify the test outcome as TIMEOUT.

The full simulator logs have no `result.json`, no testcase pass/fail marker, and no repeated adjacent heartbeat mcycle. Task 895_1 has 58 heartbeats through `wall_s=17100 mcycle=62443`; its status file is stale at 55 heartbeats through `wall_s=16800 mcycle=60184`. Task 895_2 has 59 heartbeats through `wall_s=17400 mcycle=126506`; its status file's heartbeat count is stale, but its last mcycle matches the full log.

Peak RSS was 1,852,804 KiB for task 895_1 and 1,852,784 KiB for task 895_2. The selected simulator and firmware logs, wrapper logs, resource and status records, provenance, and tool versions are under `runs/` and `logs/`. The transferred archive SHA-256 was `8039e956776021b36bee9f72c81a2d2a0a054186c1ef464853d724f441d54fad`; all selected files match [`REMOTE-SHA256SUMS-tasks1-2.txt`](REMOTE-SHA256SUMS-tasks1-2.txt).
