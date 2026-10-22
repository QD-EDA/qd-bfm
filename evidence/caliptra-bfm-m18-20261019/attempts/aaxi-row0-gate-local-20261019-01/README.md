# M18 row 0 gate on refreshed Icarus main

Ran `caliptra_top_rand_test` at Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, using current `iverilog-uvm` main source `cae035642e056644274a01e98d4422ce286685b4` and the open AHB/AAXI plus `avery_defines.svh` overlays. The Mac binary SHA-256 is `3039f3a706ecad191020170096f782c7b5b7a5776e72aa978ac04094daeae7e2`; `vvp` SHA-256 is `81d85816e4ced18dfcfed5f6658ba3a08e4662ff827879e62c617da7a25b9ef5`.

Result: `BLOCKED`, compile exit 198, 2.574 s compile, 197,541,888-byte peak RSS. The first diagnostic is the pinned RTL's unsupported fixed-array wildcard-bin declaration at `soc_ifc_reg_covergroups.svh:2055`; later syntax errors follow. Simulation did not start. This confirms the prior row 0 blocker on the refreshed source SHA; no coverage or RTL was rewritten.

Run host: `MacBook-Air.local`, macOS 27.0 arm64, Python 3.14.7. The per-test timeout was 600 s; the outer `localrun` cap was 1200 s and the wrapper exited 0 after preserving its result. `raw/job-local.tar.gz` and source/run metadata have SHA-256 sidecars. Ask-intern's triage was verified against `output/result.json` and `output/compile.log`.
