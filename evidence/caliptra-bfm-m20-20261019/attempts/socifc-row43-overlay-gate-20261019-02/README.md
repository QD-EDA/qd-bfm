# SoC-IFC row 43 overlay gate, retry 2

Fresh one-row gate for `soc_ifc_trng_test` after the first compile reached two generated mailbox invalid-access sequence selectors that were not covered by the initial overlay. The revised helper redirects each `axs_reg.get_name()` selector through a local string in those sequence functions, preserving their case labels and behavior.

Pinned Caliptra/Adams Bridge sources and c339 compiler are unchanged from gate 1. Resources: 1 CPU / 2 GiB; 1,800-second runner timeout; 2,100-second Slurm limit. Result archive and SHA-256 will be copied here before cleaning the remote run tree.

Job 3235 failed before invoking the simulation harness because the source snapshot was unpacked at the run root instead of the expected `source/` directory. `raw/runner.log`, `raw/job-meta.txt`, and `raw/runner.resource` preserve the setup error; their SHA-256 values are in `raw/SHA256SUMS`. No row verdict is inferred.
