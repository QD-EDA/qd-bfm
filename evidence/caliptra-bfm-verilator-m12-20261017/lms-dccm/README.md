# M12 LMS DCCM image-load overlay

Draft 9's one-row gate targets `fw_test_lms32` (`8c392993b1af6e0c`). M11 Verilator stops during `$readmemh` at `dccm.hex:1` because the sign-extended DCCM address is outside the first dimension of the pinned two-dimensional preloader array. The c339 result is unverified.

The build-time services overlay adds a Verilator-only 1D byte scratch array, loads an LMS-specific normalized DCCM image into it, then copies the bytes into the existing 64-bit-word preloader. The runner changes only `@FFFFFFFFB000xxxx` address directives to their DCCM-relative offsets; it checks that payload tokens are unchanged, validates the normalized image with the existing `readmemh_image` parser, records original and normalized hashes, and preserves the normalized image. The original firmware-generated `dccm.hex` remains unchanged.

The pinned services source hash is `5a048411bf1dcae2cda6406a6d32afba0dc9f9ef447c301875f7b6c7e1939343`; the generated overlay hash is `2eb6b5aa502050a657265c51af189c0e96e69c87f40db06c2619393d394c56b0`. The DCCM address normalizer's three focused tests pass. Model build 2118 completed, and the full-timeout gate 2123 passed the firmware at mcycle 2,675,745 with no scanner or assertion failures. The checksummed result bundle is under `generated/gate-2123/`.

The pinned QD-BFM source archive and common filelist, AXI, and base case-runner helpers are reused from sibling `strap-guard/` evidence and copied into the isolated Slurm run directory when staged. Only the LMS address normalizer, services overlay generator, and runner patch are specific to this gate.

## Gate selection

| Row | Baseline | c339 baseline | Candidate gate |
| --- | --- | --- | --- |
| `8c392993b1af6e0c` | FAIL at DCCM `$readmemh`, before firmware | UNVERIFIED | Diagnostic job 2119 hit its 600 s cap without a firmware result. Full-timeout job 2123 passed at mcycle 2,675,745 (1,833.9 s simulation, 1,834.7 s total), with `sim_scan.bad=0`. |

`gate-selection.tsv` records the row identity and original 21,600 s per-test timeout. Job 2119 evidence and generated firmware/DCCM images are preserved in `generated/gate-2119/`; its result and simulation logs show the 600 s wrapper cap ended before firmware ran. Full-timeout gate 2123 passed `fw_test_lms32` at mcycle 2,675,745 with `sim_scan.bad=0`. Array 2146 ran only selection indices 1–33, excluding the passing gate row at index 0; it began at `%5` while ECC job 2144 occupied the sixth A2 slot, then increased to `%6` after ECC completed. All 33 array rows passed. Their row manifests and wrapper logs are in `generated/array-2146/`, whose evidence archive SHA-256 is recorded alongside it. The 34 LMS rows changed from M11 FAIL to M12 PASS.
