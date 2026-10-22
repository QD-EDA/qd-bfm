# M18 Adams Bridge row 56 header/package gate — BLOCKED

Job 3020 compiled and reached simulation with the ML-DSA config, PISO, and sampler-package compatibility overlays. The authored testbench then invoked `python mldsa_rej_sampler.py`; the archived sim log confirms `sh: 1: python: not found`. This host exposes `python3` only, so `input_vectors.txt` and `exp_results.txt` were not generated and the testbench reported file-read errors before its max-cycle finish. No testcase pass marker was emitted. The next gate adds the existing runner `prepare_python_alias` setup for this authored component.

Raw archive SHA-256 `865ab82694b3e376f52eca002c8f116224fec9177bf4b398d4c501717fea70f9` matches its remote sidecar.
