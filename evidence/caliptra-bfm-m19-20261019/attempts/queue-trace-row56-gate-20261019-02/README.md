# M19 queue-trace wrapper gate: row 56, corrected depth sampling

The first wrapper gate, job 3120, showed the observation trace compiled through the `PRE` `$display` but Icarus rejected `expected_results.size()` as a direct `$strobe` argument. This second gate captures queue depth into an integer after `#0` and passes that simple variable to `$strobe`.

The helper also now patches `run_logged` in the runner's `main.__globals__`; the previous assignment modified runpy's returned namespace copy and never intercepted compiler calls. Self-check: `../trace-runner-20261019-01/fix-selfcheck.txt` verifies both behavior changes. No DUT, firmware, expected samples, or pass criteria change.

- Row 56, current c339, 1 CPU / 2 GiB, 600-second cap.
- Source pin `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; Icarus pin `cae035642e056644274a01e98d4422ce286685b4`.

Result: pending.
