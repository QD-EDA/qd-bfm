# Adams Bridge width alias overlay

Pinned-only M13 compilation of `sigdecode_h_tb` failed because its testbench
uses `MLDSA_MEM_ADDR_WIDTH`, while pinned `abr_params_pkg` only defines
`ABR_MEM_ADDR_WIDTH`. The protected input package hash is
`4bf9b0f78c39869949d07f8b37c70a04d0f23a6f486982e0b98a78531aa675e9`.

Gate job 2278 used Icarus main `9b5fad2afb4104caa816b257d5bccc40f01b8c66`
and a run-local copy with the single alias
`MLDSA_MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH`; the copied filelist substitutes
that package path and changes no other source. Compile and simulation both
exited 0, and the log says `Test passed`. The stock runner's generic pass-marker
counter does not recognize that test-specific message. Raw logs, file hashes,
tool versions, and overlay are in [`alias-gate-2278.tgz`](alias-gate-2278.tgz);
its SHA-256 is recorded in `alias-gate-2278.tgz.sha256`.

Array 2279 completed `norm_check_tb` and `skdecode_tb` with the alias. Both
compiled and simulated with exit 0. `norm_check_tb` reports successful bound
checks and the expected rejection checks, then `Ctrl test done`. `skdecode_tb`
reports all three unpack checks, detects the intentionally invalid `s1`, and
emits `*** All test cases completed successfully.` plus `* TESTCASE PASSED`.
Logs and hashes: [`alias-confirm-2279.tgz`](alias-confirm-2279.tgz), SHA-256
`b1488dde8b331a7913633ef0719e879a765688d072a1ddc92a8002139dfb2b66`.

Job 2283 also passed `decompose_tb` with the alias plus the one obsolete-port
removal in [`decompose-alias-overlay.patch`](decompose-alias-overlay.patch).
Both normal and usehint cases report success; compile and simulation exited 0.
Logs and hashes: [`decompose-gate-2283.tgz`](decompose-gate-2283.tgz), SHA-256
`bced6d09831492461927828a2cf2ad779e07f9831997412c1cba5b6a0e9cb3c7`.
