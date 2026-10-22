# SoC-IFC wildcard cohort — terminal result

The pinned `mbox_csr_covergroups.svh` 32,768-value alignment bins are split into adjacent 4,096-value ranges with the original filters retained. The SoC-IFC control transaction overlay aggregates unsupported wide key/entropy/seed bins and keeps the per-bit covergroups and exact nonzero-byte coverage. Wildcard/generated-source compatibility stays per-run. No RTL, firmware, stimulus, expected values, assertions, or pass criteria change.

Source snapshot SHA-256: `ed2b63872e286974b92834af1f1cf3425c20bad30d52a944f0ee81e596758d64`. Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; M20 Icarus pin `cae035642e056644274a01e98d4422ce286685b4`. The focused coverage-overlay test and all 87 runner tests passed before submission. Tasks request one CPU, 12 GiB, and a 3,600-second runner cap.

Rows 0–3 and 43–45 run with throttle one. The array follows the refreshed row-4 gate with `afterany`.

Submitted as array 3309 with dependency `afterany:3308` on 2026-10-20 at 04:57 UTC.

Terminal result: jobs 3309 rows 0, 1, 2, 3, 43, 44, and 45 are all BLOCKED (compile exit 137 after 70.420–71.516 seconds); none simulated. Each compile still selected the original `soc_ifc_ctrl_transaction_coverage.svh:36` wide `rand_key` bin and automatic bins over 64 bits because the overlay include path did not shadow the package-relative `src/...` include. The alignment `with` expression was also unsupported and dropped. All seven task archives and SHA-256 sidecars are preserved here.
