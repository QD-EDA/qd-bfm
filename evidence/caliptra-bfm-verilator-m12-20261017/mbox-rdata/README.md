# M12 MBOX RDATA sampling overlay

Draft 2's one-row gate targets `smoke_test_mbox` (`78bfcc1e9aac255e`). Its c339 result is PASS, but the M11 Verilator run failed earlier at `AXI_SUB_AR_HSHAKE_ERR`, before a returned RDATA value. The separate job 1784 trace observed the read-to-set race: the accepted edge sample saw RDATA 0 while the post-update value was 1.

The candidate starts from the pinned M10b AXI overlay (`d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`) and changes only `get_read_beat`: under Verilator it samples RVALID, RDATA, RUSER, and RRESP from a `#1step` clocking block, while the non-Verilator macros retain the existing posedge/live-signal behavior. The generator checks the base overlay hash and exact macro, task, and cleanup anchors. Generated candidate SHA-256: `87cbd4cab95047e619a9a96c8927baf471c7ea910ac95730d891a2bf81b5684d`.

The candidate passed its generator self-check and exact-diff review. Build job 2132 completed; full-timeout gate 2133 failed at `AXI_SUB_W_HSHAKE_ERR` at 5,716 ns before reaching the R channel (`sim_scan.bad=2`, simulation 38.771 s). Thus this run does not validate the RDATA sampling change, and the row remains FAIL; no affected-row array is submitted. The checksummed bundle is under `generated/gate-2133/`. No AXI assertion is suppressed and no pass criterion changes.

The pinned QD-BFM source archive and common filelist, AXI, and case-runner helpers are reused from the sibling `strap-guard/` evidence to avoid duplicate source snapshots. They are copied into the isolated Slurm run directory when this gate is staged.

## Gate selection

| Row | c339 baseline | Verilator baseline | Candidate gate |
| --- | --- | --- | --- |
| `78bfcc1e9aac255e` | PASS | M11 FAIL at AR handshake, before RDATA | Gate 2133 FAIL at W handshake, before RDATA; candidate unvalidated, retain FAIL. |

`gate-selection.tsv` records the row identity, c339 outcome, and original timeout. The full affected-row rerun and 162-row comparison remain part of M12.
