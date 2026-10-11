# Caliptra BFM DV test matrix — 2026-10-10

## Pinned sources and inventory

| Source | Revision | State |
| --- | --- | --- |
| Caliptra RTL v2.1.2 | `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` | clean, detached Slurm checkout |
| Adams Bridge v2.0.3 | `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` | clean submodule checkout |

The CSV contains 271 active test YAML entries, each keyed by repository, source
path, line, and `testname:` value:

| Source tests | Count |
| --- | ---: |
| Caliptra authored stimulus | 35 |
| Caliptra generated UVMF | 22 |
| Caliptra stock-firmware integration suites | 162 |
| Adams Bridge authored stimulus | 22 |
| Adams Bridge generated UVMF | 30 |
| **Total** | **271** |

The 162 stock-firmware YAML rows contain 158 distinct `testname` values; the
repeated names are separate source configurations and remain separate CSV
rows. The pinned integration `test_suites` tree also has six top-level
directories with no YAML test declaration (`caliptra_fmc`, `caliptra_rt`,
`caliptra_top`, `fw_test_rom`, `includes`, and `libs`). These are firmware or
support inputs rather than additional runnable YAML test cases, so they are
not counted as tests.

The census uses active `testname:` keys under the pinned `src` trees. It omits
the two Adams Bridge `sim/testlist.yaml` placeholder entries and the
`abr_example_test.yml.orig` backup; those are not runnable test definitions.
This is why a raw recursive `testname:` grep can produce a larger count than
the matrix.

See [the per-test CSV](caliptra_bfm_dv_test_matrix_2026-10-10.csv) for source
lines, status, blocker class, and evidence. The companion
[environment CSV](caliptra_bfm_dv_environment_matrix_2026-10-10.csv) records
all 44 frozen filelists and their pinned c339 compile/runtime observations. Three block-unit rows
also have terminal runtime passes on pinned Icarus c339; these results are
listed below and do not change the count of YAML test declarations. Other
environment rows retain their compile/elaboration status, which alone does
not qualify a test runtime.

## Environment filelist follow-up — 2026-10-11

The 44 pinned c339 environment rows currently classify as 12 **PASS**, 29
**BLOCKED**, 3 **FAIL**, and 0 **UNVERIFIED**. The remaining two rows are
exhaustive masked NTT simulations that reached the 6,900-second timeout without
a testcase verdict. Several zero-exit runs remain blocked because generated
vectors or Python dependencies were unavailable. Full per-row status and logs
are in the [environment matrix report](../../evidence/caliptra-bfm-environment-matrix-20261011/README.md). A reduced, pinned-c339 reproducer for the VVP unpacked-array equality flag limit is filed as [Icarus issue #538](https://github.com/dsellerbrock/iverilog-uvm/issues/538).

## Block-unit runtime follow-up — 2026-10-11

On the same pinned Caliptra and Icarus sources, the local Mac runs for
`hmac_ctrl_tb`, `sha256_ctrl_tb`, and `sha512_ctrl_32bit_tb` each exited 0 with
one pass marker and no failure/error markers. The environment CSV records
these three runtime results. Full commands, source/tool hashes, host versions,
and retained logs are in the
[local run report](../../evidence/caliptra-bfm-unit-tests-20261011/README.md).

## Firmware-suite runtime projection — 2026-10-11

The pinned c339 `rand_test_dma` trace run in
[`job-242/trace-1`](../../evidence/caliptra-bfm-fulltop-rand-dma-reset-c339-20261010/job-242/completed-runs/trace-1/)
advanced from cycle 100 to cycle 25,700 before its 3,500-second runner timeout:
25,600 cycles, or 7.31 effective cycles per end-to-end wall second. This wall
time includes runner setup, so it conservatively understates VVP-only speed.
Scaling one such segment across 271 YAML rows projects 948,500 seconds
(10.98 days). This rough estimate assumes comparable cycles per row; the rows
vary, and the timed-out run did not finish its testcase. The measurement and
projection are reported in
[Icarus issue #536](https://github.com/dsellerbrock/iverilog-uvm/issues/536).

## Status rules

- **PASS** requires a terminal test pass marker, zero test-fail markers, and a
  zero simulator exit, with source/tool provenance recorded. Diagnostic limits
  remain in the row evidence and do not qualify an entire suite.
- **FAIL** requires a completed test with an explicit failure result.
- **BLOCKED** requires a reproduced setup, compile, simulator, or dependency
  blocker before a test can run. Runtime timeout without a testcase result
  remains **UNVERIFIED**.
- **UNVERIFIED** means there is no qualifying terminal result for that exact
  test row yet. Compile-only success and historical runs on another pin do not
  change this status.

## Current classification

Ten generated UVMF tests in three environments are **BLOCKED** on clean
published Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`: ECC (2 tests),
PCRVault (3), and KeyVault (5). Their generated input/output BFM interfaces
fail compilation at package-qualified parameterized proxy class handles,
before VVP or UVM starts. The independent minimal reproducer and ECC run are in
[the ECC compile report](../../evidence/caliptra-bfm-generated-ecc-c339-pilot-20261010/README.md);
the current PCRVault/KeyVault recheck is in
[the generated-environment report](../../evidence/caliptra-bfm-proxy-uvmf-c339-recheck-20261010/README.md).
The shared parser issue is tracked as
[iverilog-uvm #533](https://github.com/dsellerbrock/iverilog-uvm/issues/533).

The other 261 rows remain **UNVERIFIED** pending a qualifying terminal result.
Earlier PCRVault and KeyVault passes on older Icarus revisions are not promoted
to current-tool passes.

Two top-level diagnostic slices have pass markers but do not qualify their
full firmware tests: AES case 0 in `smoke_test_dma_aes_gcm_short_1_dword`, and
one transfer in `rand_test_dma`. The `smoke_test_dma` diagnostic timed out
before a testcase result; its traced follow-up also timed out while the CPU was
preparing a 512-word random payload, before the AHB transfer. These diagnostic
limits are recorded in the per-test CSV and their evidence reports.

For follow-up after the simulator parser is fixed, the first three generated
environments are PCRVault, KeyVault, then ECC. PCRVault has a focused runtime
runner and prior bounded runtime evidence, so it is the quickest end-to-end
recheck. KeyVault adds five generated test configurations on the same blocker.
ECC includes the online-reset test but has only two generated configurations;
its source supplied the smallest reproducer. All three share one external
Icarus blocker, so no QD-BFM workaround is appropriate.

Slurm array 280 is no longer active. Its saved `smoke_test_dma` task timed out
with runner exit 124; the saved AES task output records scheduler termination.
Neither has a testcase result. The 2026-10-11 queue check showed only A1 jobs
321–323 pending on the unavailable node. These firmware diagnostics remain
inconclusive and are not promoted to test passes or failures.

## Older compile-only census

The dated 44-filelist census embedded in
[the consumer manifest](caliptra_bfm_consumer_manifest_2026-10-03.json)
classified 20 filelists as compile-pass, 6 as compile-fail, 17 as setup-blocked,
and 1 as unsupported by the simulator. Those are environment compile results
from the frozen census, not runtime passes for the 271 tests; they are retained
as triage evidence only.
