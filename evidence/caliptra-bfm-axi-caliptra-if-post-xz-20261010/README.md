# Caliptra `axi_if` complex-BFM smoke after AXI manager X/Z fix — 2026-10-10

The guarded `run_caliptra_axi_complex_bfm.sh` runner passed against the actual
Caliptra `axi_if` package and top-testbench types after the AXI manager's
unknown-control fail-stop change. The test reported passing channel/FIFO delay
weights and passed the Caliptra complex-BFM checks for error ranges, SRAM/FIFO
traffic, FIFO controls, recovery availability, randomized stalls, 208-dword
segmented readback, and maximum 256-beat AXI bursts.

## Pinned inputs

- QD-BFM: `b965acf0437236971a482a46e3d0499ce7988e16`
- Icarus: clean published main `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`
- Caliptra RTL: clean `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Icarus reports version 13.0 devel.

All source/tool hashes are in [`logs/source-files.sha256`](logs/source-files.sha256);
the exact QD inputs are in [`qd-bfm-source.tar.gz`](qd-bfm-source.tar.gz).
The staged archive contains only the QD AXI BFM tree and memory-guard scripts.

## Run

Slurm job 203 ran `run_caliptra_axi_complex_bfm.sh` without modifying the
pinned Icarus or Caliptra source trees. Both testbenches passed and the runner
exited 0. The job requested 1 CPU and 256 MiB, based on the same runner's prior
17,536 KiB MaxRSS (about 15x headroom). This run measured 17,684 KiB MaxRSS;
the process-group guard observed a 0.02 GiB peak and 14.42 GiB minimum
available memory against a 150,000,000-byte group cap and 6,000,000,000-byte
system reserve. Wall time was 0.54 seconds. Slurm accounting storage is
disabled on the host, so scheduler MaxRSS was unavailable; `/usr/bin/time -v`
recorded the peak RSS.

See [`job.sbatch`](job.sbatch), [`logs/runner.log`](logs/runner.log),
[`logs/resource.log`](logs/resource.log),
[`logs/source-commits.txt`](logs/source-commits.txt),
and [`logs/iverilog-version.txt`](logs/iverilog-version.txt) for the submitted
command and run output.

This is component integration evidence through Caliptra's real AXI interface
types. It does not cover full-top firmware, stock-firmware regression, UVMF,
or qualification.
