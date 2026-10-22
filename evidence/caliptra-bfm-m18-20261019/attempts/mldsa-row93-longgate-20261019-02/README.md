# ML-DSA row93 extended-run gate

Row93 (`ML_DSA_randomized_verif_test`) reached a testcase verdict in the extended run. VVP completed in 1,372.543 seconds and emitted `* TESTCASE FAILED`; the report has 16 `[SCBD_AHB]` errors and zero fatals. Every mismatch is an AHB read (`RnW=0`, `AHB_READ`) with actual returned data `0` against a nonzero expected word, at addresses `0xd8` through `0x114`; the sequence also read `MLDSA_VERIFY_RES[0..15]` as zero. No pin-level waveform was archived, so the result records the monitor/scoreboard transaction values without assigning the zero data to DUT logic or monitor sampling. The simulator exited 0; the testcase marker establishes the result as `FAIL`. This run only extended the prior 600-second cap; source, overlay, RTL, stimuli, and pass criteria were unchanged.

- Row: 93; `#SBATCH --array=93`
- Icarus: `cae035642e056644274a01e98d4422ce286685b4`, binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`
- DAN-DESKTOP: 1 CPU, 2 GiB, 3,600-second test timeout, 75-minute Slurm wall limit
- Source snapshot SHA-256: `78c3eae07e1d080ba38f7fc1399d7dc28770df42c3ffebc23a0cfaacafc04e6f`
- Run script SHA-256: `ced677a87dafb22b98278c86b33f93528c98e1ba928ce1d7228e65e477184f08`
- Result: `FAIL`; raw archive `raw/job-3078_93.tar.gz` SHA-256 `6af44f777f6d9d41e9358f658d9ed0a73dcd297f5fa3006541bf1a7242775612`
- Remote run tree was removed after archive transfer and checksum verification (112 MiB freed).
