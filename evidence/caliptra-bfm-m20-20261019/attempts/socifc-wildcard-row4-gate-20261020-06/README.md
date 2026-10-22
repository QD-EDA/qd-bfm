# Wildcard overlay setup attempt — terminal result

The prior full-overlay jobs (3308 and 3309) still compiled the original SoC-IFC package coverage include, then hit the 12 GiB memory cap. This attempt redirects the package source to a disposable overlay copy so its `src/...transaction_coverage.svh` include resolves to the transformed file. The aligned-length bins use exact wildcard masks for the original ranges and filters. No RTL, firmware, stimulus, expected values, assertions, or pass criteria change.

Source snapshot SHA-256: `7da7c56a030b7fe956d18a6ef364842582756edcddeaf0e5dec9363c59321145`. Branch `codex/caliptra-bfm-stack-20261006`, HEAD `391d41bfd2abf48c11c2a22727c43a2177cd3061`. Runner SHA-256: `98dd93f066b0a43f4548a52f606b0cd9b0a8eea19b98c785410bd11e955c8af4`; test SHA-256: `a0a6b345670ec387a8714d20d6e49e510afb70ee1b6b55b011bdbaaae0cfdfc5`. Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; M20 Icarus pin `cae035642e056644274a01e98d4422ce286685b4`. The runner suite passed 88 tests; see `diagnostics/runner-tests-after-socifc-coverage-overlay.log`. Tasks request one CPU, 16 GiB (rounded up from 1.25× the prior ~12.55 million KiB peak), and a 3,600-second runner cap.

Submitted as job 3322 with dependency `none` at 2026-10-20T05:32:24+00:00.

Terminal result: job 3322 row 4 is BLOCKED before compilation (runner setup ended after 0.147 seconds; `compile_exit` is null). The validator treated the four expected exact alignment wildcard bins as unsupported leftover wildcard syntax, so no compiler or simulation ran. The row archive and SHA-256 sidecar are preserved here. The validator was corrected for follow-up job 3330.
