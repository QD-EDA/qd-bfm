# Job 1780: runner environment failure

Job 1780 built the logging-only Verilator model successfully, then exited before firmware build or simulation. The captured `result.json` reports `HARNESS_ERROR` with `KeyError: 'CALIPTRA_GCC_PREFIX'` in `run-verilator-top-case.py`; no `sim.log` was created and this is not a test result.

The diagnostic batch script exported the compiler directory in `PATH` but omitted the `CALIPTRA_GCC_PREFIX` and `CALIPTRA_MBEDTLS_ROOT` values used by the working M10b array script. The script now exports the same toolchain environment; fresh retry job 1781 uses a separate run directory. The submitted 1780 script is preserved here with SHA-256 `0bbaca3b24de71ba0b581dfdbdfee92a56bd8f7fa8c023f65d8b7d08e646cec9`.

Build, wrapper, result, and resource files were copied from DAN-DESKTOP and verified against its `SHA256SUMS`; the submitted batch script and empty Slurm output log were also checksum-verified. The model built successfully with SHA-256 `adc9b3eabbb59fef890cfbd6d112487dceba2c3c1135cebd73540f0d6d132aa9`; it was not run. After the evidence was copied and verified, the remote run directory was deleted, freeing 729,247,711 bytes.
