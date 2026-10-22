# Draft report: butterfly_normal_test repeats an input block and compares mismatched vector scope

**Review only; not submitted.**

On Adams Bridge pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, row 76 (`butterfly_normal_test`) compiles and runs but reports NTT and INTT mismatches. The testbench declares 1,021-entry arrays, while `kyber_stage0.hex` and `kyber_stage0_out.hex` contain 256 values. In `butterfly2x2_test`, the outer `i` loop iterates 0, 64, 128, and 192, but all four inputs are read from `in_val[j*4 .. j*4+3]` without including `i`; that repeats the same 256-value region after the first block. The output checker captures only 256 values even though the input driver iterates four blocks. The testbench-only M16 correction loads the existing expected vector into `out_val`; it does not change RTL, input data, comparison, or pass criteria. Current-c339 job 3140_76 still fails with NTT `out_observed[0]=0x595` vs expected `0x815` and INTT `0` vs `0x815`. An older pinned-only Icarus gate also failed.

This is a testbench stimulus/vector-scope defect, not a demonstrated Icarus compatibility issue. It establishes an inconsistent bench scope but does not alone prove why the first captured output differs; the exact stage/order mapping needs confirmation. Suggested review: align the input block count/indexing, checker capture range, and expected vector while keeping all intended comparisons and coverage. Do not just truncate checks to the first 256 values.

Evidence: `../attempts/mldsa-result-pintrace-array-20261019-02/raw/job-3140_76.tar.gz` (SHA-256 `881e1b927c43729d4c9448a00add3310c03ffcdc796578ce70964dc79e20e237`), plus M16 gates `../../caliptra-bfm-m16-20261018/attempts/gate-ntt-row76-classification/README.md` and `gate-ntt-row76-overlay/README.md`.
