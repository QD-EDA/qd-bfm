# M11b focused traces

This diagnostic run captures one trace for each of M11 drafts 6–9 using pinned Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052, the official M10b `axi_if.sv` overlay, and assertions (`--assert`, `CLP_ASSERT_ON`). It does not modify pinned RTL or post upstream.

The gate is `smoke_test_ecc_keygen` (row 0). Only after the gate result is recorded will rows 1–3 be submitted as a three-task array. Each row has a 600-second simulator timeout and a 630-second outer process guard for result finalization; one CPU and 3 GiB are requested per simulation. The model build requests 4 CPUs and 4 GiB, matching the prior 2.38 GiB peak build measurement.

Diagnostic-only overlay traces:

- ECC: sampled `privkey_reg`/`seed_reg` changes with each corresponding `hwclr` cause.
- DMA/AES: sampled FSM transitions and the exact `AXI_DMA_AES_FSM_ERR_SYNC` failing edge.
- MLKEM: sampled failing byte/index and the last key-vault write cycle/value for that dword.
- LMS: sampled DCCM range/depth before `$readmemh`; the runner preserves the generated `dccm.hex` for size and address analysis.

Build, gate, selection, result, and checksum evidence will be added here after each stage. The LMS firmware image is diagnostic evidence and is retained.
