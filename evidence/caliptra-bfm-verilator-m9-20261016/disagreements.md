# Verilator versus Icarus disagreements

This list compares rows with a terminal Icarus result artifact. The `smoke_test_hw_config` table entry marked `prior_icarus_evidence=matrix status` is metadata, not a finished Icarus run, so it is excluded.

## `smoke_test_ecc_errortrigger2`: assertion-enabled Icarus FAIL versus Verilator PASS

- Icarus c339: FAIL at `ERR_ECC_PRIVKEY_NOT_STABLE` (`ecc_dsa_ctrl.sv:1081`) during the first ECC PCR-signing phase. Its recorded compile command defines `CLP_ASSERT_ON`.
- Verilator 5.052: PASS at mcycle 68,185. The M9 model build sets `CALIPTRA_INTERNAL_TRNG` and `CALIPTRA_BFM_CHECKER`, but not `CLP_ASSERT_ON`; the staged Verilator filelist also has no such define.
- Pinned source explains the result difference: `caliptra_sva.svh` emits concurrent assertions only inside ``ifdef CLP_ASSERT_ON`` (lines 35–41), and `CALIPTRA_ASSERT_STABLE` checks `$stable(sig)` (lines 60–62). `ecc_dsa_ctrl.sv:1014` applies this property to `privkey_reg` while ECC is active. Thus Icarus checks the property and stops; the Verilator run does not compile it and can reach the firmware PASS marker.

