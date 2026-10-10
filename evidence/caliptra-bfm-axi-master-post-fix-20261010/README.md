# AXI master post-fix regression — 2026-10-10

Slurm job 198 passed the existing guarded `run_master.sh` suite on QD commit
`75ceb4b2f66b7140aabd3cab6d02df05e99be69e` using clean published Icarus main
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` (Icarus 13.0 devel). The suite
reported 10 PASS markers and no FAIL markers. It covers the master burst and
response checks, W-before-AW ordering, overlapping read/write tasks, reset
abort/recovery, malformed response poisoning, queued reads, and outstanding
writes with BID routing.

The job requested 1 CPU and 256 MiB, sized from the same suite's 17,568 KiB
MaxRSS on job 107. Job 198 completed in 0.32 seconds with 17,680 KiB MaxRSS.
The existing guard capped the process group at 150,000,000 bytes and preserved
a 6 GB system reserve; it measured a 0.00 GiB process-group peak and 10.51 GiB
minimum available memory.

## Artifacts

- [`logs/runner.log`](logs/runner.log): full regression output and PASS markers.
- [`logs/caliptra-axi-master-postfix-198.out`](logs/caliptra-axi-master-postfix-198.out):
  job revisions and memory-guard summary.
- [`logs/time.log`](logs/time.log): elapsed time, maximum RSS, and exit status.
- [`logs/iverilog-version.txt`](logs/iverilog-version.txt): simulator version output.
- [`job.sbatch`](job.sbatch): exact Slurm request and runner command.
- [`logs/source-files.sha256`](logs/source-files.sha256),
  [`source-revisions.txt`](source-revisions.txt),
  [`source-archive.sha256`](source-archive.sha256), and
  [`source-archive.tar.gz`](source-archive.tar.gz): source/tool provenance.

This is standalone master regression evidence. It does not establish full-top,
four-state, or Caliptra/UVMF qualification.
