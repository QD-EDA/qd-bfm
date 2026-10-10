# AXI memory subordinate reset after channel handshakes — 2026-10-09

The memory subordinate regression now resets 1 ns after a sampled AR, R, AW,
W, or B handshake. The test resets the manager, target, checker, and monitor
together; it checks that the manager aborts, driven controls clear, target
responses do not remain pending or reappear after reset release, and a later
write/read pair succeeds. The handshake watcher is bounded to 64 cycles.

Slurm job 156 passed the complete subordinate and memory-queue regression
sequence. It includes the existing 256-beat subordinate test and the new
`+CASE=RESET_HANDSHAKES` case. It used published, clean Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` (Icarus 13.0 development build);
the source checkout was verified clean at that commit.

The job requested 1 CPU and 256 MiB. `/usr/bin/time` measured maximum
per-process RSS of 17,664 KiB across the compiler and simulations; the highest
VVP process was 14,064 KiB. Slurm's post-completion `sstat` record was
unavailable, so these are per-process measurements, not a job-cgroup peak.

The checked-in wrapper is macOS-only, so the Slurm job ran the same source
compiles and VVP cases directly and supplied the pinned toolchain's runtime
library path. Artifacts:

- `job156.sbatch` and `job156.out` — resource request and complete run output.
- `source-sha256.txt` and `source-state.txt` — exact QD input snapshot.
- `simulator-sha256.txt` and `iverilog-version.txt` — simulator identity.
- `result.txt` — final job result.

This is module-level AXI reset evidence, not generated DMA, full-top, or UVMF
reset qualification.
