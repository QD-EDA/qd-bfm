# MLDSA native-model rerun: rows 87, 102 and 105

Submitted as Slurm array 2978 after row 78 gate 2977 reached a terminal result. It runs rows 87, 102, and 105 with a throttle of 3, one CPU and 4 GiB per row, and a 600 s per-row timeout. The source snapshot SHA-256 is `ddd3ec97af2005e00508077bc80b7735a2f9c52ed18c741e3f8c2cf5d9c0dec7`.

The gate confirmed the pinned Dilithium executables stage successfully. In array 2978, rows 87 and 102 compiled and ran the native-model checks successfully, then hit the AHB scoreboard cast failure tracked by #666. Row 105 reached the 600 s cap after seed and signing-randomness writes without a final verdict.

| Row | Slurm task | Result | Evidence |
| --- | --- | --- | --- |
| 87 | 2978_87 | FAIL — #666 scoreboard cast | `raw/job-2978-rows-87-102-105.tar.gz#tasks/row-87/output/result.json` |
| 102 | 2978_102 | FAIL — #666 scoreboard cast | `raw/job-2978-rows-87-102-105.tar.gz#tasks/row-102/output/result.json` |
| 105 | 2978_105 | TIMEOUT at 600 s | `raw/job-2978-rows-87-102-105.tar.gz#tasks/row-105/output/result.json` |

The archive SHA-256 is recorded in `raw/job-2978-rows-87-102-105.tar.gz.sha256`. It contains each task's result, logs, resource records, and overlay/model manifests; compiled VVP images are excluded. The archived job metadata confirms the pinned firmware commits, Icarus source revision, and compiler/runtime binary hashes.

After the archive and checksum were verified, the 304 MiB Slurm run directory was removed. The protected shared toolchain was left in place.
