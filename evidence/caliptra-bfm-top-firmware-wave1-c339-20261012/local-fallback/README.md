# Local fallback, 2026-10-12

SSH to DAN-DESKTOP was still unavailable at 04:07 MDT (`Connection closed by 192.168.4.77 port 22`). Before the reset, `squeue` could not contact the Slurm controller, `/usr/bin/scancel` failed with `Input/output error`, `scontrol hold` returned `Unexpected message received`, and run directories returned I/O errors. `/usr/bin/sacct` also returned `Input/output error`. Job 591 could not be held or canceled; local work continues within the Mac budget.

## Local simulator and toolchain

The MacBook Air runs macOS 27.0 on arm64. The Caliptra RTL clone is clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; its Adams Bridge submodule is at `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. The local compiler is xPack RISC-V GCC arm64 15.2.0 and Python is 3.12.14.

Icarus source commit `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` was archived from the separate Icarus checkout and built under `/private/tmp/qd-bfm-icarus-c339-build-20261012-02`; the other agent's checkout and branch were not modified. The build used Homebrew Bison 3.8.2 (Apple's Bison 2.3 cannot parse this source), the macOS SDK libffi headers (`pkg-config` reports 3.4-rc1), Homebrew Z3 5.1.0, and `make -j3`. Build output and installed binary hashes are in `local-preflight.txt` and `icarus-build.log`. The installed binary reports `13.0 (devel) ()` because the archive has no Git metadata; the exact source SHA and binary hashes are recorded.

The Mac JTAG VPI module was compiled from the pinned Caliptra tree's `jtagdpi.c` and `tcp_server.c` with the local `iverilog-vpi`. Its build transcript is `jtagdpi-build.log`.

## Remote task snapshot

At 03:31 MDT, the four remote VVP PIDs were gone. `squeue` still could not reach the controller, `sacct` returned `Input/output error`, and the remote run/log directories returned I/O errors. Each visible `resource.log` and `runner.log` was still zero bytes; no `status.txt` or `result.json` could be recovered. The four rows are `INFRA_EXIT_UNCLASSIFIED`, not PASS/FAIL/TIMEOUT, and require reruns. Their last readable `sim.log` snapshots were unchanged at 49,398 bytes and ended during the `Ready for Fuses deasserted after polling ...` message. That message follows the source loop waiting for `READY_FOR_FUSES_LOW` to clear, but the snapshot has no later BootGo/ROM progress. Details are in [`remote-startup-snapshot/status-02-59.txt`](remote-startup-snapshot/status-02-59.txt), [`status-03-08.txt`](remote-startup-snapshot/status-03-08.txt), [`status-03-19.txt`](remote-startup-snapshot/status-03-19.txt), and [`status-03-31.txt`](remote-startup-snapshot/status-03-31.txt). The captured logs and earlier scan have SHA-256 entries in `remote-startup-snapshot/SHA256SUMS`.

## Local run

The first row-4 setup attempt exited before simulation with two header-copy errors under `MAKEFLAGS=-j3`. The upstream Makefile copies the same header set for each object, consistent with a parallel-copy race. Its 38-second, 1.84 GiB setup-only record is in `attempt-01-setup-race/`. The fresh serial `smoke_test_dma_aes_gcm_cmd_err` run started at 02:45:59 MDT with `MAKEFLAGS=-j1`, the 7,431-second manifest timeout, and `~/codex-supervisor/localrun`; it hit that timeout at 04:49:50 (`localrun_exit=124`). The final `sim.log` shows fuse readiness, the BootGo write, and `CLP: ROM Flow in progress...`, but no PASS/FAIL/FATAL marker or `result.json`; row 4 therefore has terminal outcome `TIMEOUT`. Raw command, logs, exit record, sample, and verified hashes are in `attempt-02-serial/`. The sample reported a 1.0 GiB peak physical footprint before timeout; localrun emitted no final resource summary after killing the process group.

After the row-4 timeout, SSH was checked at 04:53 MDT and still reset. Row 0, `smoke_test_kv_write_scan_mode`, started locally at 04:56 MDT from a fresh output path with `MAKEFLAGS=-j1` and its 6,775-second manifest timeout. It hit the timeout at 06:49:05 (`localrun_exit=124`); its final `sim.log` shows fuse readiness, BootGo, and `CLP: ROM Flow in progress...`, but no PASS/FAIL/FATAL marker or `result.json`. Row 0 is recorded `TIMEOUT`. Raw command and logs, two process samples, and checked hashes are in `attempt-03-row0/`. The samples showed a 1.0 GB peak physical footprint; localrun emitted no final resource summary after killing the process group.

The shared per-row tracker is [`../results.tsv`](../results.tsv); infrastructure and setup states leave its terminal outcome blank.

SSH was checked at 06:54 MDT and still reset. Row 1 (`cptra_ss_test_rom`) started locally around 06:57 MDT with its 6,873-second limit; its command and start record are in `attempt-04-row1/`. Because Slurm cannot currently hold job 591, pending rows may be dispatched remotely if the controller recovers. Check Slurm once before each later local launch, cancel this array if the controller is usable, and continue locally one row at a time if it is not.
