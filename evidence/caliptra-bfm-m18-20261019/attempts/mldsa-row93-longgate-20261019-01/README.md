# ML-DSA row93 extended-run gate

Row93 (`ML_DSA_randomized_verif_test`) compiled and showed ongoing signature-register progress but hit the initial 600-second simulation cap without a verdict. This one-row rerun extends only the wall-clock timeout to 3,600 seconds; source, overlay, RTL, stimuli, and pass criteria are unchanged.

- Row: 93; `#SBATCH --array=93`
- Icarus: `cae035642e056644274a01e98d4422ce286685b4`, binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`
- DAN-DESKTOP: 1 CPU, 2 GiB, 3,600-second test timeout, 75-minute Slurm wall limit
- Source snapshot SHA-256: `78c3eae07e1d080ba38f7fc1399d7dc28770df42c3ffebc23a0cfaacafc04e6f`
- Run script SHA-256: `5ff7d6595a0ad0cb34bb27340dd00611ce30d3caff99cde7880bf5326cfe6c39`

Job 3076 was invalid: after changing the job name, the script's `--chdir`/`RUN` paths named `m18-mldsa-row93-long-array-20261019-01`, while staging used the `...longgate...` path. Slurm fell back to `/tmp`; no test runner started and no test result was produced. The scheduler log and job metadata are in `invalid-3076/` with SHA-256 values recorded in `submission.txt`. A corrected fresh attempt follows in gate 02.
