# Draft report: sigencode_z test expects multiple polynomials from one-polynomial interface

**Review only; not submitted.**

The current-c339 run of row57 (`sigencode_normal_test`, Adams Bridge pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`) completes with 3,072 mismatch messages at indices 256–1791 across two checks. The 256-value prefixes match; values beyond index 255 are X. The testbench sizes its expected output as `MLDSA_N * MLDSA_L`, and the vector generator creates `N*L` coefficients (`N=256`, `L=7`), while this top-level operation exposes one 256-coefficient polynomial per transaction. M16 also records the same explicit range.

Suggested resolution: keep the test's seven-polynomial coverage and invoke the one-polynomial top-level once for each polynomial, or separate the interface scope into a distinct test. Do not truncate the expected vector or change pass criteria to 256.

Evidence: `../attempts/row57-current-c339-numpy-20261019-01/` and `../../caliptra-bfm-m16-20261018/attempts/gate-adams-row57-classifier/`.
