# AXI width and ID parameter matrix — 2026-10-09

The guarded `run_parameter_matrix.sh` passed all nine configurations from a
clean QD-BFM checkout at `57aff65558d0c19dfa9a6aad5d4123f14659d1bd`, using
clean published Icarus `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
The Icarus source checkout was clean and contained that commit in `origin/main`;
a live remote check returned the same `main` SHA. Source-file and simulator
hashes, the tool version, Slurm script, raw output, and resource measurement
are retained here.

The 3×3 matrix crosses `DATA_WIDTH` 32, 64, and 128 with `ID_WIDTH` 1, 4, and
8. Each configuration exercises a 48-bit address interface, an unaligned
INCR write/read with byte-lane checking, a four-beat WRAP write/read, USER
propagation, and response-ID capture through the manager, checker, and SRAM
subordinate.

Slurm job 77 requested 1 GiB and 1 CPU. The nine compile/simulation cases ran
serially in 0.28 seconds with 17,684 KiB maximum RSS; exit status was zero.

This is representative parameter coverage, not every supported width, ID,
outstanding-depth, simulator, or Caliptra/UVMF configuration.

## Expanded data-width follow-up — 2026-10-10

The guarded matrix now exercises 18 configurations: `DATA_WIDTH` 32, 64, 128,
256, 512, and 1024 crossed with `ID_WIDTH` 1, 4, and 8. All 18 pass through
the manager, checker, SRAM subordinate, channel monitor, and completed-
transaction monitor. Each case retains unaligned INCR and four-beat WRAP
read/write, lane checking, USER propagation, and response-ID checks. The
subordinate enforces `ID_WIDTH <= 8`; this run does not expand that supported
bound. The prior 2026-10-09 Slurm result and its hashes above are unchanged.

Reproduce from the QD-BFM root:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
  dv/caliptra_bfm/axi/tests/run_parameter_matrix.sh
```

The run exited zero with all 18 PASS lines in
[`parameter-matrix-1024-published-20261010.log`](logs/parameter-matrix-1024-published-20261010.log).
It used clean published Icarus source revision
`127b887dfdc09283ab0187a2e618421dee3d5dcc`; it does not claim the later cached
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` was installed or tested. The QD
source checkout was based on `9bbe401b0721da62ad13af9871bc15691c686296`, with
the two test inputs changed and fingerprinted below.

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/tests/run_parameter_matrix.sh` | `1f9e2d9480eb25a291feab62415085753e23a4c0be351c14894042b1cee36305` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_parameter_matrix.sv` | `bc1820881d0a2a727833e2c5009f6f35a40f0f5feceee64e8502895b12c3f241` |
| `dv/caliptra_bfm/axi/axi4_caliptra_checker.sv` | `afb681d7c741e2cf69cc9aee1ba20c987d070bf5237717b34b8e802acb48957b` |
| `dv/caliptra_bfm/axi/axi4_caliptra_master.sv` | `1b21a6fd7731aea0c4c79089ee7b8fe37f3b1cb9d9d94d7e9843f6ad47d72e64` |
| `dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv` | `c1d8d1a25691ccdccdcf65747aa223a5d11777d0a06af3cccbaa7d5d153acb34` |
| `dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv` | `33ed58d9c3d4b2aac4493740704547169349a28a61b304e5281533f1879529ca` |
| `dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv` | `5b0e3b0ff501a943b65d462466d27496a9319d011632e4f6b9e394e185e22e04` |
| Icarus `iverilog` | `a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602` |
| Icarus `vvp` | `29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca` |
| Runner output log | `663af04ebd1a01db09ed053cff00cbd1d564e6150d297893b1ddb58e25b60d88` |

This expands only the data-width-by-ID sample matrix. Outstanding-depth
cross-products, independent simulator parity, and full Caliptra/UVMF
qualification remain open.
