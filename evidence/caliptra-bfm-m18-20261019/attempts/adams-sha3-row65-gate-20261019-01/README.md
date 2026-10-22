# Adams Bridge abr_sha3 row65 gate

One-row rerun of `abr_sha3_rand_test` with the current hash-guarded filelist/testbench overlay. It aliases the stale sampler package import, removes the obsolete `.done_i` port, and leaves RTL, stimuli, expected values, and pass criteria unchanged.

- Row 65; `#SBATCH --array=65`
- Icarus `cae035642e056644274a01e98d4422ce286685b4`; binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`
- DAN-DESKTOP, 1 CPU, 1 GiB, 600-second runner timeout
- Source snapshot SHA-256: `b97f73385daaff0e89ee4359722bb900a582d88aaa3b65bcd353690d93b7a3d9`
- Run script SHA-256: `84fb9342695b4490bfb39db413916dd0864022000d5c3df70d6240a157bd3748`

Job 3067 compiled successfully and hit the unchanged 200,000-cycle cap without a testcase verdict; row65 remains `BLOCKED`. Raw archive SHA-256 `a83543e1b13c16b6d047377195e2b8a521cbcc5be89861828ba879aa34648475` matches its sidecar.
