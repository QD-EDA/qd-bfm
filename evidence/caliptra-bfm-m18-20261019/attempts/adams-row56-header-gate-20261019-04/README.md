# M18 Adams Bridge row 56 authored-model gate — FAIL (job 3022)

The run-local `python` alias let the authored testbench invoke the existing `python3` model. It generated `input_vectors.txt` and `exp_results.txt`, and Icarus compiled and ran the test. The bench reported 10 `Not enough valid samples in the queue` errors and emitted `* TESTCASE FAILED`; the runner recorded `FAIL` after 0.093 seconds. No pass marker appeared. The run used the refreshed Icarus source `cae035642e056644274a01e98d4422ce286685b4` (binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`) on DAN-DESKTOP.

The overlay only supplies the missing run-local Python command and the previously recorded ML-DSA filelist/header adaptations. Reference model, input generation, expected results, and testbench pass criteria are unchanged.

Raw archive: `raw/job-3022.tar.gz`; its SHA-256 is `2b2659a5b6feba74dc78013ac3cc075cc23c300f7c58dfb1e9fe1b4e0e42c9d3`, verified against the remote sidecar. The archived `result.json` reports `status=FAIL`, `compile_exit=0`, `sim_exit=0`, and `sim_timed_out=false`.
