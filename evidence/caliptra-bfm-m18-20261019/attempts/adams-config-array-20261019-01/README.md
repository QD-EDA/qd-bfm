# Adams Bridge missing-config-header rows — refreshed-main array complete

Array job 3061 reran rows 61, 65, and 69 with the hash-guarded overlay mapping deleted `mldsa_*` paths to the pinned `abr_*` successor. The overlay reached the active testbenches without synthesizing macro values.

| Row | Test | Result | Directly verified evidence |
|---:|---|---|---|
| 61 | `five_squeeze_test` | BLOCKED | Initial array compile exit 1 on stale `.done_i`; corrected row gate compiles, then reaches the unchanged 200,000-cycle cap with no testcase verdict. Current evidence is row61 gate 03, archive SHA-256 `c835f4c12c7ad798454b10a81257251b282019a73e6fc72ada2d219bdd3c2a25`. |
| 65 | `abr_sha3_rand_test` | BLOCKED | Initial array compile exit 1 on stale `.done_i`; corrected row gate compiles, then reaches the unchanged 200,000-cycle cap with no testcase verdict. Current evidence is row65 gate 01, archive SHA-256 `a83543e1b13c16b6d047377195e2b8a521cbcc5be89861828ba879aa34648475`. |
| 69 | `exp_rand_test` | FAIL | Compile and simulation exit 0; the bench reports 10 `Not enough valid samples in the queue` errors and emits `* TESTCASE FAILED`. SHA-256 `42d981776b8bba2b70c38d0dd67982ac3252e04abba5b77bec0c50d6e0b6aa36`. |

Ask-intern correctly identified row 69's explicit failure marker but incorrectly said simulation ran for rows 61/65; their archived `result.json` files have `compile_exit=1` and `sim_exit=null`, verified against the compile logs. The row results point to the archived per-task result JSONs.
