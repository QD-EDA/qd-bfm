# Intern log triage, checked

The intern received only the last 150,000 characters of the 231,245-byte compile log. Its reported “first error” was therefore not the first error in the full file. The full log begins at `kv_rst_configuration.svh:149` with Icarus rejecting a `$psprintf` call.

Verified findings:

- The full log contains 224 `error:` diagnostics and 574 `sorry:` diagnostics. The repeated nested-class-property limitation appears throughout the generated KeyVault environment.
- Calls such as `configuration.kv_rst_agent_config.wait_for_num_clocks(...)` are not a missing AHB/QD-BFM API: the pinned generated `kv_rst_configuration.svh` declares `wait_for_num_clocks`. The calls traverse nested class properties; Icarus also reports that nested class-property path as unsupported.
- The generated `kv_write_driver_bfm.sv` and `kv_read_driver_bfm.sv` assign response signals through `initiator_port` while those signals are declared inputs there. The compiler reports these as modport-direction violations; they are generated testbench source issues to inspect separately, not a QD-BFM gap.
- The `$psprintf` diagnostic is preserved without assigning it to source defect versus simulator defect; the compile log and exact pinned source are required for a reduced reproduction.

No repairs were made from this triage. The next candidate for the AHB drop-in gate is the generated SoC-IFC environment, which already has prior runtime evidence for its generated AHB mailbox path.

Follow-up: the `$psprintf` report was minimized independently in `diagnostics/icarus-psprintf-empty-arg/`. Pinned Icarus rejects the trailing-empty-argument form while Verilator 5.032 runs it; internal issue #670 is labeled `from-caliptra-dv`. This only classifies that one diagnostic; the other row-6 errors remain.
