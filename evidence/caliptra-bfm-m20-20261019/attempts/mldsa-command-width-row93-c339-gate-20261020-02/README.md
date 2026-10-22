# Row 93 command-width overlay gate — local c339 build

This is the fresh row 93 gate after the predictor overlay change. The staged Caliptra/Adams Bridge inputs are source-pinned as listed in the M20 matrix; the gate runs Icarus built locally from the exact c339 commit `cae035642e056644274a01e98d4422ce286685b4`, with the matching local `vvp`. Its binary hash and host/tool versions are recorded in `../../toolchain-c339-local-20261020/raw/`.

Only the per-run M16 compatibility overlay sizes the three native-reference command subtractions to `op_code-3'd1`. RTL, firmware, testcase sequence, expected values, assertions, and pass criteria are unchanged. Resources: one local simulation, one thread, runner timeout 1,800 seconds; `localrun` wrapper cap 2,100 seconds.
