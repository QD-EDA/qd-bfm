# Caliptra BFM max-burst and published-main smoke — 2026-10-09

This checkpoint records the generic AXI subordinate, Caliptra AXI complex BFM,
and bounded open-top firmware smoke from Slurm jobs 52 and 54.

## Source revisions

| Component | Revision |
| --- | --- |
| QD-EDA/qd-bfm | `c321ff737e6875d8a312c8f6103c5e887f3bcb8f` |
| Icarus `main` | `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` |
| Icarus-UVM | `78c06547a2a0a29b3dc9dcafae62b75b2ff61544` |
| Caliptra RTL | `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` |
| Adams Bridge | `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` |

The Icarus revision was a clean checkout whose `origin/main` contained the
build commit. A live `git ls-remote` check on 2026-10-09 returned the same
`main` SHA. It is a descendant of `0d8815febc260928e62d5c2ce82b14afd2e38dc3`,
the earlier same-day revision recorded in the preceding plan entry.

## Results

| Run | Result | Maximum resident set |
| --- | --- | ---: |
| Generic AXI memory subordinate | Pass; full 256-beat generic INCR read/write, per-beat data/USER/response checks, and prior boundary/error/reset cases | 19,492 KiB |
| Caliptra AXI complex BFM | Pass; randomized stalls, FIFO/SRAM, errors/recovery, segmented readback, and 256-beat burst | 17,280 KiB |
| Open-top firmware | Pass; one bounded AES/DMA case, normal firmware finish | 1,859,456 KiB |

The top run's guard reported a 1.80 GiB maximum process-group footprint and
22.16 GiB minimum available memory. Each job requested 2 CPUs and 6 GiB.

The firmware result is diagnostic integration evidence, not stock-firmware
qualification: it ran only `smoke_test_dma_aes_gcm_short_1_dword`, with
`--limit-aes-cases 1 --start-aes-case 6 --fast-trng --trace-axi`, fast boot
data preload, and PQ-vector generation skipped. `Axi4PC.sv` was excluded by
the selected profile. The captured `result.json` records one pass marker, zero
fail markers, zero bad diagnostics, and simulator exit 0.

## Captured artifacts

- `maxburst/`: source pins, runner outputs, and per-command `/usr/bin/time`
  resource records for the subordinate and complex BFM runs.
- `open-top/`: source pins, runner/resource output, compile log, simulation
  log, and full `result.json` with source and tool provenance.

These runs do not establish full-suite or stock-firmware qualification.
