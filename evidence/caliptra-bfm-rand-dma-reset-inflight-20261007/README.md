# Caliptra full-top DMA reset diagnostic — 2026-10-07

**Status: diagnostic only; not qualified.** The run stopped after the first post-reset AXI response, before the firmware testcase completed.

## Finding

The earlier 512-cycle setting started its timer at the firmware `0xEE` mailbox request (cycle 2,382) and asserted reset at cycle 2,896. The first AXI write in that trace did not arrive until cycle 5,785, so that setting reset before DMA traffic began ([saved trace](../caliptra-bfm-rand-dma-reset-actual-top-20261007/sim-trace-sanitized.log)).

This diagnostic used a 3,870-cycle wait. The trace showed one write still outstanding at reset: the last pre-edge checkpoint had AW=8, W=127, B=7; reset asserted at cycle 6,254 and deasserted at 6,264. After reboot, a fresh AW was accepted at cycle 9,143 and its B response arrived at 9,177. No old B response appeared between reset release and the fresh AW. This confirms the in-flight reset trigger and the first post-reset response path.

The monitor deliberately terminated the simulator after that B response. There is no testcase pass marker and no claim that the full firmware run completes after reset.

## Run and provenance

- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- QD BFM source revision used: `b217116459c1a4dd687145744a56b6d2ae278a9e`; no source files were changed for this diagnostic.
- Icarus BFM WORK branch/revision: `claude/caliptra-bfm-plan-cxc8gn` / `ac4532fab037e91df2f903e67fb40f59baedccca`; worktree dirty. Icarus 13.0 binary hashes are recorded in [`result.json`](result.json). This is not a clean published revision, so this run remains diagnostic.
- The runner's hash-checked overlay helper generated a 3,870-cycle services overlay. The top image and reused fast-boot firmware images are identified by SHA-256 in [`result.json`](result.json).
- Full-top checker, 50-cycle fast TRNG, one generated DMA iteration, and unrelated PQ vector generation skipped. The firmware image and DCCM image were reused from the prior diagnostic build; they were not rebuilt in this pass.
- Memory guard: process-group cap 3,999,999,999 bytes, available-memory reserve 6,000,000,000 bytes, 2,400-second timeout. Observed minimum available memory 9.10 GiB and maximum process-group RSS 0.94 GiB; the guard exited normally when the monitor stopped the simulator.
- Raw simulator output SHA-256: `cdacc5388d810be4d5e890766ff66c7712278db102747962daaada8b6971ae37`. Only the reset and AXI count lines are preserved in [`sim-trace-sanitized.log`](sim-trace-sanitized.log); firmware output was not copied into the repository.

Sanitized trace SHA-256: `2465c9c049fddc89238401747c3520041bf12fada670bed6a32cd11255c83513`. The structured counts, stop reason, simulator provenance, and artifact hashes are in [`result.json`](result.json).
