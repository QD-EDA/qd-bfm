# M11b focused-trace rebuild and ECC gate

Gate 2082 reached `ERR_ECC_SEED_NOT_STABLE` at 78,353,000 ps but emitted no clear-event trace. The corrected diagnostic replaces the ECC stability macro in the Verilator-only copy with an equivalent `$stable(...)` assertion and puts the sampled signal/cause trace in that assertion's failure action. The same treatment is applied to the DMA/AES sync and MLKEM byte checks, so their trace uses the exact predicate that triggers the original assertion, including unknown-value behavior. The existing non-Verilator macros remain unchanged.

The DCCM range display remains before `$readmemh`, and the runner retains the LMS `dccm.hex`. DMA transition history still records previous/current/next FSM state and error causes. An assert-based generator self-check verified all four trace anchors and predicates before staging.

This fresh run uses QD source commit `1f132e764b6385aeeecd6149703db5ed3eb5c148`, pinned Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052, the official M10b AXI overlay, `--assert`, and `CLP_ASSERT_ON`. One 2-CPU/4-GiB allocation built the model and ran only `smoke_test_ecc_keygen`; the simulator and outer process guard were each capped at 600 seconds. Its terminal assertion result and trace are recorded in `raw/gate-2086/`. Follow-up rows 1–3 are staged in run 06 after this gate result.

Job 2086 was submitted at 2026-10-17 02:57 MDT. It requested 2 CPUs, 4 GiB, and 25 minutes. The initial scheduler checks showed `PENDING` with no start estimate; it later completed. Its result and trace are recorded in [`raw/gate-2086/README.md`](raw/gate-2086/README.md).

At 03:10 MDT, job 2086 remained `PENDING` with no start estimate; the node reported 2 idle CPUs. Local fallback remains unsuitable for pinned evidence because the Mac has Verilator 5.051 devel and no RISC-V firmware compiler.

At 03:22 MDT, Slurm still reported job 2086 `PENDING` (`Reason=Priority`, `StartTime=Unknown`).

## Job 2086 result

The build completed with Verilator 5.052 and model SHA-256 `fd2ca5f1667e91714481aed96708069f8d1ea2898b417dc05f284be6b75c8d26`; it took 5:58.16 with 2,381,808 KiB peak RSS. The 600-second `smoke_test_ecc_keygen` gate returned an assertion **FAIL**, not a timeout: `ERR_ECC_SEED_NOT_STABLE` at 78,353,000 ps, after 497.914 seconds of simulation. The task took 500.411 seconds and used 55,564 KiB peak RSS; no final `mcycle` was produced.

The focused trace shows `seed_reg` changing from `8fa8541c…edf7a5441` to zero at the failing sample. At that edge `ready=0`, `zeroize=0`, `seed_present_reset=0`, `kv_read_fail=0`, and `hwclr=0`. Firmware logged `ECC zeroize flow` at 78,325,000 ps, 28,000 ps earlier. The trace confirms no clear cause was asserted on the failure sample; it does not capture which earlier pulse caused the value change. The updated draft therefore keeps that attribution as an open question. Raw logs, result, resources, overlay, and checksum manifests are under [`raw/gate-2086/`](raw/gate-2086/).

After the result and checksums were preserved locally and the 20-MiB model executable was copied into run 06, the remote run 05 build tree and staged source/overlay were removed. This freed 728,706,586 bytes; its raw logs and result remain in the run directory.
