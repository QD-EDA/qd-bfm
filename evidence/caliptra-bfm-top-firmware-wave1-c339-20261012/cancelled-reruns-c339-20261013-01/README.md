# Fresh reruns for four maintenance-cancelled wave-1 rows

This array reruns original selection rows 37, 39, 43, and 44 (array 799 tasks 28, 30, 34, and 35) after their recorded `CANCELLED-FOR-MAINTENANCE` outcomes. The historical cancellations remain in the original wave-1 ledger; this directory records independent fresh executions.

Pinned inputs are unchanged: QD-BFM commit `d1d358e92ea47eacbcdefd58266f7563682400f3`, Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus source `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. Each row keeps its existing per-test timeout; each Slurm task requests 1 CPU and 3 GiB, with array throttle 6.

`selection.tsv` maps fresh array indices 1–4 to those four source rows. `array.sbatch` stages the existing runner unchanged under a new Slurm run root. After completion, record terminal outcome, last heartbeat mcycle, elapsed time, peak RSS, hashes, and log references here and in the main results ledger; preserve the original cancellation evidence.

At 19:41 MDT, fresh tasks 895_1–3 were still RUNNING with advancing mcycle heartbeats at `wall_s=2100` (mcycles 14,820; 14,819; and 14,810). Task 895_4 remained PENDING for resources and had not started simulation. No rerun result was terminal yet; the full queue and all wave-1 heartbeats are recorded in the main wave-1 README snapshot.

At 19:51 MDT, fresh tasks 895_1–3 were still RUNNING, with advancing mcycles at `wall_s=2700` (18,997; 18,996; 18,987). Task 895_4 remained PENDING for resources and had no simulation log yet. No fresh-rerun result was terminal.

At 20:02 MDT, fresh tasks 895_1–3 were still RUNNING, with advancing mcycles at `wall_s=3300` (23,246; 23,245; 23,236). Task 895_4 remained PENDING for resources with no simulation log. No fresh rerun result was terminal.

At 20:13 MDT, fresh tasks 895_1–3 remained RUNNING with advancing heartbeats at `wall_s=4200` (29,646; 29,645; 29,636). Task 895_4 remained PENDING for resources with no simulation log. No fresh rerun result was terminal; see the [20:13 full-array snapshot](../m5b-rerun-20261012-01/heartbeat-snapshot-20261013-2013.txt).

At 20:26 MDT, fresh tasks 895_1–3 remained RUNNING at `wall_s=4800` (33,961; 33,960; 33,951). Task 895_4 remained PENDING for resources with no simulation log. No fresh rerun result was terminal; see the [20:26 full-array snapshot](../m5b-rerun-20261012-01/heartbeat-snapshot-20261013-2026.txt).
