# AXI memory target 16-beat FIXED round trip — 2026-10-10

The existing memory-subordinate test now sends a 16-beat, full-width FIXED
write with distinct data on every beat. Since FIXED keeps the address constant,
the test checks that the final word is retained at the mapped address. It then
issues a 16-beat FIXED read and checks every data beat, `RRESP`, `RUSER`, and
the `ARUSER` returned with the transaction. The AXI `B` response and `BUSER`
are checked as well.

Slurm job 168 passed the complete `run_subordinate.sh` sequence: the expanded
memory-subordinate test, handshake-reset cases, and queued-traffic test. The
run used 1 CPU and requested 256 MiB; `/usr/bin/time` measured 17,928 KiB peak
RSS, 0.27 seconds wall time, and exit status 0.

| Input | Identity |
|---|---|
| QD branch base | `codex/caliptra-bfm-stack-20261006` at `b40e5f952638dd12d9ccf3dfc2db71304fb057b7` |
| Testbench source | SHA-256 `770fafce3f8a6d7a6285fb38caeffc85cae09373d9f694d202953b3980ee7963` |
| Icarus source | clean published `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` |
| Icarus version | 13.0 (devel) (`c339b9f2`) |
| Icarus source state | clean; `HEAD` equals local `origin/main` |
| Job | Slurm 168, `verilog`, 1 CPU, 256 MiB |

The source-state record, executable hashes, exact batch script, test output,
and resource measurements are stored beside this note. This is module-level
target evidence; it does not establish that Caliptra's generated DMA master or
full-top random-DMA firmware case completes.
