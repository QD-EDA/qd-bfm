# Expanded SoC-IFC Icarus coverage overlay

The 16 GiB runs 3330/3331 exposed remaining SHA-512 aligned filters, SoC-IFC register/status byte filters, generated-package psprintf syntax, and a compiler memory ceiling. The first 24 GiB attempt, jobs 3338/3339, stopped during source validation before compilation: the expected ss_mode configuration digest was malformed at 63 characters. Its archived result is in the preceding attempt directories. The digest constant is corrected in this snapshot.

This run overlays the pinned SoC-IFC coverage and configuration includes implicated by those logs: aligned bins in MBox and SHA-512 CSR coverage, nonzero-byte filters in CSR/control/status coverage, wide transaction bins, and trailing empty psprintf arguments. Overlays are disposable per-run files; upstream Caliptra sources are unchanged.

Source snapshot SHA-256: 8ca6b3c0bde27c5b81900e273b6172ee7d2b31b79e5e62467889f7f6f25771b5. Branch codex/caliptra-bfm-stack-20261006, HEAD 391d41bfd2abf48c11c2a22727c43a2177cd3061. Runner SHA-256: 2b73eb666e901dfb35db46034c83b227b9161bb85e4eb40401f6f5f2d74a7379; test SHA-256: 0c98aa7019a1aaea61b2cd782e59cd41750444987ac5c99641c1ecc3b8daa2aa. Caliptra pin 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e; Adams Bridge pin b77e3d899e828d626cfc2a0d26a6b5704cc121e0; M20 Icarus pin cae035642e056644274a01e98d4422ce286685b4. Runner suite: 90 tests passed (log SHA-256 9065d9850de8a2b9f125967940560592d82f0567cf4d040a7701079aea525149).

Each task requests one CPU and 24 GiB (1.25 times the measured 16,738,140 KiB peak, rounded up), with a 3,600-second runner timeout and 10 minutes of scheduler overhead. The row-4 gate runs first; the seven-row array has concurrency one and depends on that gate with afterany.

Submitted as row-4 gate job 3346 at 2026-10-20T06:32:27Z, with no dependency.

Job 3346 row 4 is terminal BLOCKED before simulation. Compile exited 52 in 14.049 seconds at 2,063,092 KiB peak RSS. The transformed 256-bit rand_key range is rejected because the pinned Icarus coverage engine only represents wide bins from unsigned packed exact constant values; the two 256-bit any_value range bins fail the same way. The complete log also shows untransformed wide bins and empty psprintf calls in cptra_status_pkg, ss_mode_status_pkg, and mbox_sram_pkg, plus generated selector method/type errors. This is a compiler representation failure, not a memory limit.

Archive raw/job-3346_4.tar.gz SHA-256 f2d952b51c13f983ffdd59f902468b02605cf6fbcc62304142cfcf871ebbdf54 matches its copied remote sidecar. No simulation or testcase verdict was produced.
