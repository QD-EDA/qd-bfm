# Adams Bridge abr_sha3 row61 overlay gate

Rechecks the hash-guarded testbench-only edits for the pinned `abr_sha3_tb`: alias the legacy sampler package import to `abr_sampler_pkg` and remove its obsolete `.done_i` port connection. The edits share one overlay copy; RTL, stimulus, expectations, and pass criteria stay pinned.

- Row 61; `#SBATCH --array=61`
- Icarus `cae035642e056644274a01e98d4422ce286685b4`; binary SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`
- DAN-DESKTOP, 1 CPU, 1 GiB, 600-second runner timeout
- Source snapshot SHA-256: `b97f73385daaff0e89ee4359722bb900a582d88aaa3b65bcd353690d93b7a3d9`
- Run script SHA-256: `c8c948d5bae7861a6a4c04afead1aa3a017f967956ed9cf5c2cc7babc5c845a5`

Job 3066 compiled successfully and then hit the bench's unchanged 200,000-cycle cap without a testcase verdict. Row61 remains `BLOCKED`; raw archive SHA-256 `c835f4c12c7ad798454b10a81257251b282019a73e6fc72ada2d219bdd3c2a25` matches its sidecar.
