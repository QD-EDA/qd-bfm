# M8 setup-error attempts: arrays 1353 and 1354

Neither array produced a firmware test result. Array 1353 ran all 16 selected tasks, but the Verilator runner stopped during native-vector preflight before firmware build or simulation. Every `result.json` records `HARNESS_ERROR`; the first exception is a list of missing source inputs under `dv/caliptra_bfm/native_vectors/` (`stage_sha256_wntz.py`, `native_mlkem.c`, `random_test_ml_kem.py`, `stage_mldsa.py`, `check_native_mlkem.py`, and `check_native_mldsa.py`).

Array 1354 ran both c339 tasks, but the QD-BFM runner stopped before compile because `dv/caliptra_bfm/caliptra_bfm.f` was missing from the staged source root. Its wrapper status says `FAIL` because no `result.json` was produced; classify both as `SETUP-ERROR`, not firmware or simulator failures.

The initial retry staged only the runner file in a new source directory. The full QD-BFM source snapshot in run 06 was also incomplete for this path. The corrected submissions use the complete tracked source at commit `dd6d43d5416006a9e77f2458e8df2a5a754f86c7`, which contains the filelist and vector inputs. Their preflight checks verify those paths before submitting the arrays.

The 16 Verilator results, resource files, and task logs are preserved under `verilator/`; both c339 provenance, runner, status, resource, and Slurm logs are under `icarus/`. The generated output trees were omitted because no compiler or simulator ran. `FILE-SHA256SUMS.txt` covers the retained raw outputs and exact scripts/selections.
