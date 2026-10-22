# cptra_ss_test_rom DMA diagnostic

This was a diagnostic-only run, separate from the official M9 row. It used Slurm job 1606 and an external 600-second cap while keeping the case's original 6,873-second timeout unchanged.

## Inputs

- Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- QD-BFM source snapshot: `41fe54a891e8cde20b6ef8df4a2745cc4cb7cddd`, archived with a clean tracked worktree
- Verilator 5.052 pinned M9 model SHA-256: `ce2d0e5012cfbedb46c01a24acf948fae4f0948b140e482348407677bf9b79de`
- Diagnostic firmware `program.hex` SHA-256: `50318a214eb5aabf7e53cba95473da14cf929b45d59d3ac5cefbbce7a0ecb8ad`
- Diagnostic firmware `dccm.hex` SHA-256: `a0d61ac7ef132e442440153f98acbfbfc14bef459e5f3fc10abb67a60e7a430f`

The compiler wrapper's source-substitution record confirms that the test used the private instrumented copy of `soc_ifc.c`. The patch adds progress prints around the DMA arm, FIFO waits and writes, and idle wait; it does not change a condition, register access, or return path.

## Result

The firmware build completed. The simulation reached DMA FIFO writes 0 through 14. At 9,748,000 ns it printed `M9DIAG FIFO: space available word=15`; the following source statement is the write to `CLP_AXI_DMA_REG_WRITE_DATA`. No `word written=15` marker appeared before the outer 600-second timeout. The diagnostic localizes the stall to that 16th data-register write, but does not distinguish a blocked processor store from a downstream bus-response problem.

The Slurm job completed with shell exit 0 after its diagnostic wrapper recorded exit 124 from the external cap. It produced no `result.json` and is not a replacement test result. The official M9 row remains TIMEOUT; the c339 row also timed out without a terminal verdict.

The selected logs, source patch, toolchain output, resource record, run metadata, and their input manifest are preserved in [`diagnostic-evidence.tar.gz`](diagnostic-evidence.tar.gz), SHA-256 `63643b6a36eca5813d68c9a00e7866759bde9be91ec3deb65c48cd28a3883193`. Every entry in the original input manifest passed checksum verification before bundling. The run's build tree, copied source, model, and other staging files were deleted after evidence collection, freeing 28,997,682 bytes on DAN-DESKTOP.
