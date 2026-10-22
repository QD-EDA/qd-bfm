# Expanded SoC-IFC Icarus coverage overlay

The 16 GiB runs 3330/3331 exposed remaining SHA-512 aligned filters, SoC-IFC register/status byte filters, generated-package psprintf syntax, and a compiler memory ceiling. The first 24 GiB attempt, jobs 3338/3339, stopped during source validation before compilation: the expected ss_mode configuration digest was malformed at 63 characters. Its archived result is in the preceding attempt directories. The digest constant is corrected in this snapshot.

This run overlays the pinned SoC-IFC coverage and configuration includes implicated by those logs: aligned bins in MBox and SHA-512 CSR coverage, nonzero-byte filters in CSR/control/status coverage, wide transaction bins, and trailing empty psprintf arguments. Overlays are disposable per-run files; upstream Caliptra sources are unchanged.

Source snapshot SHA-256: 8ca6b3c0bde27c5b81900e273b6172ee7d2b31b79e5e62467889f7f6f25771b5. Branch codex/caliptra-bfm-stack-20261006, HEAD 391d41bfd2abf48c11c2a22727c43a2177cd3061. Runner SHA-256: 2b73eb666e901dfb35db46034c83b227b9161bb85e4eb40401f6f5f2d74a7379; test SHA-256: 0c98aa7019a1aaea61b2cd782e59cd41750444987ac5c99641c1ecc3b8daa2aa. Caliptra pin 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e; Adams Bridge pin b77e3d899e828d626cfc2a0d26a6b5704cc121e0; M20 Icarus pin cae035642e056644274a01e98d4422ce286685b4. Runner suite: 90 tests passed (log SHA-256 9065d9850de8a2b9f125967940560592d82f0567cf4d040a7701079aea525149).

Each task requests one CPU and 24 GiB (1.25 times the measured 16,738,140 KiB peak, rounded up), with a 3,600-second runner timeout and 10 minutes of scheduler overhead. The row-4 gate runs first; the seven-row array has concurrency one and depends on that gate with afterany.

Submitted as seven-row array job 3347 at 2026-10-20T06:32:29Z with dependency afterany:3346.

Job array 3347 is terminal. All seven rows are BLOCKED before simulation. Rows 0–3 exit 52 in 14.038–14.144 seconds, peaking at 2,063,108–2,063,324 KiB. Rows 43–45 exit 145 in 3.531–3.543 seconds, peaking at 857,004–857,224 KiB. The compiler rejects wide rand_key and any_value ranges, and reports generated-package issues including 52 unknown wait_for_num_clocks task calls, 17 empty psprintf calls, unsupported dist context propagation, virtual-interface type mismatches, missing factory.create_object_by_name, and writes through input modports. These are compile/tool compatibility failures, not OOMs.

Each raw archive and copied SHA-256 sidecar is preserved in raw/. No simulation or testcase verdict was produced.
