# SoC-IFC wildcard cohort rerun — aligned-bin overlay

This reruns rows 0–3 and 43–45 after row 4 using the same source snapshot and overlay. In addition to the exact wildcard range and generated-selector/callback/constructor/helper compatibility overlays, the runner splits each 32,768-value aligned bin into eight adjacent 4,096-value ranges while preserving its alignment filter and sampled set. No RTL, firmware, stimulus, expected values, assertions, or pass criteria change.

Source snapshot SHA-256: `df5136d0934a583137a5f1288ac398d392b3e62535966fb5c6d83e59b7b00899`. Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; M20 Icarus pin `cae035642e056644274a01e98d4422ce286685b4`. Each task requests one CPU, 12 GiB, a two-hour Slurm limit, and a 3,600-second runner cap; array throttle remains one.

The focused coverage-overlay tests and all 86 runner tests passed before submission. This array runs after the refreshed row-4 gate with an `afterany` dependency. No row status changes until each result, markers, archive, and sidecar are verified.

Submitted as array 3299 with dependency `afterany:3298` on 2026-10-20 at 04:52 UTC.


This submission is retained as invalid setup evidence: the alignment-bin helper was applied to the sibling register-covergroup file, which has no such bins, so overlay preparation rejects it before compilation. The corrected runner restricts the transform to `mbox_csr_covergroups.svh`; jobs 3303/3304 carry that guarded snapshot.

Array 3299 tasks 0–3 and 43–45 were terminal `BLOCKED` in overlay preparation after 0.147–0.150 s, all with `expected one legal_word_aligned_val coverage bin, found 0`. Compile and simulation did not run; these are invalid setup artifacts, not row verdicts. All seven archive SHA-256 sidecars verified.
