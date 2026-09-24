# QD-BFM v0 scope

Build one executable, protocol-aware open-source bus functional model useful to replace a missing Caliptra proprietary VIP dependency for bounded directed tests. It does not replace UVMF/QVIP/Avery verification or prove full DV qualification.

First inspect the pinned Caliptra v2.1.2 source at /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl (read-only) and identify the simplest actual externally driven bus (AHB-Lite or AXI-Lite/AXI4). Select ONE protocol and direction for v0; record the release interface/ports and protocol source in README. Implement a standalone SystemVerilog BFM with read/write transactions, reset, valid/ready or HREADY stalls, error response, timeout, and explicit protocol assertions. For AXI, do not claim full AXI4 if only AXI-Lite is implemented. Ensure no checker is an empty stub and no pass banner can appear after a protocol error.

Provide an independent tiny DUT/testbench that runs on installed Icarus or Verilator, with positive, stall, error, and timeout/negative cases. Optional Caliptra hookup only if it works without modifying pinned application sources; keep adapters/examples in this repo. No proprietary code or pasted Caliptra testbench. Add README, Apache-2.0 license, and test command. Own only this repo; no commit/push/remote creation.

## Reset-cancellation slice

Cancel active tasks on reset at every blocking wait, including stopped-clock,
startup, response-timeout and post-handshake cleanup windows. Clear request VALID
and response READY outputs asynchronously. Require a released-reset rising edge
before launching a new transaction. Preserve successful transfers, error responses
and request-timeout VALID retention; reset the target before reuse after timeout.
Independent target/monitor tests must reject held/early VALID and prove successful
post-reset recovery. Qualify only the documented directed configuration; four-state
controls and real application integration remain separate roadmap work.

## Active four-state response policy

Reject X/Z on READY while waiting for a request handshake and VALID while
waiting for a response. At an accepted response, require known response code,
matching known ID and (on reads) asserted RLAST. Require known read data only
on an OKAY response; error-response data is not a usable result. Idle response
payloads may be unknown. Fatal diagnostics must identify the affected signal;
unknowns must not silently become timeouts or an unknown task success value.
Exercise X and Z independently on Icarus, preserve reset/timeout behavior, and
require the testbench's own checks to reject unknown conditions. This is an
active-task check, not a complete passive AXI or four-state monitor.

## Pinned Caliptra interface pilot

Connect the existing BFM to unmodified v2.1.2 `axi_if.w_mgr/r_mgr`. Preserve the
task API at `adapter.driver`, reject mismatched widths, tie request user/lock
to zero and document ignored response metadata. Verify pin mapping, strobes,
response codes, ID extremes and stalls with an independent local target and
seeded bad-ID/width failures. Compile real sources from a clean pinned checkout;
preserve every diagnostic and return UNKNOWN for warning-bearing configurations.
Do not count this local target as actual Caliptra subordinate verification or
claim that Verilator's upstream dummy assertion selection enables checkers.

## Actual AXI subordinate integration slice

Exercise the unchanged pinned Caliptra axi_sub and its native filelist with the
existing QD adapter. Put only the component model and independent expected-data
scoreboard in QD-owned code. Test strobes, IDs, backpressure, component errors,
quiescent reset/recovery and a fault in the QD model. Preserve assertion-enabled
compile failures as a separate lane from upstream-default observational behavior;
neither a default-lane pass nor -Wno-fatal may conceal diagnostics or unavailable
assertions. Archive commands, input hashes, statuses and timing. No general AXI,
full-chip or UVM qualification is implied by this pilot.

## Four-state task input boundary

Reject unknown read/write address and ID, unknown write strobes, and unknown
bits of enabled write-data bytes before any request is driven. Preserve masked
byte and zero-strobe don't-care behavior. Require exact fatal diagnostics and an
independent monitor proving invalid arguments never reach request pins. Preserve
all prior transaction/reset/response tests and the real Caliptra pilot outcomes.

## Directed response-backpressure slice

Add a nonnegative known integer RESPONSE_DELAY, default zero, to both manager
modules. Keep response READY low for that many cycles after request cleanup,
then start the existing TIMEOUT wait. Cancel at either edge on reset. Check
stalled response VALID and payload stability through the accepting edge, with
case equality for four-state transitions. Reject unknown VALID during the active
delay; preserve stable unknown error-read data. Keep all previous regressions.
Use independent target stall counters, seeded violations and reset/recovery
checks. Exercise default and delayed configurations on unchanged pinned Caliptra
axi_sub, retaining warnings and unavailable assertions as UNKNOWN.

## Reproducible Linux evidence lane

Build immutable Icarus/Verilator commits, preserve the existing smoke job, and
run the full standalone suite plus clean pinned Caliptra axi_sub at response
delays 0/7. Archive raw failures and UNKNOWN status. Require the exact reviewed
diagnostic set and behavioral/fault evidence; unexpected drift fails CI. Record
source/tool/input hashes and host/package versions. Exercise evidence-check
failures by corrupting copies of artifacts, never application RTL/DV.

## Single-beat USER metadata slice

Add explicit AWUSER/WUSER and ARUSER task variants without changing existing
zero-user call signatures or response semantics. Reject unknown USER arguments
before launch. Keep each USER stable while its channel is stalled. Verify pins
against an independent local target and component USER on the unchanged pinned
Caliptra `axi_sub`; inject a QD-owned wrong-user expectation. Preserve the
assertion-enabled failure and width warnings as UNKNOWN. Lint the named
`soc_ifc_axi_sha_acc_dis_tb` fileset without claiming runtime access-policy
verification.
