# AXI memory target 16-beat WRAP round trip — 2026-10-10

The memory-subordinate regression sends 16 distinct full-width write beats
starting at the final word of a 64-byte WRAP window. It checks that all 16
words land at their wrapped addresses, then reads the same burst and verifies
each data beat, `RRESP`, `RUSER`, and the transaction's `ARUSER`. The `B`
response and `BUSER` are checked as well. The test uses a memory window
separate from the following reset-retention assertion.

Slurm job 171 passed the expanded `run_subordinate.sh` sequence, including the
memory-target test, handshake-reset cases, and bounded multi-ID queue test. It
used 1 CPU and requested 256 MiB; `/usr/bin/time` measured 17,840 KiB peak RSS,
0.27 seconds wall time, and exit status 0.

| Input | Identity |
|---|---|
| QD branch base | `codex/caliptra-bfm-stack-20261006` at `04051d8de721cc3b2a61deb1021e2a8dd0dfd0cb` |
| Testbench source | SHA-256 `698cc05c840e4b5964e8f0b3a0888d97834988eb8605f8b7040fad22b7c190b2` |
| Icarus source | clean published `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` |
| Icarus version | 13.0 (devel) (`c339b9f2`) |
| Icarus source state | clean; `HEAD` equals local `origin/main` |
| Job | Slurm 171, `verilog`, 1 CPU, 256 MiB |

The exact batch script, raw output, source hash, simulator hashes, source-state
record, and resource measurements are stored beside this note. This proves
module-level memory-target coverage; it does not prove the generated Caliptra
DMA master or full-top random-DMA firmware path.
