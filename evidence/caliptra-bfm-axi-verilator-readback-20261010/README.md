# AXI memory subordinate portability check — 2026-10-10

## Change

The target regression exposed a Verilator 5.032 code-generation problem when
`read_word()` returned a nested `word_at()` call: generated C++ copied a stale
helper result, so AXI `RDATA` stayed zero despite the memory holding the
expected words. The read helper now assembles each byte directly. A second
trace showed two nonblocking assignments to the same exclusive-success queue
slot in one clock; the generated code applied the earlier clear last. The
subordinate now assigns that slot once through mutually exclusive branches.
No simulator source was changed.

## Result

Slurm job 181 passed the full AXI memory-subordinate regression under Verilator
5.032. The same main regression, reset-handshake cases, and bounded multi-ID
memory-queue test passed under clean published Icarus 13.0 built from
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. The Icarus executable and runtime
hashes are in the Slurm output.

The run requested 1 CPU and 1 GiB. It took 13.09 seconds, measured 339,288 KiB
maximum RSS and a 0.39 GiB process-group peak, and exited 0. Its source hashes
and exact scripts are preserved alongside the logs.

This is standalone module-level regression evidence. It does not establish
full-top firmware or UVMF qualification.

## Artifacts

- [`run.log`](logs/run.log): compile output and all four test pass markers.
- [`slurm-181.out`](logs/slurm-181.out): simulator binary hashes and memory-guard result.
- [`time.log`](logs/time.log): runtime and MaxRSS.
- [`job.sbatch`](job.sbatch) and [`run-regressions.sh`](run-regressions.sh): exact submitted job and test commands.
- [`source-revisions.txt`](source-revisions.txt) and [`source-files.sha256`](source-files.sha256): source provenance and input hashes.
