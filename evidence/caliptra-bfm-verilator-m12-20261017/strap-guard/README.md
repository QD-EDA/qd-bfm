# M12 strap assertion guard

Draft 4's one-row gate for `smoke_test_dma_aes_kv` (`5fd86f6ad2b1e78a`, `smoke_test_dma_aes_kv_large.yml`) passed with the build-time SoC BFM guard overlay.

The baseline from M11 failed at 0.044 s, before firmware, with the deliberate high strap-size selection tripping `SS_STRAP_KEY_SIZE_LTE_64`. The overlay removes only the `ifndef VERILATOR` fence around the existing high-size assertion suppression. It leaves the selected range, assertion target, RTL, firmware, and pass criteria unchanged. The generated SoC BFM source hash is `839734b475a835ca622e4575524148ae6bc6cc1c9baa6f7d2ae0c2a6097ffd44`; generation checks the pinned source hash and exact replacement count.

## Gate result

| Row | Baseline | Overlay gate | Firmware result |
| --- | --- | --- | --- |
| `5fd86f6ad2b1e78a` | FAIL before firmware, 0.044 s | PASS, 42.14 s | `TESTCASE PASSED`, mcycle 60,405 |

The gate ran on DAN-DESKTOP under a 600 s outer cap using Verilator 5.052 (`--assert`, `CLP_ASSERT_ON`) and the M10b AXI overlay (`d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`). The generated model SHA-256 is `a216f601067e05a2b9c48e9b6587dda3904c57c29f59983b33ae55ffe3864ee6`. Build job 2097 completed in 108.20 s at 2,381,276 KiB peak RSS; gate job 2100 completed in 42.14 s at 55,456 KiB peak RSS. The recorded result also reports `sim_elapsed_s=39.631` (the wrapper wall time is 42.14 s).

## Evidence

- `gate-selection.tsv`: row identity and original 21,600 s per-test timeout.
- `generated/`: pinned source/build hashes, tool versions, filelist manifest, and run environment.
- `generated/gate-results/5fd86f6ad2b1e78a/`: result JSON, firmware and simulation logs, resources, and the remote SHA-256 manifest.
- `generated/logs/gate-2100.out` and `generated/resources/5fd86f6ad2b1e78a-2100.resource`: Slurm wrapper evidence.

This is a one-row portability gate; the full affected-row rerun and the 162-row comparison remain part of M12.
