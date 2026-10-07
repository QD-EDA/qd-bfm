# Directed AXI reset evidence — 2026-09-23

Baseline: `75d0951777b88281715000f2ffbdca00278e0e88` (roadmap branch).
Inspection found that reset cleared only the BFM's internal stall history:
manager output handshakes remained asserted, and transaction tasks only waited
on clock edges. The first new regression failed at `reset did not clear manager
outputs`, before the implementation changed. Original `./run.sh` cases passed
before modification and remain required, unchanged.

The implementation clears all five driven handshake pins asynchronously and
adds reset to each blocking event control. Startup waits for released-reset clock
observation before driving. The AXI size assignments use an explicit 3-bit cast
with a checked width range; this fixes real WIDTHTRUNC diagnostics encountered
in Verilator compilation, without disabling warnings.

## Contract and oracle

[ARM IHI 0022H](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf),
§A3.1.2 (A3-40), requires request VALID to be low during reset, permits asynchronous
assertion, and requires clock-synchronous release with a subsequent permitted
launch edge. READY-low and immediate task cancellation are the BFM's additional
API contract. The simulation driver uses falling-edge launches after rising-edge
reset observation; this avoids active-region handshake races in the named harness.
It is not a physical interface timing implementation.

`tb_reset.sv` uses an independently written target that records only rising-edge
handshakes, stores bytes selected by strobes, and generates responses from its
own accepted-request state. It does not inspect BFM task internals. Monitors check
idle outputs during reset and prevent request launch before reset-clock observation.
Deliberately forcing held/early VALID in this QD fixture must fail. No application
RTL/DV was changed and no licensed checker was replaced by a stub.

## Regression matrix

Each of these 15 phases runs with a running and a stopped clock (30 total):

| Phase | Interrupted operation |
|---:|---|
| 0 | stalled AW |
| 1 | accepted AW, before falling-edge cleanup |
| 2 | stalled W |
| 3 | waiting for B |
| 4 | stalled AR |
| 5 | accepted AR, before falling-edge cleanup |
| 6 | waiting for R |
| 7 | accepted R, before completion |
| 8 | accepted B, before completion |
| 9–10 | write startup before/after first rising edge |
| 11–12 | read startup before/after first rising edge |
| 13–14 | B/R timeout cleanup before falling edge |

Every case checks prompt `ok=0`, idle outputs, then a successful write/read after
shared reset. A watchdog makes lack of progress fail. A separate address-timeout
case checks VALID retention followed by reset clearing and reuse. Parameters
DW=8/1024 are accepted; DW=0/7/24/2048 must fail, never print PASS. This does not
claim transaction verification at all accepted widths.

## Commands and observed results

Host: macOS arm64. Icarus/vvp 13.0 stable (`v13_0`), Verilator 5.050
(`2026-07-01 rev vUNKNOWN-built20260701`). Both simulators pass the reset matrix;
both reject the two forced monitor violations. The original Icarus transaction,
error, stall, timeout, bad RID and missing RLAST cases also pass. Verilator builds
without SystemVerilog warning suppressions. No four-state result is inferred
from Verilator's two-state execution.

From the QD-BFM repository root:

```sh
./run.sh
verilator --binary --timing --top-module tb_reset --timescale 1ns/1ps \
  --Mdir ../evidence/bfm-reset/obj qd_axi4_single_master.sv tb_reset.sv
../evidence/bfm-reset/obj/Vtb_reset
# Both commands below must fail with the respective monitor message, no PASS:
../evidence/bfm-reset/obj/Vtb_reset +BAD_RESET_VALID
../evidence/bfm-reset/obj/Vtb_reset +BAD_EARLY_VALID
```

The local `../evidence/bfm-reset/` bundle retains simulator logs and summary.json
with commands, versions and observed durations. The reset matrix simulates
3.66 microseconds; this is directed functional evidence, not throughput or
performance qualification. Logs are session artifacts, not hosted in this repo.

Still unknown: unknown protocol inputs/responses, overlapping task calls, bursts,
multiple outstanding IDs, a full passive protocol monitor, UVM integration,
real Caliptra register behavior, and chip-flow qualification. The pinned Caliptra
interface was inspected, but this reset test uses a local target, not Caliptra RTL.
The next pilot must wire the released interface and retain those scope boundaries.
