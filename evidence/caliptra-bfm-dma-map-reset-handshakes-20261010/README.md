# Generated DMA-map reset after AXI handshakes — 2026-10-10

The integrated AXI DMA-map regression passes resets after accepted AR, R, AW,
W, and B handshakes while the generated FIFO recovery-block sequence is active.
For each reset it checks that responses, route state, and FIFO contents are
cleared, that the selected generated block is re-armed, and that a FIFO
write/read succeeds after reset release.

Slurm job 162 ran `sh dv/caliptra_bfm/axi/tests/run_dma_subordinate.sh` and
passed. It used QD-BFM base commit
`2e5363810c25790c3902048d6dea6139520658fd`, with the testbench below staged
from the working tree. The staged testbench SHA-256 was
`f20ef255eecc8466c586d7ffa74bc8f5c97f867fe24e02abb5d29f9fefa2eec3`.

The simulator was clean, published Icarus `main` at
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. Its `iverilog` and `vvp` SHA-256
values were `737049ca0342dd7e258d0d021f4b3b6aa750dcb6d79a6cd9871988954da898b2`
and `5f0bc4d0b98eb7438c8d0446d62fcf59c68a24e3f9d1041ac69e5d439de1f24a`.
The simulator source checkout was clean and contained the commit in
`origin/main`.

The job requested 1 CPU and 256 MiB. `/usr/bin/time` measured 17,592 KiB
maximum resident set and 0.28 seconds elapsed; the Slurm job completed in one
second. See [run output](run.log) and [resource log](resource.log).

This is module-level DMA-map coverage. It does not verify reset behavior in
Caliptra's generated DMA master, the full top, or UVMF.
