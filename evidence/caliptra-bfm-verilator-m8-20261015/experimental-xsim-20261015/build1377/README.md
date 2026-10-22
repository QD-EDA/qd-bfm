# Experimental x-sim top-model build (Slurm job 1377)

The pinned Verilator development build (`27d3c20`, `Verilator 5.045 devel`)
failed while elaborating the QD-BFM `caliptra_top_tb` model with `--x-sim`.
The first fatal diagnostic is `%Error-UNSUPPORTED` at
`caliptra_prim_fifo_sync.sv:135:37`: `Unsupported: 4-state numbers in this
context`. The source expression is `storage_rdata = storage[fifo_rptr]`; the
following internal error reports an X-valued 385-bit word at that packed FIFO
array select. The build exited 2 after 65.41 seconds, with peak RSS
2,406,656 KiB. Earlier warnings were non-fatal.

This is a model-build failure, not a firmware-test failure. No four-state
firmware case ran. Pilot array 1378 remained pending with
`DependencyNeverSatisfied` and was canceled; it has no per-test outcomes.
The exact run11 batch script, build logs, resource record, source/filelist
provenance, tool version, and Slurm output are archived here. All copied files
pass `remote.SHA256SUMS` verification.
