# Full-top `rand_test_dma` first iteration — 2026-10-10

## Result

One `rand_test_dma` iteration passed through the actual pinned
`caliptra_top_tb` with `CALIPTRA_BFM_CHECKER` enabled. Firmware build, top
elaboration, and simulation exited 0. The result recorded one testcase pass,
zero testcase failures, zero bad diagnostics, no JTAG bind/server errors, and
normal `$finish` at `minstret=7898`, `mcycle=27467`.

This is a narrowed diagnostic: one iteration, fast TRNG, diagnostic fast
boot-data preload of 13,668 bytes, quiet firmware, and no AXI trace. It does
not establish stock-firmware, full-suite, generated-UVMF, traced-DMA, or
qualification status.

## Provenance and resources

The run used QD-BFM base `b40e5f952638dd12d9ccf3dfc2db71304fb057b7`, runner
SHA-256 `ea57294b045c7cae66a8aa6b93692a4c1ae8b343160624e0f137b71d855c6cb0`,
and the current full-top BFM wrapper hash in `result.json`. The current QD
branch at review time was `c15e593`; its only Caliptra BFM source differences
from the run base were the standalone memory-target test and its README, so
the full-top runner and AXI target wrapper were unchanged.

The simulator was clean published Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, with bundled UVM
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. Caliptra RTL was
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge was
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. The structured result records
the clean Icarus source checkout, tool binaries and hashes, firmware and
simulation-image hashes, generated overlay hashes, exact commands, and pass
markers.

Slurm job 164 requested 1 CPU and 4 GiB, ran for 59:25.73, and completed with
exit code 0. `/usr/bin/time` measured 1,860,208 KiB maximum RSS; the process
group guard measured a 1.80 GiB peak and 20.90 GiB minimum available memory.

## Artifacts

- [`result.json`](output/rand-dma-one/result.json): commands, image/source
  fingerprints, simulator provenance, diagnostic modes, and result markers.
- [`sim.log`](output/rand-dma-one/rand_test_dma/sim.log): full firmware and
  simulation output containing `* TESTCASE PASSED` and normal `$finish`.
- [`compile.log`](output/rand-dma-one/compile.log) and
  [`open_caliptra_top.vf`](output/rand-dma-one/open_caliptra_top.vf): compile
  diagnostics and ordered top-level file list.
- The adjacent generated `*_icarus.sv` files are the exact compatibility
  overlays used by this run; their hashes are recorded in `result.json`.
- [`job.sbatch`](job.sbatch), [`source-revisions.txt`](source-revisions.txt),
  [`jtagdpi.sha256`](jtagdpi.sha256), and the `logs/` directory preserve the
  submitted command, pinned source identities, Slurm output, and resource
  measurements.

The 368 MiB compiled VVP image is not copied into the repository; its SHA-256
is retained in [`simulation-image-sha256.txt`](simulation-image-sha256.txt).
