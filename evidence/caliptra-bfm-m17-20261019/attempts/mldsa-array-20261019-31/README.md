# Generated MLDSA rows 78–89 and 91–106

Array job 2943 ran 28 generated-UVMF MLDSA rows at throttle 3, one CPU and 4 GiB per task, with 600 s per-row timeouts. Every row compiled successfully with pinned Icarus `9b5fad2afb4104caa816b257d5bccc40f01b8c66`.

Raw task archive: `raw/job-2943.tar.gz`, SHA-256 `27c9094a1776b333df7001d8d5b20874999bae1dc56d826256de2fc0f6d8a72c`. The archive preserves results, compile/simulation logs, commands, overlays, resource records and job metadata. Compiled VVP images and copied runtime trees are excluded. The source snapshot and its checksum are stored next to this README.

The first run produced four timeout results (rows 79, 81, 89 and 104); their logs show continued register writes but no complete-test pass marker before the 600 s cap. Twelve ML-DSA rows (80, 82, 86, 91–93, 96–97, 99, 101, 103 and 106) stopped on a scoreboard/predictor UVM fatal: a cast from `mvc_sequence_item_base` to the generated parameterized AHB transfer failed. The overlay already replaced the generated declarations with the BFM transfer typedef; the runtime object type still needs investigation.

Rows 83–85, 88, 94–95, 98 and 100 stopped in the ML-KEM sequence while trying to write `ml-kem/tv/keygen_ext_input.txt`. The pinned Adams Bridge source tree has no `ml-kem/random_test_ml_kem.py` helper, so these logs do not establish a crypto result. The runner also omitted pinned Dilithium helper binaries for ML-DSA rows 78, 87, 102 and 105. That setup omission is corrected and gated in attempt 32; those four row outcomes will be updated from the fresh runs.
