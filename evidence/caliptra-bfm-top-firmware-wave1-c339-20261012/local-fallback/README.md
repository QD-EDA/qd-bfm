# Local fallback, 2026-10-12

DAN-DESKTOP accepts SSH but its Slurm controller and run filesystem are unhealthy. `squeue` cannot contact the controller, `/usr/bin/scancel` fails with `Input/output error`, `scontrol hold` returns `Unexpected message received`, and the run directory returns `Input/output error`. Job 591 could not be held or canceled.

## Local simulator and toolchain

The MacBook Air runs macOS 27.0 on arm64. The Caliptra RTL clone is clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; its Adams Bridge submodule is at `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. The local compiler is xPack RISC-V GCC arm64 15.2.0 and Python is 3.12.14.

Icarus source commit `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` was archived from the separate Icarus checkout and built under `/private/tmp/qd-bfm-icarus-c339-build-20261012-02`; the other agent's checkout and branch were not modified. The build used Homebrew Bison 3.8.2 (Apple's Bison 2.3 cannot parse this source), the macOS SDK libffi headers (`pkg-config` reports 3.4-rc1), Homebrew Z3 5.1.0, and `make -j3`. Build output and installed binary hashes are in `local-preflight.txt` and `icarus-build.log`. The installed binary reports `13.0 (devel) ()` because the archive has no Git metadata; the exact source SHA and binary hashes are recorded.

The Mac JTAG VPI module was compiled from the pinned Caliptra tree's `jtagdpi.c` and `tcp_server.c` with the local `iverilog-vpi`. Its build transcript is `jtagdpi-build.log`.

## Remote task snapshot

At the timestamp of `local-preflight.txt`, array tasks 0–3 were still running. Their open VVP log descriptors were copied to `remote-startup-snapshot/`; each log is 49,398 bytes and ends at `SoC: Polling Flow Status...` / the partial `Ready for Fuses deasserted af` line. A direct scan found no PASS, FAIL, TIMEOUT, FATAL, or completion marker. These are progress snapshots, not terminal evidence. The combined raw capture and per-test snapshots have SHA-256 entries in `remote-startup-snapshot/SHA256SUMS`.

## Local run

The first row-4 setup attempt exited before simulation with two header-copy errors under `MAKEFLAGS=-j3`. The upstream Makefile copies the same header set for each object, consistent with a parallel-copy race; the serial retry will verify this. Raw logs and its 38-second, 1.84 GiB resource record are in `attempt-01-setup-race/`; this is not a test verdict. A fresh run of `smoke_test_dma_aes_gcm_cmd_err` is now using `MAKEFLAGS=-j1`, its 7,431-second manifest timeout, and `~/codex-supervisor/localrun`. The immutable QD source archive and run output are under `/private/tmp/qd-bfm-localwave1-c339-20261012-01/`. Its exit code, resource report, runner log, and `result.json` will be copied here after it reaches a terminal state.

The shared per-row tracker is [`../results.tsv`](../results.tsv); infrastructure and setup states leave its terminal outcome blank.

Because Slurm cannot currently hold job 591, row 4 may also be dispatched remotely if the controller recovers. The four currently running remote rows (0–3) are excluded from the local fallback. Check Slurm before the next row and cancel this array as soon as its controller is usable.
