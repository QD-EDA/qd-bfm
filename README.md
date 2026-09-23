# QD-BFM

`qd_axi4_single_master.sv` is a small AXI4 manager BFM for bounded, directed, single-beat reads and writes. It targets the inbound SoC AXI subordinate interface in Caliptra RTL v2.1.2: `caliptra_top.sv` ports `s_axi_w_if` and `s_axi_r_if` (`axi_if.w_sub` / `axi_if.r_sub`), declared in `caliptra-rtl/src/axi/rtl/axi_if.sv`. That interface's widths come from integration parameters; the BFM defaults are `AW=32`, `DW=32`, `IW=8`, `TIMEOUT=16`.

It is a directed-test helper, not UVMF/QVIP/Avery verification, Caliptra DV qualification, or AXI protocol signoff. It does not implement bursts, multiple outstanding transactions, configurable user/lock signaling, or coverage. The default local test uses an independent tiny memory target and does not compile or modify Caliptra. An optional real-interface adapter pilot is described below.

## Requirements and quick start

Install Icarus Verilog (`iverilog` and `vvp`), then run:

```sh
./run.sh
```

The script compiles the BFM and local testbench, then runs the passing write/read, request-stall, error-response, and address-timeout cases. It also injects a bad read response ID and missing `RLAST`, requires each run to fail, and rejects any pass banner from those negative runs. Success prints `PASS` and exits `0`; a compile, simulation, or expectation failure exits nonzero.

## Using the BFM

Instantiate the module and connect its request/response pins to the manager side of the target interface (for Caliptra's inbound interface, to `s_axi_*_if`). Drive `clk` and active-low `rst_n`; tie unused interface user/lock fields low and ignore response user fields. Call `write_one(addr, data, strb, id, ok, resp)` or `read_one(addr, id, ok, data, resp)` from a testbench process. The address must be aligned to `DW/8` bytes and reset must be released. `ok` is true only for a successful response; `resp` carries the two-bit AXI response. `TIMEOUT` bounds each wait in clock cycles.

Requests remain asserted through ready stalls, with payload-stability checks. Response ID mismatch or a read without `RLAST` calls `$fatal`; AXI error responses return `ok=0`. On request-channel timeout, VALID remains asserted to preserve AXI handshake rules: reset both BFM and target before another transfer. Response timeout returns `ok=0` and deasserts response ready.

Licensed under Apache-2.0; see [LICENSE](LICENSE).

See [the staged qualification roadmap](ROADMAP.md) for named pilots, unsupported
cases, independent oracles, performance targets and release gates.

## Reset cancellation

Drive reset to both the BFM and target. Asynchronous reset assertion clears
`AWVALID`, `WVALID`, `ARVALID`, `BREADY` and `RREADY`, including requests left
asserted after timeout. A task interrupted at any blocking wait returns `ok=0`
without requiring another clock edge. A reset after task completion does not
retroactively cancel the completed transaction. Discard response/data outputs
when `ok` is not exactly 1. Reset does not undo a write already accepted by the
target; the target's own reset semantics govern committed state.

A new task waits for a rising edge with reset released and then launches on a
falling edge, away from target sampling. Deassert reset synchronously using the
harness's scheduled clocking convention (the regression uses a nonblocking
assignment at a rising edge). Do not invoke overlapping tasks or reuse the BFM
after any timeout until **both endpoints** have been reset. Task start now has
up to one and a half clock periods of setup latency; `TIMEOUT` still counts each channel's
handshake wait separately. This is a simulation BFM, not synthesizable RTL.

The supported data-width parameter is 8 through 1024 bits in power-of-two bytes,
matching the three-bit AXI size field. The read/write regression exercises DW=32;
DW=8/1024 are parameter-acceptance checks only. Other widths fail at initialization.

`./run.sh` now also runs an independent reset target/monitor: 30 reset cases,
including stopped clocks and accepted-handshake cleanup windows; reset after an
address timeout; and successful read/write recovery. Held-VALID and early-VALID
injections must fail without a pass banner. [Reset evidence](RESET_EVIDENCE.md)
records cross-simulator results and limits. Full four-state protocol monitoring, concurrent
transactions, response-backpressure coverage and Caliptra integration remain
unqualified; this change does not establish full AXI compliance.

