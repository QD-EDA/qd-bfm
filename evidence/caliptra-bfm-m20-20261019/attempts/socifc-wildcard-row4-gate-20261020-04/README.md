# Row 4 wildcard gate — guarded aligned-bin overlay

The pinned `mbox_csr_covergroups.svh` alignment bins exceed Icarus's 4,096-value filter limit. The runner now splits only that source's four 32,768-value bins into eight adjacent ranges each, retaining every original alignment filter and sampled value. The sibling register covergroup file has no such bins. Wildcard and generated-source overlays remain per-run; no RTL, firmware, stimulus, assertions, or pass criteria change.

Source snapshot SHA-256: `b057a9ec657e163cd63eb5240d81e5e70b2e6318dc066bbf47513ca0fde60520`. Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; M20 Icarus pin `cae035642e056644274a01e98d4422ce286685b4`. The focused coverage-overlay test and all 86 runner tests passed before submission. The gate requests one CPU, 12 GiB, and a 3,600-second runner cap.

Submitted as job 3303 with dependency `afterany:3299`. Its dependent array is job 3304.

This is the alignment-only intermediate snapshot; the complete control-transaction coverage overlay is in the later row-4/array attempts 05/04.

Job 3303 was terminal `BLOCKED` after 71.583 s with compile_exit=137 and no simulation. Peak RSS was 12,551,852 KiB. The split alignment bin still used an unsupported `with` expression and compilation reached the 12 GiB limit. Archive SHA-256 `bfdea0b29d47245aebe9ee66e2033cc92467d55d390624297e4bd3d4eb16fe0c` verified.
