# Draft report: SHA accelerator status assertion starts from a nonzero state

**Review only; not submitted.**

The current-c339 rerun of row 31 (`sha_acc_intrblk_test`, Caliptra RTL pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`) exits FAIL at the testbench's “Register bit-field(s) mutable over AXI” assertion for `SHA_ACC_INTR_BRF_ERROR_INTERNAL_INTR_R` (`0x30021814`). An observation-only trace samples the internal status as `0b1010` before the test writes that register over AHB, before the corresponding AXI write begins, and again at assertion sampling. Therefore this failure does not show that the AXI transaction mutated the status; the assertion is evaluating a preexisting status value.

Suggested review: check the interrupt-block test's ordering and mutability assertion. If the assertion compares writability by assuming reset-zero instead of using the pre-transaction value/field access policy, make it compare the relevant before/after state while preserving the intended read-only check.

Evidence: `../attempts/row31-status-trace-20261019-01/raw-job-3139_31.tar.gz` (SHA-256 `4c814f86c59decd9240837a7fcae5df57801408a1dc73c398dd7c6475f1348b1`), with manually verified intern triage at `../attempts/row31-status-trace-20261019-01/row31-triage-intern.txt`.
