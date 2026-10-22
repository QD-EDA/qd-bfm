# M18 ML-DSA row 77 updated-overlay gate — TIMEOUT

Job 3014 reran `ML_DSA_randomized_key_gen_test` on the pinned Adams Bridge revision with current-main Icarus and the updated open-AHB/ML-DSA overlay. Compilation passed, and the previous expected-analysis cast fatal is absent. VVP exited 124 at the configured 600-second cap (result elapsed 599.068 s). The last timestamped progress is 200 ns in `hdl_top.sv`: waiting for the reset event trigger. The log has no UVM error/fatal or testcase pass marker, so this is recorded as `TIMEOUT`, not pass.

Compiler source is `cae035642e056644274a01e98d4422ce286685b4`; compiler binary SHA-256 is `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`. The 45-file source snapshot and job script hashes were checked before submission. Raw archive SHA-256 `152536ef14645a84291d989e3ef8acfb70aea369a749ad5afd5e0490b5af92bd` matches the remote sidecar.
