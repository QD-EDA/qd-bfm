# E-Verilog waitlist

This list separates cases that could not complete the M24 Verilator 5.052 flow from terminal simulation failures. The per-row matrix is in [`M24 results`](../evidence/caliptra-bfm-m24-20261022/results.tsv).

## Stock-firmware cases that did not complete

| Test ID | Case | M24 result | Why not Verilator |
| --- | --- | --- | --- |
| `5c07448096cbab59` | `smoke_test_kv_ecdh_flow` | FIRMWARE_BUILD_FAIL (0.811 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/smoke_test_kv_ecdh_flow/smoke_test_kv_ecdh_flow.c:124:1: error: return type defaults to 'int' [-Wimplicit-int] |
| `b65eaf52203ca1c3` | `smoke_test_kv_ecc_flow1` | FIRMWARE_BUILD_FAIL (0.801 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/smoke_test_kv_ecc_flow1/smoke_test_kv_ecc_flow1.c:197:5: error: implicit declaration of function 'srand' [-Wimplicit-function-declaration] |
| `a0a7e79a3779b0ba` | `smoke_test_clk_gating` | FIRMWARE_BUILD_FAIL (2.328 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/libs/caliptra_isr/caliptra_isr.c:808:(.text+0xee): undefined reference to `service_soc_ifc_notif_intr' |
| `4e6f763fa02018da` | `smoke_test_hw_config` | FIRMWARE_BUILD_FAIL (2.317 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/libs/caliptra_isr/caliptra_isr.c:808:(.text+0x3ca): undefined reference to `service_soc_ifc_notif_intr' |
| `957dd42951b28ed5` | `caliptra_demo` | FIRMWARE_BUILD_FAIL (1.142 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/caliptra_demo/caliptra_demo.c:131:27: error: 'CLP_KV_REG_PCR_ENTRY_0_0' undeclared (first use in this function); did you mean 'CLP_PV_REG_PCR_ENTRY_0_0'? |
| `eaeb97287ce63194` | `smoke_test_ecc_errortrigger4` | FIRMWARE_BUILD_FAIL (0.842 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/libs/caliptra_isr/caliptra_isr.c:754:5: error: implicit declaration of function 'service_abr_error_intr'; did you mean 'service_kv_error_intr'? [-Wimplicit-function-declaration] |
| `9f91b0f948764f74` | `smoke_test_qspi` | FIRMWARE_BUILD_FAIL (1.05 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/smoke_test_qspi/smoke_test_qspi.c:57:16: error: 'SOC_IFC_REG_CPTRA_HW_CONFIG_QSPI_EN_MASK' undeclared (first use in this function); did you mean 'SOC_IFC_REG_CPTRA_HW_CONFIG_RSVD_EN_MASK'? |
| `769b6966a3a192b0` | `smoke_test_mlkem_all_zero_seed` | FIRMWARE_BUILD_FAIL (0.79 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/smoke_test_mlkem_all_zero_seed/smoke_test_mlkem_all_zero_seed.c:490:5: error: too many arguments to function 'mlkem_encaps_check'; expected 5, have 6 |
| `001a3be50b29e4b3` | `pv_hash_reset` | FIRMWARE_BUILD_FAIL (0.803 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/pv_hash_reset/pv_hash_reset.c:133:22: error: 'CLP_SHA512_REG_SHA512_GEN_PCR_HASH_NONCE' undeclared (first use in this function); did you mean 'CLP_SHA512_REG_SHA512_GEN_PCR_HASH_NONCE_0'? |
| `6dc114367c8b520c` | `smoke_test_ras` | FIRMWARE_BUILD_FAIL (2.469 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/libs/caliptra_isr/caliptra_isr.c:808:(.text+0x5b2): undefined reference to `service_soc_ifc_notif_intr' |
| `4088dcffd3297382` | `smoke_test_hmac_errortrigger` | FIRMWARE_BUILD_FAIL (0.798 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/smoke_test_hmac_errortrigger/smoke_test_hmac_errortrigger.c:44:5: error: implicit declaration of function 'srand' [-Wimplicit-function-declaration] |
| `244a281ff42ebdc1` | `smoke_test_kv_ecc_flow2` | FIRMWARE_BUILD_FAIL (0.796 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/smoke_test_kv_ecc_flow2/smoke_test_kv_ecc_flow2.c:197:5: error: implicit declaration of function 'srand' [-Wimplicit-function-declaration] |
| `1e057b20d3564828` | `smoke_test_uart` | FIRMWARE_BUILD_FAIL (0.838 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/smoke_test_uart/smoke_test_uart.c:39:16: error: 'SOC_IFC_REG_CPTRA_HW_CONFIG_UART_EN_MASK' undeclared (first use in this function); did you mean 'SOC_IFC_REG_CPTRA_HW_CONFIG_RSVD_EN_MASK'? |
| `2c12f5a5a0c9a13c` | `smoke_test_kv_crypto_flow2` | FIRMWARE_BUILD_FAIL (0.797 s) | /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/integration/test_suites/smoke_test_kv_crypto_flow2/smoke_test_kv_crypto_flow2.c:522:38: error: passing argument 3 of 'mldsa_keygen_flow' makes pointer from integer without a cast [-Wint-conversion] |
| `f1991acb7ebadfe1` | `cptra_ss_test_rom` | TIMEOUT (6875.604 s) | No terminal result before the 6,873-second M24 cap. The matching M9 trace identifies a DMA write to unmapped destination `0x21200000` returning DECERR, followed by notification re-entry; see [M9 root causes](../evidence/caliptra-bfm-verilator-m9-20261016/root-causes.md). |

## Non-firmware rows without an M24 launch path

The full-top firmware runner accepts only stock-firmware YAMLs. Authored-stimulus and generated-UVMF benches need dedicated Verilator entry points; these are WAITLIST rows, not simulator failures, and M24 did not simulate them.

| Test ID | Test | Matrix kind | Reason |
| --- | --- | --- | --- |
| `ae4874726ffc4f34` | `caliptra_top_rand_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `3251e90acd650145` | `caliptra_top_wdt_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `e3be45f16f5d3c60` | `caliptra_top_wdt_independent_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `dd96858a01a39df9` | `caliptra_top_cmdline_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `f545f910b409a4a1` | `caliptra_top_rom_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `6fcd241c41010d78` | `HMAC_random_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `e32993a67bc5d68a` | `HMAC_otf_reset_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b583586f0ad8e7ce` | `kv_rand_lock_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b261355e6e129ffa` | `example_derived_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `079458dee2f51386` | `kv_rand_wr_rd_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `e3f94058b18ae0cd` | `kv_rand_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `8306619aafe8cdc9` | `kv_rand_debug_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `a9ef0208e7ac8811` | `hmac_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `6497ec010533483a` | `uart_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b34820723f6397ce` | `doe_cbc_nist_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `83818541ae3f578e` | `entropy_src_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `162c2cbf48fa39cc` | `sha512_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `259beb74602f22fc` | `example_derived_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b9bede6960d44d15` | `SHA512_random_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `4b7ebe27ae1a7d38` | `sha256_random_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `a41d0128a4c9a7be` | `sha256_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `563ad4f531b097c5` | `csrng_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `c6fa19c3b9d0f27d` | `fuse_reg_prod_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `cb279ca38f7ee4ed` | `debug_unlock_manuf_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `5e7014ab4db0808c` | `ss_soc_dbg_unlock_level_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `e13985100e2bbaaf` | `fuse_cptra_cap_reg_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `3cf0a7f8bc483322` | `ss_strap_reg_wrmrst_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `2618febe2cd67394` | `fuse_reg_lifecycle_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `1795521d5526bcfe` | `rvtime_reg_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `a7a48d2fdd73f276` | `soc_reg_intrblk_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `17f68a2db6361be2` | `soc_reg_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `8df0909c7d7d79bb` | `fuse_reg_perm_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `89d696941206b186` | `sha_acc_intrblk_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `31f9d77f604dfba1` | `fuse_reg_axi_user_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `99f799a903ca7f47` | `ss_strap_reg_pwron_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `67a5899ccd23ba72` | `soc_reg_invalid_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `a42f52975020183f` | `soc_reg_pwron_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `5ae4b3b3e2fc9b87` | `debug_unlock_prod_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `f7a178c7d8dfece1` | `ss_strap_reg_prod_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `8aa8b4617d15bf45` | `soc_ifc_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `a6e90d7a9647bdff` | `soc_ifc_axi_sha_acc_dis_tb` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `4c053cfe19b15fa9` | `soc_reg_wrmrst_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `794c4ccf9b89f2ef` | `single_socreg_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b0857ffb7440425b` | `ss_strap_reg_lifecycle_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `3ad5509d67bda0df` | `soc_ifc_trng_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `44d7eaf9dc4fe6fa` | `soc_ifc_rand_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b09f80d530760b4b` | `soc_ifc_cmdline_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `1c94fb399fd5bdef` | `pv_rand_wr_rd_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `ccb350f68016fd2d` | `pv_rand_lock_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `531a90cfa48d3b32` | `pv_rand_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b0aa4c9a764ffb9f` | `ecc_sca_config_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `50d7c722b3520bd0` | `ecc_otf_reset_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `ec5b39f2e321878a` | `ecc_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `3228adafbabcac87` | `hmac_drbg_randomized_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `8710ad77652cbe51` | `hmac_drbg_directed_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `0d3745a5c8b7522d` | `ECC_normal_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `95b78e739f38fa0c` | `ECC_otf_reset_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `a05eb73ccf7e38c4` | `rej_rand_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `524b518c8b62b555` | `sigencode_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `98ff6f074fa89451` | `sib_rand_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `87716ff2a4ffb36e` | `norm_check_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `877144ef3d7adabc` | `skencode_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `46e6d5e13e097fae` | `five_squeeze_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `7b0341faa00f108a` | `cbd_rand_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `592e7b9b73903ff2` | `decompose_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b7f74adec4be982a` | `compress_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `38aef568a4413d50` | `abr_sha3_rand_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `ca357d16a893acae` | `skdecode_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `88f1156847de47f8` | `sigdecode_h_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `c51f576114c59094` | `masking_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `f93089e3ba20daac` | `exp_rand_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `4435fb2c4061476a` | `power2round_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `0c42f3fba482840b` | `rej_rand_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `88ef23f5fcc43e8a` | `sigdecode_z_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `bde39b679bd7ca4b` | `ntt_masking_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `539d500919b1ac8d` | `pkdecode_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `3138fc010b7a9321` | `ntt_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `9d66c2de172bcc30` | `butterfly_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `aa75c6ef03733ea0` | `ML_DSA_randomized_key_gen_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b4169e7e699dd1ef` | `ML_DSA_randomized_verif_stream_msg_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `e078f3a34735e3c5` | `ML_KEM_keygen_KATs_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `ec8b3d4345c9cc7e` | `ML_DSA_verif_KATs_stream_msg_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `79baa11932249996` | `ML_KEM_keygen_decaps_self_check_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `a177ac673703fe82` | `ML_DSA_verif_KATs_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `7f3204fc9bb5fe50` | `ML_KEM_randomized_all_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `0309cd97a32eff08` | `ML_KEM_randomized_decap_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `95d8c25e1e8f1043` | `ML_KEM_randomized_keygen_decap_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `ca7a7a483bc5484e` | `ML_DSA_randomized_sign_gen_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `3b5e08d6479f39e4` | `ML_DSA_randomized_zeroize_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `4a4602458ed5f899` | `ML_KEM_randomized_encap_input_fail_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `6d119902c4f3f7ef` | `ML_KEM_decaps_KATs_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b5faf8a7fcdfbca5` | `makehint_normal_test` | `authored-stimulus` | No M24 stock-firmware full-top launch path for this bench kind. |
| `d1de543aaafbea9b` | `ML_DSA_randomized_key_gen_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `b5c232bd3cdf1a9c` | `ML_DSA_randomized_verif_fail_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `f177d6ef512f191b` | `ML_DSA_randomized_verif_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `ea83927074a9018c` | `ML_KEM_randomized_decap_input_fail_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `cb3abb8aa50032f0` | `ML_KEM_randomized_keygen_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `04a5819b40e1d13b` | `ML_DSA_randomized_early_run_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `214c53ef5820276c` | `ML_DSA_randomized_two_verif_on_fail_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `641736234e134702` | `ML_KEM_randomized_encap_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `fab65f05429055a3` | `ML_DSA_randomized_all_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `5d14735d9c2a8135` | `ML_KEM_overwrite_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `634675b8d2de08f4` | `ML_DSA_randomized_h_decode_fail_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `466c238207a8a068` | `ML_DSA_randomized_key_gen_and_sign_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `1003763504b6ae5d` | `ML_DSA_keygen_KATs_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `885616c97bda0759` | `ML_KEM_encaps_KATs_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `5a0aa1ad1caef246` | `ML_DSA_randomized_KeySign_stream_msg_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `2dfaa83d0f397dd3` | `ML_DSA_keygen_signing_KATs_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |
| `349f38498654d5a6` | `ML_DSA_randomized_reset_test` | `generated-uvmf` | No M24 stock-firmware full-top launch path for this bench kind. |

M23 row 144 `smoke_test_sha3_interrupts` is no longer waitlisted: M24 passes it after mapping the plural matrix name to the singular firmware directory `smoke_test_sha3_interrupt`.
