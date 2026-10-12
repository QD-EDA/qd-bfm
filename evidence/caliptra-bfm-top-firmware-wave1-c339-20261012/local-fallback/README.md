# Local fallback, 2026-10-12

As of 03:44 MDT, SSH to DAN-DESKTOP resets the connection. Before that, `squeue` could not contact the Slurm controller, `/usr/bin/scancel` failed with `Input/output error`, `scontrol hold` returned `Unexpected message received`, and run directories returned I/O errors. `/usr/bin/sacct` also returned `Input/output error`. Job 591 could not be held or canceled; local work continues within the Mac budget.

## Local simulator and toolchain

The MacBook Air runs macOS 27.0 on arm64. The Caliptra RTL clone is clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; its Adams Bridge submodule is at `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. The local compiler is xPack RISC-V GCC arm64 15.2.0 and Python is 3.12.14.

Icarus source commit `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` was archived from the separate Icarus checkout and built under `/private/tmp/qd-bfm-icarus-c339-build-20261012-02`; the other agent's checkout and branch were not modified. The build used Homebrew Bison 3.8.2 (Apple's Bison 2.3 cannot parse this source), the macOS SDK libffi headers (`pkg-config` reports 3.4-rc1), Homebrew Z3 5.1.0, and `make -j3`. Build output and installed binary hashes are in `local-preflight.txt` and `icarus-build.log`. The installed binary reports `13.0 (devel) ()` because the archive has no Git metadata; the exact source SHA and binary hashes are recorded.

The Mac JTAG VPI module was compiled from the pinned Caliptra tree's `jtagdpi.c` and `tcp_server.c` with the local `iverilog-vpi`. Its build transcript is `jtagdpi-build.log`.

## Remote task snapshot

At 03:31 MDT, the four remote VVP PIDs were gone. `squeue` still could not reach the controller, `sacct` returned `Input/output error`, and the remote run/log directories returned I/O errors. Each visible `resource.log` and `runner.log` was still zero bytes; no `status.txt` or `result.json` could be recovered. The four rows are `INFRA_EXIT_UNCLASSIFIED`, not PASS/FAIL/TIMEOUT, and require reruns. Their last readable `sim.log` snapshots were unchanged at 49,398 bytes and ended during the `Ready for Fuses deasserted after polling ...` message. That message follows the source loop waiting for `READY_FOR_FUSES_LOW` to clear, but the snapshot has no later BootGo/ROM progress. Details are in [`remote-startup-snapshot/status-02-59.txt`](remote-startup-snapshot/status-02-59.txt), [`status-03-08.txt`](remote-startup-snapshot/status-03-08.txt), [`status-03-19.txt`](remote-startup-snapshot/status-03-19.txt), and [`status-03-31.txt`](remote-startup-snapshot/status-03-31.txt). The captured logs and earlier scan have SHA-256 entries in `remote-startup-snapshot/SHA256SUMS`.

## Local run

The first row-4 setup attempt exited before simulation with two header-copy errors under `MAKEFLAGS=-j3`. The upstream Makefile copies the same header set for each object, consistent with a parallel-copy race; the serial retry will verify this. Raw logs and its 38-second, 1.84 GiB resource record are in `attempt-01-setup-race/`; this is not a test verdict. A fresh run of `smoke_test_dma_aes_gcm_cmd_err` started at 02:45:59 MDT with `MAKEFLAGS=-j1`, its 7,431-second manifest timeout, and `~/codex-supervisor/localrun`. At 03:44 its VVP process remained active at about 85% CPU and 0.60 GiB RSS; `sim.log` was unchanged from 02:46:58, with no `result.json` or terminal marker. The latest status is in [`attempt-02-serial/observations-03-44.txt`](attempt-02-serial/observations-03-44.txt); the immutable QD source archive and live run output are under `/private/tmp/qd-bfm-localwave1-c339-20261012-01/` until it terminates.

The shared per-row tracker is [`../results.tsv`](../results.tsv); infrastructure and setup states leave its terminal outcome blank.

Because Slurm cannot currently hold job 591, pending rows may be dispatched remotely if the controller recovers. After row 4 finishes, check Slurm once before each local launch; cancel this array if the controller is usable, and continue locally one row at a time if it is not.
