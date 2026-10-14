# Array 799 task 40: smoke_test_ras

Result: **FAIL** before simulation, after 30.90 s, with peak RSS 1,852,336 KiB. The runner exited 1 because firmware build failed; `result.json` was not produced and no progress heartbeat was emitted, so the final mcycle is N/A.

Verified from `output/smoke_test_ras/firmware.log`: the linker reports `undefined reference to service_soc_ifc_notif_intr` at upstream `caliptra_isr.c:808`, followed by `collect2: error: ld returned 1 exit status`. The runner then reports missing `program.hex`, `dccm.hex`, `iccm.hex`, and `mailbox.hex`. This is a firmware build failure distinct from the four compatibility defects already scoped for the overlay; this row was not given a simulation result or reclassified as PASS.

Pinned source and tool versions, resource log, raw firmware/RTL compile logs, task status, and Slurm output are included. Slurm task 799_40 is absent from the live queue; its run output is safe to clean after these artifacts and the main results ledger are recorded.
