# Array 1772 cancelled for overlay diagnosis

The six running elements of array 1772 were cancelled at 2026-10-16 14:05:25 on DAN-DESKTOP after the supervisor reported that their simulator logs had been unchanged at the first fuse write for 6,805 seconds while the Verilator processes consumed a full CPU. The cancelled outputs are diagnostic evidence only; they have no `result.json`, `task-complete.txt`, or test outcome. Tasks 1772_0–5 map to Slurm job steps 1773–1778. The remaining array elements were not run.

All six copied `sim.log` files end at `SoC: Writing obfuscated UDS to fuse bank`. Their hashes, byte counts, case names, and source IDs are in [`cancelled-array-1772.tsv`](cancelled-array-1772.tsv). The corresponding Slurm cancellation messages and empty resource files are retained under [`raw/`](raw/). The bundle SHA-256 is recorded in [`LOCAL-SHA256SUMS`](LOCAL-SHA256SUMS).

This attempt is excluded from the official pinned-versus-overlay result table. The gate was met: traced job 1812 reached firmware PASS with the first-fuse AW/W/B handshake recorded, and v2 job 1834 reached firmware PASS under a 600-second cap. The corrected 103-row array was submitted as job 1835 after those results were archived.
