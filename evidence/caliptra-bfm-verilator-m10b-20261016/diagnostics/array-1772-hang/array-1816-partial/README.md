# Partial diagnostic array 1816 (overlay v1)

Array 1816 used the uninstrumented AW/W/B overlay `e8fec740da3fb9ffcd72fd7eb72c63480d30bd4de531e390772138dcf9ad6d1a` and model `430fcb1ee9fea6f76ce3efc7c8fe7efa3150d7d338315858776c7836e1baf7e0`. It ran on `DAN-DESKTOP` at six tasks maximum, one CPU and 3 GiB per task.

Ten rows reached terminal results: five PASS and five FAIL. Two rows failed at `AXI_SUB_AR_HSHAKE_ERR`; three failed at `ERR_ECC_PRIVKEY_NOT_STABLE`. The verified per-row table is `results.tsv`; raw result directories, logs and resource reports are in `completed-results.tar.gz`. All ten per-result `FILE-SHA256SUMS` checks passed. The archive SHA-256 is `f3b0acfd295e5b7daea5455c467e113d6fe6f408b10b26e7428831c3e3e1cbf4`.

Array 1816 was canceled at 15:24 MDT after the AR failure showed the current overlay still had an uncorrected read-address handshake. At cancellation, tasks 4, 8, 12, 13, 14 and 15 were running; tasks 16–102 had not started. These are cancellation/overlay-revision statuses, not TIMEOUTs. The running-task snapshot is `running-before-cancel.txt` with SHA-256 `a337a8fab71e3ef34b8ebd7011ec6ca96b6f85715e48cd3b2ae7bb11f38ed54f`.

These ten results are diagnostic evidence for overlay v1, not the final M10 comparison. The AR and ECC assertion findings still need root-cause work; the 103-row campaign will be rerun with a corrected overlay after a matching one-row firmware result.
