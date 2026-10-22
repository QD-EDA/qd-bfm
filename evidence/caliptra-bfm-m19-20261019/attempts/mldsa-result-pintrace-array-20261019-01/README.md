# ML-DSA result-register AHB pin trace (prepared)

Rows 93 and 97 both read `MLDSA_VERIFY_RES[0..15]` as zero in M18. The archived row 93 run has no raw pin trace, and row 97's failure-injection sequence produces two all-zero result batches despite flipping bit 20 of `MLDSA_SIGNATURE[16]` (`8f3b5a6a` to `8f2b5a6a`). The prepared array traces AHB pins on rows 93 and 97, and adds an uninstrumented current-c339 rerun of row 76.

- The trace helper and its source/trace hash manifest are described in `../trace-runner-20261019-01/README.md`.
- Slurm script SHA-256 `bcb31f8995844de07655fda459cf5f29b52517d927312021352e534e9889aad9`; `bash -n` passes.
- Rows 93 and 97 log observation-only AHB pins around reads at `0xd8–0x114`; row 76 uses the ordinary runner. Per-row caps are 3,600 seconds for 93/97 and 600 seconds for 76.
- The array is not submitted until array 3100 and the six-row current-c339 comparison array are terminal. It uses the same protected Caliptra/Icarus pins, one CPU and 2 GiB per task, and two concurrent rows.
- Instrumentation does not change DUT, firmware, test sequence, expected values, or pass criteria.

Result: pending.
