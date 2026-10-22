# Adams Bridge missing-config-header one-row gate

Row 58 (`sib_rand_test`) gates the existing hash-guarded overlay that maps the stale `mldsa_config_defines.svh` filelist path to the pinned ABR configuration header and renames stale ML-DSA paths to current ABR sources. No macro values, RTL, expected values, or pass criteria are changed.

The run uses Icarus main `cae035642e056644274a01e98d4422ce286685b4`, one CPU, 4 GiB, and a 600-second per-row timeout. Source snapshot SHA-256: `109e0fdad561d881c5e11d9253c82a30ce898e54216bf2bc6fe612a1b23060af`. Job 3051 stopped in runner setup after 0.013 seconds: the filelist overlay correctly remapped the package, but the helper incorrectly required a testbench package import. The pinned sample_in_ball_tb.sv has no such import, so compilation and simulation did not start. This diagnostic gate is retained; it is not the terminal row result. Archive SHA-256: c4e1abe7dab91bdc829607d6267360f592fbca3b296ef10d5b063962a3eafd75.
