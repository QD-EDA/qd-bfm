# Row 71 Python command setup gate

The pinned row 71 bench calls `python rej_bounded.py`, but DAN-DESKTOP only has `python3`. The runner now creates a `runtime/python` symlink to the host's `python3` and prepends that row's runtime directory to the simulation PATH. Other rows do not take this setup path.

Job 2682 used one CPU, 3 GiB, a 600-second per-row timeout, Python 3.14.4, and the pinned Icarus binary (`9b5fad2`, SHA256 `6cd9749c...`). Compilation and simulation exited 0; execution completed in 0.074 seconds, with a measured 23,736 KiB peak RSS. The runtime alias and generated files are recorded in `raw/python-alias.txt` and `raw/tasks/row-71/runtime/`.

The setup blocker is resolved, but the test is **FAIL**: it generated 10 input-vector lines and 10 expected-result lines, then reported seven `Not enough valid samples in the queue` errors and `* TESTCASE FAILED`. The intern's triage correctly identified the test failure but missed the Python/vector setup evidence; the saved alias target, Python version, generated files, and log confirm Python ran. The reason for the queue errors has not been reduced to a simulator defect, so no issue or overlay was created.

All captured run files passed verification against `raw/SHA256SUMS.remote.txt`. The compiled VVP was removed after its hash was verified. The completed Slurm run directory was deleted after capture, freeing 7,839,744 allocated bytes.
