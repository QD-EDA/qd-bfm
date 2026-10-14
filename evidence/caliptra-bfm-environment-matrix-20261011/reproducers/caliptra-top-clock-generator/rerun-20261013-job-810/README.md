# Independent reproducer rerun

Slurm job 810 on DAN-DESKTOP reran the source-derived clock reducer with 1 CPU,
2 GiB, and a 10-minute job limit. The test script applies 120-second compile
timeouts and a 30-second simulation timeout.

- Caliptra source: commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; the reducer
  keeps `bit core_clk` and `core_clk = #5ns ~core_clk;` from
  `src/integration/tb/caliptra_top_tb.sv` and adds a finite completion check.
- Pinned Icarus c339: source commit
  `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, binary SHA256
  `683c94313f596bba25aa4e6de37efb4e68bb5dadc37394a91a2a0e6078ac26cb`.
  Compile exit 1 with `always process does not have any delay`.
- Verilator 5.032, binary SHA256
  `672a1ccf3468902f66387049f001b04f254bbcece7d5e816e3861715889bf252`.
  Build and run both exited 0; the four-transition PASS marker appeared at 25 ns.

The original `caliptra_top_ss_mode_tb` row remains compile-failing and also has
independent mixed-driver diagnostics. This rerun confirms the clock-generator
diagnostic on the actual source construct; it does not establish the originally
reported bit-versus-logic difference.