## Unknown values during a transaction

An X/Z READY during a request wait or VALID during a response wait is fatal.
Accepted responses must have a known response code and matching ID; reads must
also assert RLAST, and an OKAY read must contain known data. Idle response
payloads and error-response read data may be unknown. These checks cover signals
sampled by active tasks; they do not check all interface activity. Task-entry validation is described
below and does not make this a full passive monitor. Do not use an unknown `ok` as success in a testbench:
require `ok === 1'b1`.

`./run.sh` adds 22 X/Z pin injections, two payload boundaries and two negative
checks of the testbench's own assertion helper. See
[four-state evidence](FOUR_STATE_EVIDENCE.md) for scope, commands and remaining gaps.

## Caliptra interface adapter (pilot remains UNKNOWN)

`qd_caliptra_axi_single_master.sv` connects `axi_if.w_mgr` and `axi_if.r_mgr`
from pinned Caliptra v2.1.2 to the existing BFM. Pass matching `AW/DW/IW`
parameters; both interfaces and the adapter must share clock and reset.
Call `adapter.driver.write_one(...)` / `adapter.driver.read_one(...)` with the
same arguments and reset/timeout contract as the standalone BFM. The `driver`
instance name is part of this task API. Width mismatches are fatal.

The adapter ties request user/lock fields to zero and ignores response user
metadata. It cannot express privileged/nonzero-user or exclusive accesses.
Do not call Caliptra's built-in manager tasks on the same interfaces or attach
another manager driver. Concurrent tasks remain unsupported.

```sh
./run_caliptra_interface.sh /path/to/clean/caliptra-rtl /tmp/qd-caliptra-evidence
```

The script requires SHA `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, archives
compiler diagnostics, and tests wiring against the actual interface declaration
with an independent local target. It returns 2 (`UNKNOWN`) on compiler warnings,
1 on build/test/input failure, and 0 only on a clean interface pilot. Verilator
5.050 currently produces three upstream width warnings; behavioral tests pass
but the pilot is **not clean**. Default CI still runs only `./run.sh`; its green
status does not cover this optional pilot. [Evidence and blockers](CALIPTRA_INTERFACE_EVIDENCE.md)
distinguish interface tests from actual Caliptra RTL/DV qualification.

## Actual Caliptra subordinate pilot

```sh
python3 run_caliptra_subordinate.py /path/to/clean/caliptra-rtl /tmp/qd-axi-sub-evidence
```

This compiles the pinned upstream `axi_sub.vf` and drives the real `axi_sub`
through the existing adapter. The QD component memory and scoreboard exercise
12 accepted transfers, two held component cycles per transfer, full/partial/zero
strobes, ID extremes, SLVERR reads/writes, quiescent reset/recovery, and a read-data
fault injection. Scope is AW/DW/UW=32, IW=8, EX_EN=0, C_LAT=0, one outstanding
aligned full-width single-beat access. It does not run soc_ifc or full-chip DV.

The runner archives separate assertion-enabled and upstream-default configurations.
On Verilator 5.050 the assertion-enabled build rejects five `eventually` properties;
only the default configuration simulates. Three upstream width warnings also remain.
Overall exit is 2 (UNKNOWN), never a fallback clean pass. Build/test/input failures
in the default lane exit 1. No upstream assertions or diagnostics are edited.
See [target evidence](CALIPTRA_SUBORDINATE_EVIDENCE.md) for precise coverage limits.

## Request argument checks

Before driving a request, both tasks reject X/Z addresses and IDs. Writes also
reject X/Z strobes and unknown bits in enabled data bytes. Disabled write bytes
may contain X/Z; zero-strobe writes may use wholly unknown data. Invalid fields
are fatal before any request is launched. Existing reset/alignment and timeout
contracts still apply. See [request argument evidence](REQUEST_ARGUMENT_EVIDENCE.md)
for the 12 negative cases, boundary tests and unchanged Caliptra pilot limits.
