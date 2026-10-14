# AXI target burst monitor accounting — 2026-10-10

The 16-beat FIXED and WRAP memory-target round trips now run before the
monitor snapshot, so the regression's counter assertions include both cases.
They assert 18 AW/B transactions, 15 AR/R transactions, and 315 W beats,
with 3 FIXED and 2 WRAP address transactions on each direction, 15 OKAY B
responses, 301 OKAY R beats, 309 full-strobe W beats, and 18 WLASTs. The test
also checks all 16 wrapped memory locations, then verifies every returned
data, response, and USER field.

Slurm job 172 passed the complete `run_subordinate.sh` sequence: the expanded
memory-subordinate test, handshake-reset cases, and bounded multi-ID queue
test. It used 1 CPU and requested 256 MiB; `/usr/bin/time` measured 17,456 KiB
peak RSS, 0.27 seconds wall time, and exit status 0.

| Input | Identity |
|---|---|
| QD branch base | `codex/caliptra-bfm-stack-20261006` at `3be6c5ad7ef76d27cae72d859b6c199bef7abc18` |
| Testbench source | SHA-256 `76f9323e686e8570474d3f752bb2acb4d6d3f9c91a16101133caa2c55bbe5200` |
| Icarus source | clean published `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` |
| Icarus version | 13.0 (devel) (`c339b9f2`) |
| Icarus source state | clean; `HEAD` equals local `origin/main` |
| Job | Slurm 172, `verilog`, 1 CPU, 256 MiB |

The exact batch script, raw output, source hash, simulator hashes, source-state
record, and resource measurements are stored here. This proves memory-target
monitor accounting; it does not prove the generated Caliptra DMA master or
full-top random-DMA firmware path.
