# AXI interface force/release reducers

These small experiments isolate continuous assignments, interface modports, nested AXI-like interfaces, and the Caliptra delay-injection macro. All explored forms compiled with c339 and simulated successfully; the latest `-g2017 -gassertions` confirmation is in `../iverilog-c339/assertions-results/`.

They do not reproduce the 46 full-top mixed-driver diagnostics from `slurm-vip-adapter/`. The issue remains unresolved at the full-source/interface elaboration level, so no Icarus defect is claimed for these diagnostics.
