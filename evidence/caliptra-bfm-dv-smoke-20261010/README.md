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

Array task 0 timed out after 7,000 seconds without a testcase result marker;
its log's partial final line did not identify the timeout phase. Task 1
compiled and entered simulation, then was cancelled without a result. Task 2
was cancelled before it started. Their retained evidence is in
[`task-0-smoke-timeout/`](task-0-smoke-timeout/) and
[`task-1-stopped/`](task-1-stopped/).

The isolated trace follow-up was Slurm job 289. It timed out after 7,000
seconds with no testcase marker or result JSON. The final trace reached cycle
58,500 in the firmware loop that generates 512 random words for the AHB FIFO,
before its large DMA transfer. It confirms the fuse-ready poll cleared after
one read and the ROM began running. Its logs, hashes, and resource report are
in [`trace-smoke-timeout/`](trace-smoke-timeout/); the pinned-source script is
[`trace-smoke.sbatch`](trace-smoke.sbatch).

The first AES/DMA vector diagnostic was rerun independently as job 301 without
the trace plugin. It exited 0 with one pass marker and no fail markers, but
only AES case 0 ran; the full stock-firmware test row remains unverified. See
[`aes-first/`](aes-first/) for the run manifest and artifacts.

The two smoke timeout log copies redact three firmware-printed test-key values
each. Their original SHA-256 digests and redacted line numbers are recorded in
[`redactions.txt`](redactions.txt); the remote run artifacts were not changed.
