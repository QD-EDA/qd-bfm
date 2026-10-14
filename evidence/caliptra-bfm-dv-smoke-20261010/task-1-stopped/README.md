# First AES/DMA diagnostic stopped — Slurm array 280 task 1

The AES/DMA case compiled and started simulation, then was cancelled after
task 0 timed out in the same top-level runner. Its 14-byte simulator log
contains only `w = 1 n = 1`; it has no pass/fail marker or terminal result.
Task 2 (`rand_test_dma`) was still pending and was cancelled before it started.
Neither case is classified from these incomplete runs.

The retained compile log, partial simulator log, Slurm output, and pinned
source revisions document the stopped attempt. The follow-up diagnostic uses
`smoke_test_dma --trace-axi` to inspect shared boot progress before repeating
the other firmware cases.
