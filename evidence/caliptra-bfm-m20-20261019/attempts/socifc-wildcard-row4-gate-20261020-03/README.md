# Row 4 wildcard gate — aligned-bin overlay

The prior row-4 run and its seven dependent cohort rows compiled until Icarus dropped the 32,768-value aligned coverage bins at the 4,096-value filter limit. The runner now partitions those bins into eight adjacent 4,096-value ranges while keeping each original alignment filter. The sampled value set is unchanged; no RTL, firmware, stimulus, assertions, or pass criteria change.

This gate reuses the verified generated-selector, callback, constructor, and no-result-helper overlays. Source snapshot SHA-256: `df5136d0934a583137a5f1288ac398d392b3e62535966fb5c6d83e59b7b00899`. Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; M20 Icarus pin `cae035642e056644274a01e98d4422ce286685b4` with the established compiler and VVP hashes. It requests one CPU, 12 GiB, a two-hour Slurm limit, and a 3,600-second runner cap.

The focused coverage-overlay tests and all 86 runner tests passed before submission. The prior terminal archive is preserved in `../socifc-wildcard-row4-gate-20261020-02/raw/`. No status changes until this run's result, markers, archive, and sidecar are verified.

Submitted as job 3298 on 2026-10-20 at 04:52 UTC. The dependent cohort array is 3299.


This submission is retained as invalid setup evidence: the alignment-bin helper was applied to the sibling register-covergroup file, which has no such bins, so overlay preparation rejects it before compilation. The corrected runner restricts the transform to `mbox_csr_covergroups.svh`; jobs 3303/3304 carry that guarded snapshot.

Job 3298 was terminal `BLOCKED` in overlay preparation after 0.148 s, with cause `expected one legal_word_aligned_val coverage bin, found 0`. Compile and simulation did not run; this is invalid setup evidence, not a row verdict. Archive SHA-256 `ee22cf58d0a297e9cfb6758850ac15185c622c9edbcd45aad9d614df963fbaf6` verified.
