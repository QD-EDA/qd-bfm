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
all 44 frozen filelists and their older compile observations; every current
environment status remains unverified until rechecked with pinned Icarus.

## Status rules

- **PASS** requires a terminal test pass marker, zero test-fail markers, and a
  zero simulator exit, with source/tool provenance recorded. Diagnostic limits
  remain in the row evidence and do not qualify an entire suite.
- **FAIL** requires a completed test with an explicit failure result.
- **BLOCKED** requires a reproduced setup, compile, simulator, or dependency
  blocker before a test can run.
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

For follow-up after the simulator parser is fixed, the first three generated
environments are PCRVault, KeyVault, then ECC. PCRVault has a focused runtime
runner and prior bounded runtime evidence, so it is the quickest end-to-end
recheck. KeyVault adds five generated test configurations on the same blocker.
ECC includes the online-reset test but has only two generated configurations;
its source supplied the smallest reproducer. All three share one external
Icarus blocker, so no QD-BFM workaround is appropriate.

Slurm array 280 is running a bounded first pass over the QD-BFM runner's three
top-level firmware cases. `smoke_test_dma` uses fast RNG and boot-data preload;
the AES case is limited to its first case; `rand_test_dma` is limited to one
transfer. Each row will be updated only after its own runner result and source
hashes are checked. These are diagnostic executions, not full-suite claims.

## Older compile-only census

The dated 44-filelist census embedded in
[the consumer manifest](caliptra_bfm_consumer_manifest_2026-10-03.json)
classified 20 filelists as compile-pass, 6 as compile-fail, 17 as setup-blocked,
and 1 as unsupported by the simulator. Those are environment compile results
from the frozen census, not runtime passes for the 271 tests; they are retained
as triage evidence only.
