# KeyVault row 6 HSEL overlay fix, attempt 09

Fresh one-row runtime gate for generated KeyVault row 6 (`kv_rand_lock_test`) after removing the generated HSEL low tie-off in all overlay modes. The active QD-BFM AHB manager already drives HSEL from HTRANS; the generated tie-off caused a multi-driver X observed in attempt 08. The row-8 burst-smoke path already removed that tie-off, so this change brings ordinary runtime mode in line with it. RTL, firmware, and pass criteria are unchanged.

- Target: row 6, `kv_rand_lock_test`; firmware commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; row YAML SHA-256 `17c86f0887cfdb3cb3a3ff4ff25ef65a5c932e1a4a8ad34c40cc36352ea2b66f`.
- Host: DAN-DESKTOP. Python 3.14.4.
- Icarus source commit: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; version 13.0 (devel); `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Resources: 1 CPU, 4 GiB requested, 30-minute Slurm cap; 600-second per-test timeout.
- Runner: `run.py --runtime`, `CALIPTRA_UVM_TESTNAME=kv_rand_lock_test`. The runner still requires successful exit, zero UVM errors/fatals, testcase pass marker, and `$finish`.
- The run script preflights normal-mode overlay output and fails if the generated HSEL tie-off remains.
- Source archive SHA-256: `6ac554bfe1e3154775c4f1062f177d463ae9f4bdafe1701e10f69ada8cec474a`.
- Overlay source SHA-256: `79cd01bf7a85233af90153732e841992db4ee7ac57dbf97a8b75c3e3b7f835c3`.
- Raw job archive SHA-256: `bf24bbfeda8c6469d382c05cec3788ee521f5d5556bc527b42879e2c723663c7`.

**FAIL at runtime.** The HSEL preflight passed and the simulation reported no AHB protocol-checker errors. At 3,025 ns, the runtime had one `[OBJ/COPY]` error (`Passing a null object to be copied`) and one `[SCBD_AHB]` fatal: the generated scoreboard could not cast `mvc_sequence_item_base` to its parameterized `ahb_master_burst_transfer` type. The runner returned 1; the run did not pass.

This is consistent with the parameterized-class identity defect already minimized for A3 in [`diagnostics/ahb-uvm-factory-cast/`](../../diagnostics/ahb-uvm-factory-cast/) and tracked internally as issue #666. The intern additionally reported a predictor `$cast failed` diagnostic, but that text is absent from both archived `runner.out` and `sim.log`; it was not used as evidence. The next gate applies the existing generated-transfer typedef workaround to the regular runtime path, as the earlier burst-smoke path already did.

Runtime wall time was 10.38 s and peak RSS was 634,764 KiB. The complete run is `raw/job-2820.tar.gz`.