Evidence: Icarus [compile command](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-35-smoke_test_ecc_errortrigger2/result.json), [Icarus failure log](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-35-smoke_test_ecc_errortrigger2/sim.log), and Verilator [result and log](runs/78ad1bab537c2ff8/result.json). Source links: [assertion macro](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/src/libs/rtl/caliptra_sva.svh#L35-L62), [ECC stability assertion](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/src/ecc/rtl/ecc_dsa_ctrl.sv#L1004-L1015).

This roots the comparison mismatch in assertion configuration. The underlying private-key stability event remains unresolved because the Verilator run omitted the assertion; this is not evidence that the assertion is a false positive or that the RTL is correct.

## `pv_hash_zeroize`: assertion-enabled Icarus FAIL versus Verilator PASS

- Icarus c339: FAIL at 597,595,000 ns on `ERR_SHA_BLOCK_NOT_STABLE` from pinned `sha512.sv:538`, after the test's SHA-512 zeroize and hash-start sequence. The fatal is reported at `sha512.sv:565`.
- Icarus compiles with `-gassertions -D CLP_ASSERT_ON` (`run_caliptra_top_firmware_bfm.py:904-908`). The pinned `CALIPTRA_ASSERT_STABLE` macro expands to a `$stable(sig)` property, and `CALIPTRA_ASSERT` emits that property only under `CLP_ASSERT_ON`.
- The Verilator 5.052 model build has neither `+define+CLP_ASSERT_ON` nor `--assert` in its recorded command. Its PASS at mcycle 61,838 therefore does not exercise `ERR_SHA_BLOCK_NOT_STABLE`.

Evidence: Icarus [compile command](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-8-pv_hash_zeroize/compile.log), [failure log](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-8-pv_hash_zeroize/sim.log), and [classification](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-8-pv_hash_zeroize/classification.txt); Verilator [result](runs/9160c33b030e9483/result.json) and [pinned model build log](build-evidence/build.log). Source: [assertion macro](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/src/libs/rtl/caliptra_sva.svh#L35-L62), [SHA-512 property](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/src/sha512/rtl/sha512.sv#L536-L538).

The recorded result disagreement is caused by different assertion coverage, not a demonstrated simulator defect. Whether the stability assertion is detecting an RTL bug or an Icarus-specific behavior remains unresolved because this Verilator model omits the assertion.

## `smoke_test_ecc_errortrigger4`: outcome-label mismatch, same pre-simulation build failure

The matrix records Icarus `FAIL` and Verilator `FIRMWARE_BUILD_FAIL`; the configured Verilator case YAML is `smoke_test_ecc_errortrigger5`, while its YAML test name is `smoke_test_ecc_errortrigger4`. Both raw runs stop during the firmware C build before simulation. Icarus task 669_31 reports implicit declarations of `service_abr_error_intr` and `service_abr_notif_intr` in `caliptra_isr.c:754`, with `simulation=not_started`; Verilator task 1430_83 reports the same two missing functions and `firmware_exit=2`. The difference is the terminal label used by the older Icarus evidence, not simulator behavior. See [Icarus classification](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-31-smoke_test_ecc_errortrigger4/classification.txt), [Icarus compile log](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-31-smoke_test_ecc_errortrigger4/compile.log), [Verilator result](runs/eaeb97287ce63194/result.json), and [Verilator firmware log](runs/eaeb97287ce63194/firmware.log).

## `smoke_test_qspi`: Icarus FAIL label versus Verilator firmware-build failure

Icarus c339 task 27 is classified `FAIL` at `firmware_build`; its compiler reports that the test source references QSPI register symbols absent from the generated `caliptra_reg.h`, and the classification explicitly records that simulation did not start. Verilator 5.052 task 1430_108 reports `FIRMWARE_BUILD_FAIL` for the same test. Its compiler reports undeclared `SOC_IFC_REG_CPTRA_HW_CONFIG_QSPI_EN_MASK`, `CLP_SPI_HOST_REG_CSID`, `CLP_SPI_HOST_REG_STATUS`, and other `CLP_SPI_HOST_REG_*` and `SPI_HOST_REG_*` names. The source/header mismatch is the same on both runs; the difference is only the terminal label, not simulator behavior.

Evidence: Icarus [classification](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-27-smoke_test_qspi/classification.txt), [compiler log](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-27-smoke_test_qspi/firmware.log), and Verilator [result](runs/9f91b0f948764f74/result.json) and [compiler log](runs/9f91b0f948764f74/firmware.log).

## `smoke_test_uart`: outcome-label mismatch, same missing firmware definitions

Icarus records `FAIL`; Verilator records `FIRMWARE_BUILD_FAIL`. Both compiler logs fail while building the same `smoke_test_uart.c` object, with the identical 12 UART register and field macros undeclared. The Icarus classification records that these names are absent from the pinned `caliptra_reg.h`; the Verilator result has no simulation exit or simulation time. This is a firmware source/header defect in the pinned Caliptra tree, not a simulator disagreement.

Evidence: Icarus [missing-symbol check](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-9-smoke_test_uart/missing-symbol-check.txt) and [compiler log](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-9-smoke_test_uart/firmware.log); Verilator [compiler log](runs/1e057b20d3564828/firmware.log) and [result](runs/1e057b20d3564828/result.json). An exact comparison of undeclared-identifier sets from the two compiler logs found the same 12 names.

## `smoke_test_mbox`: Icarus PASS versus Verilator TIMEOUT at the read-to-set lock handoff

The Icarus c339 run passes at mcycle 74,924. Its SoC BFM reports lock grant after one poll, completes the mailbox exchange, and prints `* TESTCASE PASSED`. Verilator 5.052 times out at the mailbox-lock request with no command-register write. Both runs use identical `program.hex` and `dccm.hex` hashes.

The pinned lock CSR is software-set-on-read (`mbox_csr.sv:273–285`); the SoC BFM loops while the returned lock bit is one (`caliptra_top_tb_soc_bfm.sv:341–346`). Firmware has no earlier lock read in this flow; its only `MBOX_LOCK` read occurs later at `smoke_test_mbox.c:109`. Diagnostic job 1614 showed complete AR/R handshakes returning `RDATA=1`, not an unanswered AXI read. Job 1617 traced the task boundary: 20 `axi_read_single` calls returned `data=1`, `resp=0`, and the BFM began the next poll after each return. No lock grant or command write appeared before the separate diagnostic cap. The first SoC BFM read sets the free lock but Verilator returns the set value, so the BFM interprets the lock it just acquired as busy and keeps polling. Icarus sees `0` on its first poll and exits the loop. This roots the result mismatch in the lock's read-to-set response and polling condition; the exact simulator-scheduling versus upstream RTL-race cause of the differing first-read value remains unisolated.

A separate `resp_user = new[len+1]` diagnostic overlay did not change the timeout, so that array allocation is not the cause. Both focused trace runs reached their separate outer diagnostic caps and did not produce terminal test results; the original M9 row remains `TIMEOUT`.

Evidence: Icarus [result](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-16-smoke_test_mbox/result.json) and [simulator trace](../caliptra-bfm-top-firmware-wave1-c339-20261012/terminal-results/task-16-smoke_test_mbox/sim.log); Verilator [result](runs/78bfcc1e9aac255e/result.json) and [simulator trace](runs/78bfcc1e9aac255e/sim.log); focused [AXI trace report](diagnostics/mbox-axi-trace-20261016-01/README.md), [call-boundary trace report](diagnostics/mbox-axi-calltrace-20261016-01/README.md), and M9 collection record [`collection-20261016-0204.txt`](collection-20261016-0204.txt).
