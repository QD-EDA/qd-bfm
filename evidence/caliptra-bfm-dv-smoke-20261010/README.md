# Full-top firmware case slice — 2026-10-10

Slurm array 280 runs the three top-level firmware cases supported by the
current QD-BFM runner, one at a time. Each task has a fresh output directory,
1 CPU, 3 GiB memory, a two-hour Slurm limit, and a 7,000-second TERM/KILL
timeout. The memory request uses a prior full-top peak of 1,860,208 KiB.

| Task | Firmware case | Scope |
| ---: | --- | --- |
| 0 | `smoke_test_dma` | fast TRNG and boot-data preload |
| 1 | `smoke_test_dma_aes_gcm_short_1_dword` | first AES/DMA case only |
| 2 | `rand_test_dma` | first generated transfer only |

Tasks 1 and 2 are narrowed diagnostics. None use AXI tracing or reset
injection. Results are not promoted until each result JSON, terminal marker,
runner exit, and source/tool hashes are reconciled. The source snapshot is QD
commit `72d965adc2d7e9bfdbadaa3348add9781319bd1c`; Icarus is clean published
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; Caliptra and Adams are pinned to
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.

See [`three-cases.sbatch`](three-cases.sbatch) and [`submission.txt`](submission.txt).
Task logs, result JSON files, hashes, and resource logs will be added after
the array finishes.
