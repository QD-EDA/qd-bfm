# M11b ECC trace retry

This fresh run follows gate 2082, which reached `ERR_ECC_SEED_NOT_STABLE` at 78,353,000 ps but emitted no `M11_ECC_CLEAR_TRACE` record. The original diagnostic used a separate inverted-stability assertion; the retry places the trace in the failure action of an equivalent `$stable(seed_reg)` assertion with the same disable condition. The original `CALIPTRA_ASSERT_ERROR` remains in that action, and non-Verilator builds keep the pinned assertion macro.

Only the diagnostic overlay generator changed. Pinned Caliptra RTL remains `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Verilator 5.052, `--assert`, `CLP_ASSERT_ON`, the official M10b AXI overlay, the row selection, and 600-second simulator/outer caps remain the same. The gate is still `smoke_test_ecc_keygen`; rows 1–3 stay gated until this retry has a terminal result and usable trace.

Build and gate results, scheduler records, and checksums will be added here.

The separate rebuild job 2084 was canceled while still pending, before it allocated resources. To stay within the six-task allowance, its rebuild and ECC gate were combined into one fresh allocation in run 04. Job 2084 is not a test result; the submission and cancellation record are preserved beside this note.
