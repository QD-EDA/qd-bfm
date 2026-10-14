# Full-top random-DMA rerun on current QD BFM — 2026-10-10

## Result

Slurm job 184 passed one `rand_test_dma` iteration through the pinned
`caliptra_top_tb` using the QD BFM source from commit
`5945efeae78580cc8a5bd7a4050ee4dfec39d7be`. Compile, firmware build, and
simulation all exited 0. The run recorded one testcase pass, zero testcase
failures, zero bad diagnostics, zero JTAG bind denials, and zero JTAG server
errors. The DUT finished at `minstret=7898`, `mcycle=27467`. The native
Caliptra AXI BFM checker was enabled.

This is one narrowed diagnostic iteration, not stock-firmware, full-suite,
UVMF, or qualification evidence. It used fast TRNG, the diagnostic fast
boot-data preload of 13,668 bytes, quiet firmware output, and no AXI trace.

## Provenance

The simulator was clean published Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, contained in `origin/main`, with
UVM `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. Caliptra RTL was
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge was
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. The structured result records the
commands, clean source checkout, binary and generated overlay hashes, firmware
images, diagnostic modes, and finish counters. `source-files.sha256` and
`source-archive.sha256` identify the staged committed QD input snapshot.

Two earlier submissions, jobs 182 and 183, stopped before simulation because
the staged source subset omitted the shell memory-guard wrapper and then the
DMA overlay generator. They were source-packaging errors, not missing machine
dependencies; the final job included both files. Their logs are retained below.

## Runtime and resources

Job 184 requested 1 CPU and 4 GiB with a two-hour limit. `/usr/bin/time`
measured 1:01:02 and 1,860,408 KiB maximum RSS. The process-group guard measured a 1.80 GiB peak and 15.97 GiB minimum
system-available memory, with a 6 GB reserve. The run's job script uses the
strict 4,000,000,000-byte process-group cap.

## Artifacts

- [`result.json`](output/rand-dma-one/result.json): exact run provenance and
  result markers.
- [`sim.log`](output/rand-dma-one/sim.log), [`compile.log`](output/rand-dma-one/compile.log),
  and [`open_caliptra_top.vf`](output/rand-dma-one/open_caliptra_top.vf):
  simulator output and ordered top-level source list.
- The exact generated Icarus overlays are retained in
  [`generated-overlays.tar.gz`](output/rand-dma-one/generated-overlays.tar.gz);
  their hashes are in `result.json`.
- [`job.sbatch`](job.sbatch), [`source-revisions.txt`](source-revisions.txt),
  [`source-files.sha256`](source-files.sha256), [`tool-binaries.sha256`](tool-binaries.sha256),
  [`time.log`](logs/time.log), and [`slurm-184.out`](logs/slurm-184.out) record
  the command, source/build identities, and resource measurements.
- The 351 MiB compiled VVP image is not copied; its SHA-256 is in
  [`simulation-image-sha256.txt`](simulation-image-sha256.txt).
- `slurm-182-source-stage-failure.out` and `slurm-183-source-stage-failure.out`
  document the pre-simulation staging errors.
