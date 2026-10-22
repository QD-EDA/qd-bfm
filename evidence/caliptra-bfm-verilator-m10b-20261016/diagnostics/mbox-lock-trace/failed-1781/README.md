# Job 1781: assertion stop before the mailbox-lock trace

Job 1781 rebuilt the logging-only model with `--assert` and `CLP_ASSERT_ON`, then stopped at simulation time 4000 on the known `AXI_SUB_AW_HSHAKE_ERR` during the initial fuse write. It failed before the first `MBOX_LOCK` access, so it produced no mailbox-lock cycle evidence and is not a result for `smoke_test_mbox`.

The `axi_if` diagnostic copy adds read-transaction logging but retains the pinned AWREADY sampling. The official M10b AW-sampling overlay is being tested separately by array 1772. For the next focused MBOX trace, assertion monitors will be omitted from this diagnostic build only; the pinned BFM timing and MBOX CSR behavior will remain untouched, and the official assertion-enabled overlay array will continue independently.

All result, log, build, filelist, and resource files were copied from DAN-DESKTOP and verified against its `SHA256SUMS`; the staged-input manifest and submitted batch script are preserved. Submitted script SHA-256: `f98c1913f26d7ec712a9ea6fe5ee77e1799fc8df8d9d42cfcfc0f85a6d270a88`. The model SHA-256 is in `model.sha256`.
