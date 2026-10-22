# M18 ML-DSA row 77 upgraded-Icarus gate — FAIL

Job 3011 ran `ML_DSA_randomized_key_gen_test` on Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` with current Icarus main `cae035642e056644274a01e98d4422ce286685b4` (`iverilog` SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`). The open-AHB filelist and existing ML-DSA overlay compiled successfully; simulation exited 0 after 29.562 s but failed at 425 ns with one UVM_FATAL in `mldsa_scoreboard.svh:243`: the expected-analysis transfer `$cast` failed. There is no testcase pass marker.

The raw job archive and its remote SHA-256 sidecar are in `raw/`; the archive hash was independently matched locally. The saved generated predictor and scoreboard show the QD-BFM transfer typedef in use. M16’s reduced #666 evidence documents the same Icarus parameterized-class cast failure. A corrected overlay gate is recorded separately.
