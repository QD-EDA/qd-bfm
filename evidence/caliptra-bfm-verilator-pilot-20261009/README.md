# Verilator compilation pilots — 2026-10-09

These Slurm pilots attempted the Caliptra AXI complex regression and then the
smaller standalone checker suite with Verilator 5.032. All were stopped by the
process-group guard during compilation; none produced or ran a simulation
executable. They establish no Verilator behavior or compile pass. The observed
group maxima are threshold-crossing measurements at termination, so treat them
as censored lower bounds, not eventual peak requirements. `/usr/bin/time` only
reported the shell wrapper's resident memory and is not the group measurement.

| Job | Workload | Slurm memory | CPUs | Group cap | Observed group max | Result |
|---:|---|---:|---:|---:|---:|---|
| 95 | Full complex BFM | 2 GiB | 1 | 1.5 GB | 1.42 GiB | Guard exit 124 during compile |
| 96 | Full complex BFM | 3 GiB | 1 | 2.5 GB | 2.40 GiB | Guard exit 124 during compile |
| 97 | Full complex BFM | 5 GiB | 1 | 4.0 GB | 3.80 GiB | Guard exit 124 during compile |
| 98 | Full complex BFM, tuned | 5 GiB | 1 | 4.5 GB | 4.24 GiB | Guard exit 124 during compile |
| 99 | Full complex BFM, tuned | 5500 MiB | 1 | 5.2 GB | 4.91 GiB | Guard exit 124 during compile |
| 100 | Standalone checker | 1 GiB | 1 | 0.8 GB | 0.85 GiB | Guard exit 124 during compile |
| 101 | Standalone checker | 2 GiB | 1 | 1.5 GB | 1.43 GiB | Guard exit 124 during compile |
| 102 | Standalone checker | 3 GiB | 1 | 2.4 GB | 2.25 GiB | Guard exit 124 during compile |
| 103 | Standalone checker | 4 GiB | 1 | 3.0 GB | 2.81 GiB | Guard exit 124 during compile |
| 104 | Standalone checker | 5 GiB | 1 | 4.0 GB | 3.75 GiB | Guard exit 124 during compile |

The full workload used QD-BFM snapshots based on `c8ce915`/`e88c880`; the
checker workload used `e88c880`. Both used pinned Caliptra RTL
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.032
(`672a1ccf3468902f66387049f001b04f254bbcece7d5e816e3861715889bf252`), and
g++ 15 (`e6718f7e0c7d057c3ff77b550c603da9bc4030e3ede3c053705acce1293dbe4d`).
Each job requested one CPU. The per-job guard/resource outputs, Slurm stdout,
input file manifests, and the last two job scripts are retained under `jobs/`.
The exact unmerged runner candidates are retained above for diagnosis; they are
not supported or passing regression entry points.

Do not raise the cap based on these partial peaks alone. Any renewed attempt
needs a deliberately sized, isolated Slurm request and must distinguish the
compiler's eventual peak from the guard's termination threshold.
