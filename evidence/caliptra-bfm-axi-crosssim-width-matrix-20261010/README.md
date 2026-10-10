# AXI width and ID cross-simulator matrix — 2026-10-10

The same existing manager/checker/SRAM-subordinate/channel-monitor/transaction-
monitor parameter test passed all 18 width/ID configurations under clean,
published Icarus and Verilator 5.050:

- Icarus `main` `4b3f3424c440aca6af92153b6860a7253b925234`: 18/18 pass.
- Verilator 5.050: 18/18 pass.

The matrix crosses 32/64/128/256/512/1024-bit data with 1/4/8-bit IDs. Each
case checks unaligned INCR and four-beat WRAP reads and writes, byte lanes,
USER, response IDs, checker handshakes, and completed transaction records.
The BFM limits the subordinate ID-width sample to 8 bits.

## Response-ready correction

The first Verilator 5.050 run compiled but failed at 32-bit data/1-bit ID. A
focused trace showed the manager accepted the final beat and then dropped
`RREADY` in the same active edge because its combinational READY logic excluded
the now-completed slot. The subordinate therefore did not consume that beat
and left `RVALID`/`RLAST` stale for the next read. The manager now keeps READY
asserted while the task still owns that slot; the task releases it at negedge
after the handshake. The same hold is applied to `BREADY` for write responses.
The post-fix matrix passes in both simulators, and Icarus read/write outstanding
matrices pass all 54 width/ID/depth configurations each.

Verilator emits existing width and incomplete-case warnings and is invoked with
`-Wno-fatal`; this is two-state runtime parity, not four-state qualification.
No simulator source was changed. Icarus is the clean published build listed
below; Verilator is the local 5.050 install.

## Reproduction

Run from the QD-BFM repository root:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
  dv/caliptra_bfm/axi/tests/run_parameter_matrix.sh

VERILATOR_BIN=/opt/homebrew/bin/verilator \
  dv/caliptra_bfm/axi/tests/run_parameter_matrix_verilator.sh
```

Both runners use the repository memory guard and run the configurations
serially. The Verilator runner removes each temporary build directory after its
case.

## Provenance

QD source is commit `da22b47cd01f3195e245e9700f28091fdf456491`. At run time the
worktree contained unrelated local changes and untracked artifacts; they were
not inputs to these runners and were left untouched. The Icarus source is the
newest locally available published `origin/main` revision, clean commit
`4b3f3424c440aca6af92153b6860a7253b925234`. Verilator reports
`5.050 2026-07-01 rev vUNKNOWN-built20260701`.

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/axi4_caliptra_master.sv` | `bfbf58a05b00449fb5de805188c776a101673aa8b33f5bad3515cc4d663b176a` |
| `dv/caliptra_bfm/axi/axi4_caliptra_checker.sv` | `afb681d7c741e2cf69cc9aee1ba20c987d070bf5237717b34b8e802acb48957b` |
| `dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv` | `c1d8d1a25691ccdccdcf65747aa223a5d11777d0a06af3cccbaa7d5d153acb34` |
| `dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv` | `33ed58d9c3d4b2aac4493740704547169349a28a61b304e5281533f1879529ca` |
| `dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv` | `5b0e3b0ff501a943b65d462466d27496a9319d011632e4f6b9e394e185e22e04` |
| `dv/caliptra_bfm/axi/tests/run_parameter_matrix.sh` | `1f9e2d9480eb25a291feab62415085753e23a4c0be351c14894042b1cee36305` |
| `dv/caliptra_bfm/axi/tests/run_parameter_matrix_verilator.sh` | `b187f2915e1e03ee782306b72682ac3d187b3c8095828ec17d9a9fc0da8d9915` |
| `dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_parameter_matrix.sv` | `bc1820881d0a2a727833e2c5009f6f35a40f0f5feceee64e8502895b12c3f241` |
| Icarus `iverilog` | `00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385` |
| Icarus `vvp` | `f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a` |
| Verilator executable | `fb2cc573b1055cf096c90e1efc9966fe56bdb4b265c83590cf2a49f7a0defcdf` |
| Icarus 18-case pre-fix log | `43b48da87a544631813af121cd7b4a998c575eecdefc3b8a5edb8b834ca1edf9` |
| Icarus 18-case log | `f4f2812e39651a5f48d466af38991559568ade1f762715f5a19babe2513fd7ab` |
| Verilator 18-case log | `7466574920368367cfec22f8879fd57e7f934d57ab103e85ab0b0781e588f089` |

## Diagnostic artifacts

- [`iverilog-4b3f-matrix.log`](logs/iverilog-4b3f-matrix.log): Icarus passed this matrix before the READY correction; Verilator exposed the final-beat race.
- [`verilator-5.050-matrix.log`](logs/verilator-5.050-matrix.log): pre-fix stale-response failure.
- [`verilator-5.050-debug-32x1.log`](logs/verilator-5.050-debug-32x1.log): focused signal trace for the final-beat race.
- [`verilator-5.050-launcher-failure.log`](logs/verilator-5.050-launcher-failure.log): initial launcher recursion caused by exporting Verilator's reserved `VERILATOR_BIN`; the reusable runner now clears that variable before invoking Verilator.
- [`verilator-5.050-rready-fix-matrix.log`](logs/verilator-5.050-rready-fix-matrix.log): complete post-fix Verilator matrix.
- [`iverilog-4b3f-rready-fix-matrix.log`](logs/iverilog-4b3f-rready-fix-matrix.log): complete post-fix Icarus matrix.
