1. Trace rows 93/97 from the SHAKE sampler output through `abr_ctrl` register-write gating to the raw AHB result.
2. Compare the failing behavior with Verilator or a second simulator; if the full UVM bench is unsupported, reduce to the smallest equivalent RTL reproducer.
3. Investigate the two largest BLOCKED groups: fixed-array wildcard coverage bins and absent ML-KEM generation inputs.
4. Apply only source-preserving testbench/BFM/filelist/setup overlays; gate one affected row before any array.
5. Run eligible rows on pinned sources/tools, archive logs/results with SHA-256, and clean completed build trees.
6. Reconcile all changed M20 rows, audit the full TSV, publish before/after counts, and commit only M20 evidence and scoped fixes.
