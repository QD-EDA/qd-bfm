# M11b focused traces

This diagnostic run captures one trace for each of M11 drafts 6–9 using pinned Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052, the official M10b `axi_if.sv` overlay, and assertions (`--assert`, `CLP_ASSERT_ON`). It does not modify pinned RTL or post upstream.

The gate is `smoke_test_ecc_keygen` (row 0). Only after the gate result is recorded will rows 1–3 be submitted as a three-task array. Each row has a 600-second simulator timeout and a 600-second outer process guard (plus 10 seconds for TERM-to-KILL cleanup); one CPU and 3 GiB are requested per simulation. The model build requests 4 CPUs and 4 GiB, matching the prior 2.38 GiB peak build measurement.

Diagnostic-only overlay traces:

- ECC: sampled `privkey_reg`/`seed_reg` changes with each corresponding `hwclr` cause.
- DMA/AES: sampled FSM transitions and the exact `AXI_DMA_AES_FSM_ERR_SYNC` failing edge.
- MLKEM: sampled failing byte/index and the last key-vault write cycle/value for that dword.
- LMS: sampled DCCM range/depth before `$readmemh`; the runner preserves the generated `dccm.hex` for size and address analysis.

The LMS firmware image is diagnostic evidence and is retained.

## Build 2079

The corrected staged build completed on `DAN-DESKTOP` on 2026-10-17 at 02:20 MDT. It used QD source commit `1f132e764b6385aeeecd6149703db5ed3eb5c148`, pinned Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052 (`v5.052`, 2026-09-05), GCC 15.2.0, `--assert`, and `CLP_ASSERT_ON`. Slurm allocated 4 CPUs and 4 GiB; compilation exited 0 in 4:05.56 with 2,382,004 KiB peak RSS. The built model SHA-256 is `d098dd7e1fbee0c6b2d3dcb5fba1b3b5a7f87b3554d0453b0d184eda5cdf0644`. Build log, resource report, overlay manifest, completion marker, scheduler output, and hashes are under [`raw/job-2079`](raw/job-2079/).

The ECC gate row is job 2082, submitted with 1 CPU, 3 GiB, and a 600-second simulator plus outer process cap. It reached firmware and failed `ERR_ECC_SEED_NOT_STABLE` at 78,353,000 ps, after the log's `ECC zeroize flow` line at 78,325,000 ps. The result and all raw inputs/logs pass `FILE-SHA256SUMS` in [`raw/gate-2082`](raw/gate-2082/). Its separate diagnostic property did not print a clear-event record, so this run records the assertion and timing but does not identify the clear signal. The follow-up run uses the same `$stable(seed_reg)` assertion predicate with the trace in that predicate's failure action, preserving unknown-value behavior and ensuring the trace runs with the assertion report.

After local checksums were verified, remote run directories 01, 02, 03, and the canceled-before-start staging run 04 were removed; this freed 734,797,557 bytes of run-tree data. The failed setup, completed build, gate result, scripts, and manifests remain in the local evidence tree. Active run 05 remains in place for job 2086.
