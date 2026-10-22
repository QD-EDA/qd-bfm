M14 skencode diagnostic gate — SUPERSEDED, NOT COUNTED

Job 2353 passed the generated test's existing comparisons and negative error check, but this run used a run-local replacement for abr_params_pkg.sv. Because M14 explicitly excludes RTL overlays, it is retained only as diagnostic evidence and is not counted toward the 22/44 target. A fresh gate will use the pinned package and put the width compatibility in a testbench-only overlay.

Compile/simulation exits were 0; the four generated vector files were present; three comparisons completed; there were no mismatch messages or unexpected error-flag messages. Raw evidence was hash-verified before cleanup.

Remote run-tree bytes freed: 170105.
