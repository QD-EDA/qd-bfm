# ECC, SHA512, and PCRVault current-main array — complete

Array job 3043 ran rows 16, 17, 46, 47, 48, 54, and 55 with the pinned Icarus main snapshot `cae035642e056644274a01e98d4422ce286685b4`. Each task requested 1 CPU and 4 GiB, with a 600-second runner timeout. The seven raw task archives and their SHA-256 sidecars are in `raw/`; each sidecar was checked against its archive before updating `m18-results.tsv`.

All seven compile attempts stopped before simulation and are recorded `BLOCKED`:

| Row | Area | Compile exit | First blocker |
|---:|---|---:|---|
| 16 | SHA512 | 2 | `SHA512_out_transaction_coverage.svh:17`, automatic bins on a >64-bit coverpoint (#667) |
| 17 | SHA512 | 2 | `SHA512_out_transaction_coverage.svh:17`, automatic bins on a >64-bit coverpoint (#667) |
| 46 | PCRVault | 80 | `pv_rst_configuration.svh:149`, generated `$psprintf` has missing/empty parameters (#670) |
| 47 | PCRVault | 80 | `pv_rst_configuration.svh:149`, generated `$psprintf` has missing/empty parameters (#670) |
| 48 | PCRVault | 80 | `pv_rst_configuration.svh:149`, generated `$psprintf` has missing/empty parameters (#670) |
| 54 | ECC | 10 | `ECC_out_transaction_coverage.svh:17`, automatic bins on a >64-bit coverpoint (#667) |
| 55 | ECC | 10 | `ECC_out_transaction_coverage.svh:17`, automatic bins on a >64-bit coverpoint (#667) |

The earliest diagnostics and terminal compile-only statuses were checked directly in each archive's `result.json` and `compile.log`. Ask-intern's triage was treated as a hint; its row attribution was not fully reliable. The shared upstream main ref remained `cae035642e056644274a01e98d4422ce286685b4` when checked after the run.
