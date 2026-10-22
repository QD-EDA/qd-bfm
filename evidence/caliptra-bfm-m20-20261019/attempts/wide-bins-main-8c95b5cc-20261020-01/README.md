# Icarus main build for M20b wide-bin reruns

Builds the current `main` commit `8c95b5cc10fc83d15b47e0364d2d7b4a2e12cac1`, which is the merge commit for PR #697. The job fetches this exact commit and its `uvm-core` submodule commit `78c06547a2a0a29b3dc9dcafae62b75b2ff61544` directly from the public repository.

The isolated Slurm build requests 2 CPUs, 8 GiB, and 1 hour. It installs to `/home/dsell/toolchains/iverilog-uvm-main-8c95b5cc10fc83d15b47e0364d2d7b4a2e12cac1`; the source tree stays in the disposable run directory, while the script and build log are preserved here. After build, the binary hashes and version are recorded before running rows 16, 17, 54, and 55.

Build job 3354 completed on DAN-DESKTOP. The installed binaries are Icarus 13.0 devel (`8c95b5cc`), with `iverilog` SHA-256 `825148179dae25095eb5ec3d7804a5c5c0a09102c78dc47d2f86ffdf95141d6d` and `vvp` SHA-256 `36831eaf6a1902cd3625bc5db478636a1d3dc7bb8030c000e1d19a3d46f28375`; the source and UVM submodule pins are recorded in `toolchain-manifest.txt`.

The PR's own 512-bit regression passes with its `-g2017` options and prints `PASSED`. An earlier manual check used the old `-g2012` module fixture; it reproduced the previous diagnostic, so it is retained only as an invalid-mode setup note in `raw/run-main-2012-mode-check.log`. The Caliptra runner uses `-g2017`.

`run_m15_test_main.py` is the existing 123 KB M15 runner with only its Icarus commit and binary-hash constants changed. Its base runner SHA-256 is `2b73eb666e901dfb35db46034c83b227b9161bb85e4eb40401f6f5f2d74a7379`; the copied version is checked to differ only in those two constants. The pinned M15 manifest is copied beside it with a SHA-256 sidecar. Array 3355 attempted rows 16, 17, 54, and 55 with two-task throttling and a 3,600-second runner timeout per row; submission details are in `rows-submission.txt`.

Array 3355 is an invalid preflight attempt, not a row result. All four runner JSON files report `BLOCKED` before compilation because `--repo-root` lacked `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f` (`compile_exit` is absent). Per-row archives and Slurm logs are preserved under `raw/preflight-3355/` with matching SHA-256 sidecars. Attempt 02 stages the runner's 37 clean support sources and uses that directory as `--repo-root`.
