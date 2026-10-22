# ML-DSA cast-failure rerun on refreshed Icarus

Array job 3055 runs 14 rows with the current-main Icarus binary and generated ML-DSA testbench/BFM compatibility overlay. The overlay changes only generated environment/predictor/scoreboard/setup sources; it does not alter RTL, firmware, or pass criteria.

## Completed wave 1

| Row | Test | Status | SHA-256 | Evidence |
|---:|---|---|---|---|
| 80 | `ML_DSA_verif_KATs_stream_msg_test` | TIMEOUT | `9ebf74f903403f42fba39b77a5b638907d12e163c99d925d24538ba831e01149` | `raw/job-3055_80.tar.gz` |
| 82 | `ML_DSA_verif_KATs_test` | TIMEOUT | `4822bbc4e9464415abee21ae47f9e2ba712c341e49032a1c03dcccfd9fec996c` | `raw/job-3055_82.tar.gz` |
| 86 | `ML_DSA_randomized_sign_gen_test` | TIMEOUT | `df949cf6fcc17f26ca85b31435103f22007bbc489567bafc8b69fba22d7d1abe` | `raw/job-3055_86.tar.gz` |
| 87 | `ML_DSA_randomized_zeroize_test` | TIMEOUT | `9ec55b2beb20865c6a0e816724a98775302bbfc82e55e2471a04519ccb08b304` | `raw/job-3055_87.tar.gz` |

Each archive SHA-256 matches its adjacent sidecar. All four compiles succeeded; VVP hit the 600-second per-row cap with no testcase marker. Row80 additionally logged one `UVM_ERROR` from `mldsa_predictor.svh:318` for an unhandled register write, then continued progress until timeout.

## Completed wave 2

| Row | Test | Status | SHA-256 | Evidence |
|---:|---|---|---|---|
| 91 | `ML_DSA_randomized_key_gen_test` | TIMEOUT | `ed747839c922a5155837907eae39c4adb0aac3901b4bc63874e0222a3ca521c1` | `raw/job-3055_91.tar.gz` |
| 92 | `ML_DSA_randomized_verif_fail_test` | TIMEOUT | `9578149f5ecc2d2d0ab458ed4f3f947104c657ac99cd59eea1e966da97684115` | `raw/job-3055_92.tar.gz` |
| 93 | `ML_DSA_randomized_verif_test` | TIMEOUT | `1f298623f882869ab268a4af41637c2e04635ac2d152509fdf067fa390c5622b` | `raw/job-3055_93.tar.gz` |
| 96 | `ML_DSA_randomized_early_run_test` | TIMEOUT | `c1d7f7d21f355167a66253b65d62e9087904d0bb09776c29078d1b86f7d935f4` | `raw/job-3055_96.tar.gz` |

Each archive SHA-256 matches its adjacent sidecar. These four compiles also succeeded; none reached a testcase verdict in 600 seconds. Rows 92 and 93 logged register-write progress near the final signature words, while row91 remained at the reset trigger; this is timeout evidence, not a pass.

## Completed wave 3

| Row | Test | Status | SHA-256 | Evidence |
|---:|---|---|---|---|
| 97 | `ML_DSA_randomized_two_verif_on_fail_test` | TIMEOUT | `0240acb66edf03a0ed120e8383ce33e82aa9966e299c757c899859f9da54f1c5` | `raw/job-3055_97.tar.gz` |
| 99 | `ML_DSA_randomized_all_test` | TIMEOUT | `f616354b6ce259a241ce30f12449e09294d52a4ed362c80690d34ff90d61b1d1` | `raw/job-3055_99.tar.gz` |
| 101 | `ML_DSA_randomized_h_decode_fail_test` | TIMEOUT | `a006457402b19668afd3b969f27cdf65fcdc4d5b8a2e5290d62066940824a961` | `raw/job-3055_101.tar.gz` |
| 102 | `ML_DSA_randomized_key_gen_and_sign_test` | TIMEOUT | `6e73067917b3bfdb02a61e5313cba42eee2c0eaa4d55b6b09f6c3e3c4205083c` | `raw/job-3055_102.tar.gz` |

Each archive SHA-256 matches its adjacent sidecar. All four compiles succeeded; VVP timed out at 600 seconds without testcase verdicts. These rows continue to later work only through a longer, separately identified row93 diagnostic; the initial timeout evidence remains preserved here.

## Completed wave 4

| Row | Test | Status | SHA-256 | Evidence |
|---:|---|---|---|---|
| 103 | `ML_DSA_keygen_KATs_test` | TIMEOUT | `795c8866a06d15dbadad29c33012874bee61b3d43b01c1408116fe022c34f12f` | `raw/job-3055_103.tar.gz` |
| 106 | `ML_DSA_keygen_signing_KATs_test` | TIMEOUT | `802e5853eb793f1070d63680b1572775096f627cfac0e41cbee398bff8094528` | `raw/job-3055_106.tar.gz` |

Both archives match their sidecars. Both compiles succeeded; VVP timed out at 600 seconds with no testcase verdict.

All 14 cast-failure rows now have current-main terminal evidence. The extended row93 run is separate and retains the initial timeout evidence here. See `submission.txt` for the pin and resources.
