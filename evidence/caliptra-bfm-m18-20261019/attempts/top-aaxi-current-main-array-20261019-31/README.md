# M18 AAXI / SoC-IFC rows 1–4, 43–45 — INVALID STAGING (array job 3028)

Current-main rerun of the seven remaining top-level AAXI and SoC-IFC environments after the row 0 gate. Each task uses the refreshed Icarus pin, open-AHB/AAXI compatibility, and `avery_defines.svh`; 4 tasks run concurrently, one CPU and 4 GiB each. The overlay changes only testbench/BFM/filelist setup; RTL, firmware, and pass criteria are unchanged.

The row 0 local gate already reaches current-main RTL and identifies a fixed-array wildcard-bin blocker at `soc_ifc_reg_covergroups.svh:2055`; these runs record each requested row separately.

Runner suite: 80 tests passed. Source snapshot SHA-256: `1f920533b1d4385de8c205e7011cfc576aab0ed5dd2fc94700e9ec2b89ca26d1`.

Array job 3028 was submitted with a 4-task throttle while the two KeyVault rows finish; the combined number of A2 tasks is capped at six. Source and script hashes passed remote preflight.

The seven archived rows terminated before compile because the staged source omitted `axi4_caliptra_dma_if_subordinate.sv`, required by `caliptra_bfm_aaxi_compat.f`. These are staging failures, not row results; they are excluded from the M18 matrix and rerun in attempt 32 with the missing source included.
