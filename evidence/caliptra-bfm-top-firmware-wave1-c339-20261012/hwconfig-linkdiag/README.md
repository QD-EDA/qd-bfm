# `smoke_test_hw_config` firmware-link diagnosis

## Finding

The undefined `service_soc_ifc_notif_intr` is an upstream firmware header-linkage defect. At the pinned Caliptra RTL revision, `smoke_test_hw_config/caliptra_isr.h:129` defines the callback as a non-static `inline` function. The ISR translation unit includes the header and emits an external call through `nonstd_veer_isr(soc_ifc_notif)` at `libs/caliptra_isr/caliptra_isr.c:808`. Under the QD runner's `-std=gnu11 -O2`, `caliptra_isr.o` retains an undefined external reference, while `smoke_test_hw_config.o` does not define the symbol. The pinned GCC is xPack RISC-V Embedded GCC 15.2.0.

This points to the firmware's inline linkage, not a QD runner source-selection or simulator issue. The QD build flags trigger the defect, but the callback declaration is in the upstream firmware test suite. No QD-side patch is warranted for this milestone.

## Probes

All builds used Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and the same pinned firmware source/dependencies.

| Build flags | Result | Evidence |
|---|---|---|
| `-std=gnu11 -O2` | Link fails with undefined `service_soc_ifc_notif_intr` | `run-02/o2-inline/build.log`, `status.txt`, raw object symbol output in `run-02/o2-inline/symbol-evidence.txt` |
| `-std=gnu11 -O2 -finline-functions` | Same undefined callback | `run-02/o2-inline/build.log` |
| `-std=gnu11 -O3` | Callback issue is passed, but link fails because ROM exceeds 96 KiB | `run-01/qd-gnu11-o3/build.log` |
| `-std=gnu11 -Os` | Undefined ISR callbacks and other helpers remain | `run-02/os/build.log` |
| `-std=gnu11 -O2 -fgnu89-inline` | Multiple definitions for header functions including `lsu_read_32`, `lsu_write_32`, and `SEND_STDOUT_CTRL` | `run-02/gnu89-inline/build.log` |
| upstream default flags | Fails earlier with conflicting `soc_ifc_w1clr_sha_lock_field` declarations | `run-01/upstream-default/build.log` |

## Raw evidence

Each variant has its complete `build.log` and a `status.txt` recording host, RTL commit, compiler flags, and build exit code. The captured Slurm output files `run-01/slurm-588.out` and `run-02/slurm-589.out` are empty because the script redirected each build's output to its variant log. The old Slurm job records have expired; the raw per-variant status and build logs remain the evidence of those runs.

SHA-256 digests for all copied logs and status files are recorded in `source-excerpts.txt` alongside the relevant source and `nm` output.
