# Row 57 NumPy setup gate

Job 2678 ran row 57 (`sigencode_normal_test`) on DAN-DESKTOP with Python 3.14.4, NumPy 2.5.4, and the pinned Icarus binary (`9b5fad2`, SHA256 `6cd9749c...`). The NumPy wheel SHA256 is `d549420b...`; the exact wheel is retained in the sibling `gate-adams-row57-classifier/inputs/` directory.

The dependency setup succeeded and Icarus compiled and ran the test. The first runner snapshot reported `BLOCKED` because it did not yet recognize this testbench's explicit `Error: Output mismatch at index ...` failures. This run is superseded for classification by the fresh runner gate in `gate-adams-row57-classifier/`, which reports `FAIL` from the same mismatch output.

The captured simulator output, generated vectors, resources, commands, row result, pinned runner snapshot, and checksum-verification list are under `raw/`. The remote checksum list verified against the captured files. The compiled VVP is omitted after its hash was recorded in `raw/SHA256SUMS.remote.txt`. The completed Slurm run directory was deleted after capture.
