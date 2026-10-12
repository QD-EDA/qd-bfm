# AXI interface force/release reducers

These small experiments isolate continuous assignments, interface modports, nested AXI-like interfaces, and the Caliptra delay-injection macro. The delay-macro-only reducer passes with c339 and the full-top `-g2017 -gassertions` flags.

The full-top mixed-driver errors come from the separate `axi_if.rst_mgr()` task assignments conflicting with the parent continuous assignments; the source-level cause and a failing reducer are documented in `../mixed-driver-interface-task/README.md`. The testbench code is nonstandard under IEEE 1800-2023 §6.5, so no Icarus issue is claimed for these errors.
