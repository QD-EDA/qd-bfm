# SOC-IFC testbench compile triage on c339

Four fresh run directories explored the pinned `soc_ifc_tb` setup with run-local copies of `soc_ifc_tb_pkg.sv`; the Caliptra source and filelist stayed unchanged.

- Job 471 added the assignment-pattern apostrophe at `_security_state_dict`; compilation then stopped at another associative-array initializer on line 132.
- Job 472 added apostrophes to the ten array declaration initializers; compilation then stopped at `lock_fuses` lacking a return type.
- Job 473 added `void` to the `lock_fuses` and `unlock_fuses` prototypes/definitions; compilation then reported three malformed struct assignment patterns.
- Job 474 added apostrophes to those struct assignment patterns. The compiler then reported an unsupported constraint in `soc_reg_intrblk_test.svh:283`, `$ivl_clocking_sample` undefined in `soc_ifc_tb.sv:614`, and segfaulted (compile exit 139). Simulation did not run.

The row remains BLOCKED on specific c339 testbench incompatibilities: random-constraint translation and clocking-sample support. No broader testbench port or behavior changes were attempted. All source overlays, raw compiler logs, resource records, tool versions, hashes, host snapshots, and exact scripts/manifests are preserved here. The job 474 task used Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, 1 CPU, 3 GiB, and a 6,900-second per-test timeout.
