# Wildcard coverage array with exact overlay validation

Job array 3331 is terminal. Rows 0, 1, 2, 3, 43, 44, and 45 are all BLOCKED before simulation: Icarus reports that the 32,768-value legal_word_aligned_val filter exceeds its 4,096-value limit, then exits 137. Each task reached the same compile failure in 72.686–74.719 seconds, with peak RSS from 16,737,040 to 16,737,536 KiB. Slurm logs record an OOM kill for every task.

The first remaining aligned filter is in SHA-512 CSR coverage, which the submitted overlay did not transform. The raw archives and SHA-256 sidecars preserve each task's result and compile/resource logs. This run used one CPU, 16 GiB, and a 3,600-second runner timeout; no simulation result was produced.
