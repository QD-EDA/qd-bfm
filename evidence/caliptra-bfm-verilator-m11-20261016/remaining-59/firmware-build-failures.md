# M11 firmware build failures

These 14 rows fail while compiling or linking the pinned stock firmware, before simulation. The first 12 diagnostics below were checked in each archived `firmware.log` in [`completed-1964-01.tar.gz`](completed-1964-01.tar.gz); `smoke_test_uart` is in [`completed-1964-03.tar.gz`](completed-1964-03.tar.gz), and `smoke_test_kv_crypto_flow2` is in [`completed-1964-04.tar.gz`](completed-1964-04.tar.gz). They are `FIRMWARE_BUILD_FAIL`, not Verilator simulation results. c339 has the same build-stage failure for `smoke_test_ecc_errortrigger4`, `smoke_test_qspi`, and `smoke_test_uart`; for UART, the closed M9 disagreement record confirms the same 12 undefined register/field macros. The other rows have no completed c339 run. `smoke_test_hw_config`'s old matrix status is not a finished c339 run, as recorded in the closed M9 disagreement report.

| Test | Verified build cause | Diagnostic |
|---|---|---|
| `smoke_test_kv_ecdh_flow` (`5c07448096cbab59`) | Function definition omits a return type under the firmware compiler flags | `return type defaults to 'int' [-Wimplicit-int]` at `smoke_test_kv_ecdh_flow.c:124` |
| `smoke_test_kv_ecc_flow1` (`b65eaf52203ca1c3`), `smoke_test_hmac_errortrigger` (`4088dcffd3297382`), `smoke_test_kv_ecc_flow2` (`244a281ff42ebdc1`) | `srand` is used without a visible declaration | `implicit declaration of function 'srand'` |
| `smoke_test_clk_gating` (`a0a7e79a3779b0ba`), `smoke_test_hw_config` (`4e6f763fa02018da`), `smoke_test_ras` (`6dc114367c8b520c`) | Link lacks the implementation of the SoC-IFC notification ISR referenced by `caliptra_isr.c` | `undefined reference to 'service_soc_ifc_notif_intr'` |
| `caliptra_demo` (`957dd42951b28ed5`) | Test references register macros absent from the pinned headers, including KV PCR and HMAC384 names | `CLP_KV_REG_PCR_ENTRY_0_0` undeclared; compiler suggests `CLP_PV_REG_PCR_ENTRY_0_0` and HMAC512 names for HMAC384 references |
| `smoke_test_ecc_errortrigger4` (`eaeb97287ce63194`) | Test ISR calls ABR handlers with no visible declarations | `implicit declaration of function 'service_abr_error_intr'` and `service_abr_notif_intr` |
| `smoke_test_qspi` (`9f91b0f948764f74`) | Test references QSPI/SPI-host register macros absent from the pinned headers | `SOC_IFC_REG_CPTRA_HW_CONFIG_QSPI_EN_MASK` and `CLP_SPI_HOST_REG_CSID` undeclared |
| `smoke_test_mlkem_all_zero_seed` (`769b6966a3a192b0`) | Call site does not match the available `mlkem_encaps_check` signature | `too many arguments ... expected 5, have 6` |
| `pv_hash_reset` (`001a3be50b29e4b3`) | Test references a SHA512 register macro not defined by the pinned headers | `CLP_SHA512_REG_SHA512_GEN_PCR_HASH_NONCE` undeclared; compiler suggests `_NONCE_0` |
| `smoke_test_uart` (`1e057b20d3564828`) | Firmware uses UART and UART-enable register names absent from the pinned generated headers | 12 undefined identifiers, including `SOC_IFC_REG_CPTRA_HW_CONFIG_UART_EN_MASK`, `CLP_UART_STATUS`, `CLP_UART_WDATA`, `CLP_UART_RDATA`, and `CLP_UART_CTRL`; c339 and Verilator have the same missing-symbol set |
| `smoke_test_kv_crypto_flow2` (`2c12f5a5a0c9a13c`) | The `mldsa_keygen_flow` call passes an integer where its declaration requires a private-key pointer | `passing argument 3 ... makes pointer from integer without a cast` at `smoke_test_kv_crypto_flow2.c:522` |

The grouped diagnostics identify the source-level compile/link blockers. They do not establish whether a newer firmware source revision or a test-specific compatibility change is the intended fix.
