## Draft: MBOX read-to-set response is sampled after the edge update

**Status:** Local draft for user review only; not posted. This draft covers only the verified RDATA sampling race. The separate unexplained ARVALID-drop diagnostic is recorded in [a separate note](mbox-arvalid-drop-unexplained.md).

## Reproduction and observation

On pinned Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, the logging-only Verilator 5.052 run for `smoke_test_mbox` observed the first lock read at CSR cycle 56915 with stored value 0 and readback 0, followed by the software-set-on-read update to 1. At AXI posedge cycle 56942, the active-region sample saw `RVALID=1`, `RREADY=1`, and `RDATA=0`; the same-edge post-update sample saw `RDATA=1`, and the BFM returned 1. The preceding negedge also had data 0.

The pinned `get_read_beat` waits on `@(posedge clk)` and then reads live `rdata`, so its active-region scheduling can observe the later update instead of the accepted beat. The Icarus one-poll result is consistent with capturing the pre-update value. This is a BFM sampling race at the read-to-set handoff, not evidence of an RTL functional failure. See the [job 1784 trace record](../../../caliptra-bfm-verilator-m10b-20261016/diagnostics/mbox-lock-trace/job-1784/README.md). That logging-only run hit its separate 180-second outer cap and is diagnostic evidence, not an official test result.

The M11 official row `78bfcc1e9aac255e` also failed under the M10b overlay, but earlier at `AXI_SUB_AR_HSHAKE_ERR` before a returned RDATA value. That separate ARVALID-drop remains unresolved; the RDATA sampling fix alone cannot be counted as covering the official row.

The M12 candidate gate (job 2133) also fails the official row, this time at `AXI_SUB_W_HSHAKE_ERR` before any RDATA sample; `sim_scan.bad=2`. The candidate is therefore not validated against the official row and no wider rerun was launched. These earlier AW/W-channel failures remain separate from the RDATA race reproduced by the focused trace. This draft remains local and has not been posted.

## Expected behavior

Capture RDATA from the same edge sample that qualifies `RVALID && RREADY`, before same-slot RTL updates can change it.
