# Local fallback, 2026-10-12

DAN-DESKTOP accepts SSH but its Slurm controller and run filesystem are unhealthy. `squeue` cannot contact the controller, `/usr/bin/scancel` fails with `Input/output error`, `scontrol hold` returns `Unexpected message received`, and the run directory returns `Input/output error`. Job 591 could not be held or canceled.

## Local simulator and toolchain

The MacBook Air runs macOS 27.0 on arm64. The Caliptra RTL clone is clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; its Adams Bridge submodule is at `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. The local compiler is xPack RISC-V GCC arm64 15.2.0 and Python is 3.12.14.

Icarus source commit `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` was archived from the separate Icarus checkout and built under `/private/tmp/qd-bfm-icarus-c339-build-20261012-02`; the other agent's checkout and branch were not modified. The build used Homebrew Bison 3.8.2 (Apple's Bison 2.3 cannot parse this source), the macOS SDK libffi headers (`pkg-config` reports 3.4-rc1), Homebrew Z3 5.1.0, and `make -j3`. Build output and installed binary hashes are in `local-preflight.txt` and `icarus-build.log`. The installed binary reports `13.0 (devel) ()` because the archive has no Git metadata; the exact source SHA and binary hashes are recorded.

The Mac JTAG VPI module was compiled from the pinned Caliptra tree's `jtagdpi.c` and `tcp_server.c` with the local `iverilog-vpi`. Its build transcript is `jtagdpi-build.log`.

## Remote task snapshot

At the 03:19 MDT check, array tasks 0–3 were still live (`/proc` state `R`), each using about 1 GiB RSS. Their open VVP log files remained 49,398 bytes with the same modification times; no terminal marker appeared. At 02:59 the captured logs ended during the `Ready for Fuses deasserted after polling ...` message. The source shows this message follows the loop waiting for `READY_FOR_FUSES_LOW` to clear, but the snapshot has no later BootGo/ROM progress. See [`remote-startup-snapshot/status-02-59.txt`](remote-startup-snapshot/status-02-59.txt), [`remote-startup-snapshot/status-03-08.txt`](remote-startup-snapshot/status-03-08.txt), and [`remote-startup-snapshot/status-03-19.txt`](remote-startup-snapshot/status-03-19.txt); the captured logs and earlier scan have SHA-256 entries in `remote-startup-snapshot/SHA256SUMS`. These are progress snapshots, not terminal evidence.

## Local run

The first row-4 setup attempt exited before simulation with two header-copy errors under `MAKEFLAGS=-j3`. The upstream Makefile copies the same header set for each object, consistent with a parallel-copy race; the serial retry will verify this. Raw logs and its 38-second, 1.84 GiB resource record are in `attempt-01-setup-race/`; this is not a test verdict. A fresh run of `smoke_test_dma_aes_gcm_cmd_err` started at 02:45:59 MDT with `MAKEFLAGS=-j1`, its 7,431-second manifest timeout, and `~/codex-supervisor/localrun`. At 03:19 its VVP process remained active at about 90% CPU and 0.59 GiB RSS; `sim.log` was unchanged from 02:46:58, with no `result.json` or terminal marker. The latest status is in [`attempt-02-serial/observations-03-19.txt`](attempt-02-serial/observations-03-19.txt); the immutable QD source archive and live run output are under `/private/tmp/qd-bfm-localwave1-c339-20261012-01/` until it terminates.

The shared per-row tracker is [`../results.tsv`](../results.tsv); infrastructure and setup states leave its terminal outcome blank.

Because Slurm cannot currently hold job 591, row 4 may also be dispatched remotely if the controller recovers. The four currently running remote rows (0–3) are excluded from the local fallback. Check Slurm before the next row and cancel this array as soon as its controller is usable.
