# Active-task X/Z evidence

This slice checks the existing single-beat tasks, AW=32, DW=32, IW=8,
TIMEOUT=5 in `tb_axi4`. It is not Caliptra simulation or production qualification.
The base is `bdc365c2a76fe86e0f0167d085646b37f97d64dc` (reset-abort PR).

## Reproduced defect and policy

Forcing BRESP to X against the base BFM and base testbench produced exit 0 and
the normal PASS banner. `resp == 0` propagated X into `ok`; the testbench's
`if (!condition)` also accepted X. The shared task now rejects unknown response
codes, and the test helper requires a condition exactly equal to 1.

The active tasks reject unknown AWREADY/WREADY/ARREADY or BVALID/RVALID on a
sampled wait edge. At a response handshake, they reject unknown BRESP/RRESP;
existing exact-ID and RLAST checks remain. An OKAY read with unknown data is
fatal. Idle payloads and data from an error response may be unknown. This is
the BFM API's policy, not a claim of exhaustive AXI specification checking.

This work addresses a real interface expectation: pinned Caliptra v2.1.2
[`axi_sub_wr.sv`](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/src/axi/rtl/axi_sub_wr.sv#L371)
and [`axi_sub_rd.sv`](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/src/axi/rtl/axi_sub_rd.sv#L378)
contain known-value checks on protocol controls and active payloads. Our scope
is narrower, especially for inactive channels and error data. Those application
sources were read only; none were compiled, modified or asserted to pass here.

## Reproduction and results

Run from this repository:

```sh
./run.sh
iverilog -g2012 -s tb_four_state -o /tmp/qd-four-state.vvp \
  qd_axi4_single_master.sv tb_axi4.sv tb_four_state.sv
vvp /tmp/qd-four-state.vvp +SIGNAL=BRESP +X  # expected exit 1
vvp /tmp/qd-four-state.vvp +SIGNAL=RDATA +Z  # expected exit 1
vvp /tmp/qd-four-state.vvp +SIGNAL=IDLE_PAYLOAD  # expected exit 0
vvp /tmp/qd-four-state.vvp +SIGNAL=ERROR_RDATA   # expected exit 0
```

`run.sh` requires exit failure, the specific diagnostic and no PASS for each of
22 injections: X and Z independently on AWREADY, WREADY, ARREADY, BVALID, RVALID,
BRESP, RRESP, BID, RID, RLAST and RDATA. It also requires the injection marker,
so a test that never reached its injection cannot count. Two positive boundaries
cover unknown idle payloads and unknown SLVERR read data. Two additional negatives
prove that the test helper rejects X/Z conditions. The original transaction,
stall, error, timeout, reset and parameter checks still pass.

Icarus/vvp 13.0 stable (`v13_0`, Homebrew) is the four-state execution engine.
No warning suppression or diagnostic filtering was needed. The stimulus uses
packed text and fixed-width force values because Icarus crashed on a string
case expression and warned about force expression evaluation during test
development; final compilation is clean. Forced values remain constant.

Verilator 5.050 (`2026-07-01 rev vUNKNOWN-built20260701`) also compiled and passed
the existing 30-case reset regression with this change:

```sh
verilator --binary --timing --top-module tb_reset --timescale 1ns/1ps \
  --Mdir /tmp/qd-reset-obj qd_axi4_single_master.sv tb_reset.sv
/tmp/qd-reset-obj/Vtb_reset
```

That two-state run is portability evidence only, not an X/Z oracle. Five complete
Icarus suite runs took 0.564–0.646 s, median 0.604 s including compilation, on
macOS arm64 Darwin 27.0.0, Mac17,3, 24 GiB RAM. These are local measurements,
not the roadmap's Linux qualification performance result.

Raw logs, exact argv/status/timing, tool paths/hashes and source hashes are kept
locally in `../evidence/bfm-four-state/` with a SHA256SUMS file. They are not
published release evidence. The checked-in tests reproduce the checks.

## Remaining limits

No full passive monitor, unknown reset policy, exhaustive single-bit X/Z matrix,
unknown request-argument validation, concurrent tasks, bursts, coverage closure,
UVM lane, commercial four-state oracle, or actual Caliptra adapter/top simulation
is established. A matching unknown request/response ID is outside this slice;
request arguments must be known. Interface compilation and a real register
smoke remain necessary. All six-tool production release criteria remain open.
