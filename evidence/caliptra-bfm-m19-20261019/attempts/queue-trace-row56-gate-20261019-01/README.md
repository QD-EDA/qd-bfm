# M19 queue-trace wrapper gate: row 56

The first six-row current-c339 array ran the four queue-trace rows without trace displays: the helper patched the dictionary returned by `runpy`, while the runner's `main()` resolves `run_logged` from its separate function globals. This one-row gate validates the corrected hook before rerunning the queue-trace set.

- Row: 56 (`rej_rand_test`), pinned Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, Icarus `cae035642e056644274a01e98d4422ce286685b4`.
- 1 CPU, 2 GiB, 600-second per-row cap, fresh run root.
- The helper writes only testbench observation displays into the runner's staged output copy; it does not change RTL, firmware, input vectors, expected values, or pass criteria.
- Helper self-check: `../trace-runner-20261019-01/fix-selfcheck.txt` verifies the actual `runpy` call path writes the queue trace and manifest.

Result: pending.

archive_sha256=d8e6cbf863ac8ee90dcb1419f5edca195f18e00b54ac399ebf5c2271e26aeb9a
