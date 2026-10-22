# Generated open-AHB/AAXI batch (attempt 22)

Fresh rerun after job 2909 failed in staging before invoking any row runner. The prepared script and source snapshot are copied to a new Slurm run directory, the snapshot is unpacked once before submission, and all tasks read that shared source tree.

Rows: 16, 17, 44–48, 55. Array throttle: 4; each task requests 1 CPU and 4 GiB, with a 600 s per-row test timeout. Icarus source pin: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`.

Job 2919 completed all eight tasks in 3 s. Tool binary SHA-256: `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Source snapshot SHA-256: `635e8219ba26c4e0e37b3cd76ef151ed8cc7b4f144f46d1189d141af0b76d867`. Raw archive `raw/job-2919.tar.gz`; SHA-256 `934346dc46c28cf443a6f57765754b4c76fc8fa7f8255f2770bc3b98157a5319`.

| Row | Status | Verified first blocker |
|---:|---|---|
| 16, 17 | BLOCKED | SHA-512 generated coverage uses automatic bins on a 512-bit coverpoint (#667); compilation also flags omitted `convert2string()` in string concatenation (#664). No simulation. |
| 44, 45 | BLOCKED | SoC-IFC mailbox covergroup wildcard-transition syntax error at `mbox_csr_covergroups.svh:64` (#661). No simulation. |
| 46–48 | BLOCKED | PV generated sources fail on an empty trailing `$psprintf` argument (#670), with later AHB transfer-member and class-property diagnostics (#663, #664, #671, #672). No simulation. |
| 55 | BLOCKED | ECC generated coverage fails on >64-bit automatic bins (#667), followed by string, nested-property, and input-modport write diagnostics. No simulation. |

All rows used the open-AHB or open-AAXI compatibility filelist/package overlays. The row-level `result.json` entries and `compile.log` files in the archive were checked directly; no row reached simulation or a pass marker. The intern's combined triage returned a broad set of diagnostics across rows, so its summary was not used in place of the per-row evidence.
