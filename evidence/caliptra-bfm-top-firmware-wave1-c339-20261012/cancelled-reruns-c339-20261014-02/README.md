# Fresh reruns after host restart

Job 936 was interrupted by the 2026-10-14 DAN-DESKTOP restart before wrapper completion. Its four attempts have no result JSON or testcase marker and are classified `INFRA-INTERRUPTED`; their logs and hashes are preserved in [`../cancelled-reruns-c339-20261014-01/infra-interruption-evidence-936/`](../cancelled-reruns-c339-20261014-01/infra-interruption-evidence-936/). The partial build/output trees were deleted after evidence commit `6e16604`.

This directory holds the fresh retry of the four original array-799 maintenance cancellations: 799_28, 799_30, 799_34, and 799_35. They map to source rows 37, 39, 43, and 44, respectively. Array tasks 1–4 use the same pinned source/toolchain and original per-test timeout. Each task requests 1 CPU and 3 GiB, has a 6h10m allocation, and the array throttle is 6. No local duplicates are running.

The pre-submit cluster check found the `verilog` partition up with 20 idle CPUs, pinned inputs verified, and only unrelated job 948 pending by dependency. [`selection.tsv`](selection.tsv) maps the array tasks; [`results.tsv`](results.tsv) records terminal outcomes only after complete run evidence is collected.


## Array 949 staging failure

Array 949 was submitted at 07:38:08 MDT and all four tasks exited at 07:38:09–10 with exit code 1 before reading any case. Each log says the script could not find `selection.tsv` at the run-root path because it had only been staged under `submit/`. No per-test runner, compiler, or simulator ran; this is `SETUP-ERROR`, not a firmware verdict. The four short Slurm logs are preserved under [`setup-error-949/`](setup-error-949/).
