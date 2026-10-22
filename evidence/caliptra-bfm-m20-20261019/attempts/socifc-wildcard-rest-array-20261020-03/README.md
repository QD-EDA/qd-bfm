# SoC-IFC wildcard cohort — guarded aligned-bin overlay

The pinned `mbox_csr_covergroups.svh` alignment bins exceed Icarus's 4,096-value filter limit. The runner now splits only that source's four 32,768-value bins into eight adjacent ranges each, retaining every original alignment filter and sampled value. The sibling register covergroup file has no such bins. Wildcard and generated-source overlays remain per-run; no RTL, firmware, stimulus, assertions, or pass criteria change.

Source snapshot SHA-256: `b057a9ec657e163cd63eb5240d81e5e70b2e6318dc066bbf47513ca0fde60520`. Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; M20 Icarus pin `cae035642e056644274a01e98d4422ce286685b4`. The focused coverage-overlay test and all 86 runner tests passed before submission. The gate requests one CPU, 12 GiB, and a 3,600-second runner cap.

Rows 0–3 and 43–45 run with array throttle one and 12 GiB per task. Submitted as array 3304 with dependency `afterany:3303`.

This is the alignment-only intermediate snapshot; the complete control-transaction coverage overlay is in the later row-4/array attempts 05/04.

Array 3304 tasks 0–3 and 43–45 were terminal `BLOCKED` after 70.355–71.619 s; each compile exited 137 near the 12 GiB cap and no simulation ran. Icarus reported the split alignment bin `with` expression unsupported. All seven archive SHA-256 sidecars verified.
