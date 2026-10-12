# Caliptra top clock generator reproducer

This reducer is taken from `caliptra_top_tb.sv` in Caliptra source commit
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` (source SHA256
`c212c32da99e90cd3991da65e653998cac3e945d7479abfd640b9d82f47659f9`). The
source declares `bit core_clk` and uses `core_clk = #5ns ~core_clk;` in
`clk_gen`, without a module timescale or timeunit. The actual generator is
inside `` `ifndef VERILATOR``; this reducer omits that guard so both tools
process the same clock code.

Pinned Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, binary SHA256
`683c94313f596bba25aa4e6de37efb4e68bb5dadc37394a91a2a0e6078ac26cb`, version
13.0-devel) rejected the reducer with exit 1:

```text
error: always process does not have any delay.
: A runtime infinite loop will occur.
Elaboration failed
```

Verilator 5.032 (binary SHA256
`672a1ccf3468902f66387049f001b04f254bbcece7d5e816e3861715889bf252`) built
and ran the same source with exit 0, printing
`PASS: Caliptra clock generator completed four transitions` at 25 ns.

The batch used these commands (wrapped in 120-second compile and 30-second
runtime guards):

```sh
iverilog -g2017 -gassertions -s actual_caliptra_clock_generator \
  actual_caliptra_clock_generator.sv -o build/actual.vvp
verilator --binary --timing --build-jobs 1 \
  --top-module actual_caliptra_clock_generator --Mdir build/verilator \
  actual_caliptra_clock_generator.sv
build/verilator/Vactual_caliptra_clock_generator
```

The raw logs, exit codes, versions, host provenance, and hashes are retained
here. The Slurm batch requested 1 CPU, 2 GiB, and 10 minutes;
Slurm accounting is disabled and peak RSS was not recorded.

This confirms the c339 diagnostic on the actual Caliptra clock construct and
its acceptance by Verilator. It does **not** confirm the filed bit-versus-logic
distinction: job 747 showed both `bit` and initialized `logic` fail without a
timescale and pass with one. The current issue text records that correction.
