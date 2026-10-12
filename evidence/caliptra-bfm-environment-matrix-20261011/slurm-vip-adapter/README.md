# Caliptra AXI adapter matrix validation

Array 464 is the first run of the two missing-VIP matrix rows using the QD AXI checker through the compatibility adapter. The pinned Caliptra source declares `caliptra_top_tb` as the real simulator top for both filelists; the build-target names remain in the row IDs only. See `top-audit.txt`.

The run uses Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`), Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and QD-BFM adapter/checker from commit `3c41c09eca43ed31506013ca70973b99388421aa`. It appends the checker module source to each copied filelist and points `CALIPTRA_AXI4PC_DIR` at the committed `Axi4PC.sv` adapter.

Job 464 used one CPU, 3 GiB, and two hours per task; array throttle was two, and each test had a 6,900-second timeout. The immutable remote run directory is `/home/dsell/slurm-runs/caliptra-bfm/a2/vip-adapter-c339-20261011-01`.

Both compile steps exited 1 with 46 mixed-driver diagnostics in `caliptra_top_tb_axi_complex.sv` and the clock-generator diagnostic. The mixed assignments are traced to the `rst_mgr()` task in `axi_if.sv`, which procedurally assigns the same manager-side fields that the top continuously assigns. IEEE 1800-2023 §6.5 (pp. 90-91) prohibits those mixed assignments, so this is a testbench portability blocker; see `../reproducers/mixed-driver-interface-task/README.md`. The `caliptra_top_tb.sv:138` clock diagnostic is tracked by #545 and is now reproduced from the actual clock snippet: c339 rejects it and Verilator 5.032 builds/runs it (see `../reproducers/caliptra-top-clock-generator/README.md`). The earlier bit-versus-logic distinction remains unconfirmed. The row is still blocked by the separate mixed-driver diagnostics; the original `Axi4PC.sv` syntax failure is gone, and neither full-top simulation ran.

## Follow-up on the mixed-driver diagnostics

Job 548 recompiled `caliptra_top_ss_mode_tb` with `-gno-assertions` using the same c339, source snapshot, and filelist. It produced the same 46 mixed-driver diagnostics (23 signal names on each of two interfaces) and the same clock-generator diagnostic; assertions are not the cause. The compile-only output and provenance are in `noassertions/`.

The task/interface reducer in `../reproducers/mixed-driver-interface-task/` reproduces the mixed-driver error with c339; compiling with `-DSYNTHESIS` removes the reset task and passes. Verilator 5.051 accepts the reduced pattern. This confirms a testbench portability blocker, not a separate Icarus defect. The clock issue is now independently reproduced from the actual Caliptra source; only the bit-versus-logic distinction remains unconfirmed. The full-top row remains blocked by the mixed-driver diagnostics. The prior delay-macro-only reducer still passes with the full-top flags `-g2017 -gassertions`.
