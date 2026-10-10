# AHB checker X/Z matrix and full AHB regression — 2026-10-10

The 26-case AHB profile-checker regression and the full standalone AHB manager,
memory-target, monitor, and reset-abort regression passed from a clean QD source
archive under IEEE 2012, 2017, and 2023. All six runs exited 0. The checker
matrix injects X and Z separately on HREADY, HRESP, HSEL, HTRANS, HWRITE,
HSIZE, HADDR, and write-phase HWDATA, alongside the existing BUSY, alignment,
wait-stability, ERROR-response, and orphan-transfer controls.

The source archive is from QD commit
`10b86e64cc7b1a0af9cda410b27e4120e614ca55`. Tests used clean published Icarus
main `4b3f3424c440aca6af92153b6860a7253b925234`; its executable hashes match
the earlier published-main evidence. The AHB reset-abort test now waits one
simulation time step before checking reset-gated HSEL, avoiding a testbench
race on the combinational output. No AHB manager or checker logic changed in
this increment.

Runs were performed locally on Darwin 27.0.0 arm64 because SSH to the Slurm host
timed out. Every runner used the existing memory guard with a 400,000,000-byte
process-group cap and 6,000,000,000-byte available-memory reserve. The raw
outputs are in [`logs/`](logs/); commands and pins are in
[`commands.txt`](commands.txt) and [`source-revisions.txt`](source-revisions.txt).

This qualifies only these focused AHB BFM regressions on the pinned Icarus
build. It is not current-`c339b9f2`, Caliptra ECC, full-top, or UVMF evidence.
