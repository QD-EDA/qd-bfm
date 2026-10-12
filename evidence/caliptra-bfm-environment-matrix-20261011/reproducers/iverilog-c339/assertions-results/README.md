# Force/release reducer with the full compile flags

Job 545 compiled the existing `force_release_axi_macro.sv` reducer on DAN-DESKTOP with Icarus c339 and the same `-g2017 -gassertions` flags as the Caliptra top. Compile and simulation exited 0 and the reducer printed PASS. This weakens the hypothesis that interface force/release plus those flags alone explains the full-top diagnostics; it does not resolve the source-specific mixed-driver errors.

Job 544 is retained under `run-01-wrapper-failure/`: its wrapper omitted exported variables and exited before creating a compile log. It is a harness failure, not compiler evidence. Job 545 used a fresh run directory and the corrected wrapper. Full tool, host, compile, simulation, and resource records are in `force_release_axi_macro/`.
