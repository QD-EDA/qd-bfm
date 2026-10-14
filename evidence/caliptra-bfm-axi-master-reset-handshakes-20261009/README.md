# AXI manager reset after channel handshakes — 2026-10-09

The standalone AXI manager regression now asserts `ARESETn` 1 ns after a
sampled AR, R, AW, W, or B handshake. Each operation must abort unsuccessfully,
clear its driven controls and busy state, and allow a post-reset locked
read/write pair to complete. The regression also reruns the existing manager
functional, reset-stall, error-response, and outstanding-transaction cases.

Slurm job 154 passed the final source snapshot's complete manager regression
sequence declared in `run_master.sh`, using published, clean Icarus `main` commit
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` (Icarus 13.0 development build).
The Slurm host's Icarus source checkout was clean at that commit. Because the
checked-in memory wrapper is macOS-only, the job script runs the same compile
and VVP cases directly in its Slurm allocation and exports the pinned
toolchain's `deps/lib` runtime path. Job 152 also passed before a 64-cycle
timeout was added to the handshake watcher; its source hashes and output are
retained separately.

The job requested 1 CPU and 256 MiB. `/usr/bin/time` measured a maximum
per-process RSS of 15,616 KiB across the compile and simulation processes; the
highest VVP process was 13,412 KiB. The scheduler's post-completion `sstat`
record was unavailable, so these are per-process measurements, not a Slurm
job-cgroup peak.

Artifacts:

- `job154.sbatch` / `job154.out` — final Slurm commands, output, and RSS.
- `source-sha256-job154.txt` — hashes of the final QD source snapshot.
- `source-state-job154.txt` — QD base commit and snapshot scope.
- `job152.*`, `source-*-job152.txt`, `iverilog-version-job152.txt`, and
  `result-job152.txt` — earlier successful run before the watcher timeout
  bound was added.
- `simulator-sha256.txt` / `iverilog-version-job154.txt` — pinned binary identity.
- `result-job154.txt` — final job result.

This covers the standalone AXI manager. Reset timing in other BFM blocks and
full Caliptra/UVMF qualification remain open.
