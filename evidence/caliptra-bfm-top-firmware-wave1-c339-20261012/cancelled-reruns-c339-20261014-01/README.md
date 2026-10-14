# Fresh reruns after the maintenance cancellations

Job 936 was submitted at 00:12 MDT on 2026-10-14 to DAN-DESKTOP (Slurm 25.11.2) as array `1-4%6`, after four slots were available. Tasks 936_1–4 map to the original array-799 maintenance cancellations: source rows 37, 39, 43, and 44 (original tasks 28, 30, 34, and 35). At the first queue check, all four reruns were RUNNING. No local duplicates were started.

The run requests 1 CPU and 3 GiB per task with a 6h10m allocation and uses the original per-test timeouts. Pinned inputs were verified before submission: QD-BFM `d1d358e92ea47eacbcdefd58266f7563682400f3`, Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus source `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; the Icarus `iverilog` binary SHA-256 is recorded in `submission.txt`. The submitted array script is a copy of the previous wrapper with only the job name and run-root paths changed.

`selection.tsv` maps the fresh array task IDs to source rows. `results.tsv` is the live outcome ledger; final status and mcycle will be copied from the complete logs and wrapper evidence once each task ends. The original maintenance-cancellation evidence remains unchanged in the historical array-799 ledger.


At 00:29 MDT, all four job 936 tasks remained RUNNING. Each had four heartbeats, most recently at wall 900 seconds, with mcycles 6,591; 6,578; 6,587; and 6,589. No rerun had reached a terminal result. The full six-row queue and current heartbeats are in [`../m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0029.txt`](../m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0029.txt).


At 00:39 MDT, tasks 936_1–4 remained RUNNING and advanced from wall 900 to wall 1,500 seconds. Their mcycles are 11,206; 11,182; 11,197; and 11,202. The latest queue and heartbeat snapshot is [`../m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0039.txt`](../m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0039.txt).


At 00:49 MDT, all four job 936 tasks remain RUNNING and have advanced to wall 2,100 seconds. Their latest mcycles are 15,751; 15,713; 15,739; and 15,742; the 00:49 snapshot is [`../m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0049.txt`](../m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0049.txt).
