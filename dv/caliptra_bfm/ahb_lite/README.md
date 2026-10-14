# Caliptra AHB-Lite BFM slice

This directory contains a native pin-level AHB-Lite manager, passive transfer
monitor, profile checker, and bounded memory subordinate. The current Caliptra
integration bus is 32-bit address and 64-bit data. No QVIP, UVMF, or WD source
is copied here.

## Manager

[`ahb_lite_caliptra_master.sv`](ahb_lite_caliptra_master.sv) provides serialized
`read_one`/`write_one` tasks and bounded `read_burst`/`write_burst` tasks. A
multi-beat request drives NONSEQ followed by SEQ address phases and terminates
with IDLE; the Caliptra interface omits HBURST. Burst length is limited to 256
beats. The manager holds address/control and write data through target wait
states, samples HRESP/HRDATA when HREADY completes each response, and withdraws
the next SEQ beat when an ERROR starts. It returns per-beat completion/error
status and packed read data. The caller supplies bus-lane-formatted write data
and interprets returned read lanes. Misaligned or over-width requests are
rejected before a transfer starts. A timeout, reset during a transfer, unknown
HREADY/HRESP, or malformed two-cycle ERROR response poisons the instance.
After the active task returns, hold reset low and call `reset_master` before
reuse.

The manager serializes requests and does not generate lock sequences or USER
sidebands. HSEL is asserted for NONSEQ/SEQ when directly
connected to one subordinate. On a multi-target Caliptra bus, ignore that
convenience output and let the interconnect decoder drive each responder's
HSEL. HREADY comes from the target/interconnect. For a direct single-target
connection, feed the subordinate's `HREADYOUT` back to both the manager's and
subordinate's `HREADY` inputs; in a multi-target system, use the interconnect's
global HREADY mux instead.

## Memory subordinate

[`ahb_lite_caliptra_memory_subordinate.sv`](ahb_lite_caliptra_memory_subordinate.sv)
models one byte-addressable SRAM window. It captures transfers only on HREADY,
applies byte/halfword/word/doubleword writes to the corresponding 64-bit data
lanes, holds responses through configured wait cycles, and returns the required
two-cycle AHB-Lite ERROR response for out-of-window, malformed, or injected
errors. Reset clears protocol state while preserving the initialized memory.
This is a bounded SRAM target; it does not implement mailbox/FIFO side effects,
Caliptra multi-region decode, or lock behavior.

## Monitor and checker

[`ahb_lite_caliptra_monitor.sv`](ahb_lite_caliptra_monitor.sv) reconstructs a
completed transaction from the pipelined address and data phases. It publishes
an address-accept pulse and a completion pulse with captured address/control,
data, and response fields, plus raw coverage counters for accepted reads,
writes, 1/2/4/8-byte transfers, pending non-ready cycles, and completed ERROR
responses. `address_count` and `transfer_count` provide the address and
completion denominators; these counters still work when simulator covergroups
are stubs. This is a procedural pin-level seam, not a UVM analysis port.

`../uvm/ahb_lite_caliptra_pin_monitor_adapter.sv` connects these raw pins to
`ahb_lite_caliptra_record_if`, including reset and wait-cycle counters. It uses
the 32-bit address and 64-bit data shape exposed by Caliptra's passive QVIP
monitor wiring in the integrated top and active QVIP configuration in the
isolated SoC-IFC top; it is exercised by the AHB UVM smoke. This is the
pin-to-record boundary; it does not recreate QVIP's generated HDL/HVL wrapper
or internal `uvm_config_db` setup.

Run `dv/caliptra_bfm/ahb_lite/tests/run_ahb_lite.sh` from the repository root
for the directed Icarus test in IEEE 2012 by default. With the multi-edition
Icarus fork, set `SV_EDITION=2017` or `SV_EDITION=2023` to select another mode.
It covers 64-bit full-word and half-word lane
behavior, configured wait cycles, injected and out-of-window two-cycle ERROR
responses, and verifies that the checker and monitor remain clean while
counting 15 completed transfers, including two four-beat INCR bursts, six
accepted SEQ phases, and a post-reset readback that checks SRAM retention. It
also resets the manager during address wait, data wait, and an in-flight burst;
each abort must idle the bus, keep the manager poisoned until reset recovery,
and allow a later read to complete.

The active UVM MVC path also has a guarded `+AHB_RESET_ABORT_ONLY` case. It
checks the command bridge's `response_aborted` status, suppresses publication
of the aborted request, then verifies post-reset traffic reaches all four
compatibility streams. See the [published-main reset-abort evidence](../../../evidence/caliptra-bfm-ahb-uvm-reset-abort-main-20261009/README.md).
Current-state update (2026-10-09): the standalone AHB and active UVM reset-abort
regressions also pass on the latest locally available `iverilog-uvm`
`origin/main` commit `197f9baece79e66d25524906fb7b54c9faa8f4e2`. The remote head
could not be refreshed due DNS failure; see the evidence's dated rerun section.

`tests/run_checker.sh` accepts a legal transfer and two-cycle ERROR response,
then checks 26 negative controls against the expected checker error code. These
include X and Z on HREADY, HRESP, HSEL, HTRANS, HWRITE, HSIZE, HADDR, and
write-phase HWDATA, plus BUSY, excessive transfer size, misalignment, unstable
address/control and write data, malformed or single-cycle ERROR responses,
orphan SEQ, and orphan ERROR. It accepts `SV_EDITION=2012` (default),
`2017`, or `2023` and rejects any other value before compilation.

`tests/run_caliptra_ecc_ahb_bfm.sh` connects the native 32-bit manager, profile
checker, and monitor to the actual pinned Caliptra `ecc_top` RTL. It writes and
reads back the ECC interrupt-enable CSR and checks for exactly two clean
monitor records. The run needs this repository's Icarus fork because stock
Icarus 13.0 does not parse several constructs in the pinned Caliptra RTL; set
`IVERILOG_BIN` and `VVP_BIN` to the fork's installed tools. Set `CALIPTRA_ROOT`
to select another pinned Caliptra checkout. `SV_EDITION` selects 2012 (the
default), 2017, or 2023 mode. This is an ECC unit-level RTL smoke, not a
generated UVMF environment or top-level Caliptra run.

`tests/run_caliptra_ecc_ahb_uvm_bfm.sh` runs the same 32-bit ECC counterparty
through the native UVM sequencer/driver and manager proxy. A direct sequence
writes and reads `1` at CSR `0x804`; a UVM RAL frontdoor operation then writes
and reads `0`. The monitor checks all four records and the profile checker
must remain clean. It passes in 2012, 2017, and 2023 modes with the local
Icarus `-uvm` fork and Accellera UVM 2020.3.1. This exercises the open UVM AHB
agent against a real Caliptra unit; the generated UVMF agent and full Caliptra
top remain outside this smoke.
Current-state update (2026-10-09): IEEE 2017 and 2023 reruns also pass with
the clean published Icarus main revision 4b3f3424c440aca6af92153b6860a7253b925234.
Both report four checked transfers and zero UVM warnings, errors, or fatals.
This is the latest published main revision available in the local cache; the
remote head could not be refreshed. See
[updated-main evidence](../../../evidence/caliptra-bfm-ecc-ahb-uvm-main-20261009/README.md).

The command, pinned inputs, tool hashes, source hashes, and three-edition result
are recorded in
[`evidence/caliptra-bfm-ecc-ahb-uvm-20261004`](../../../evidence/caliptra-bfm-ecc-ahb-uvm-20261004/README.md).

Current-state update (2026-10-10): the 26-case checker negative matrix and the
full standalone AHB regression both pass in IEEE 2012, 2017, and 2023 on clean
published Icarus `4b3f3424c440aca6af92153b6860a7253b925234`. The matrix injects
X and Z on each checked control/address/data input. The reset-abort test also
settles the combinational HSEL before checking it. See the
[published-main evidence](../../../evidence/caliptra-bfm-ahb-xz-published-20261010/README.md).

[`ahb_lite_caliptra_checker.sv`](ahb_lite_caliptra_checker.sv) checks control
and write-data stability through wait states, including the final HREADY-high
sample. It permits IDLE address changes before a valid transfer is presented
and master cancellation after an ERROR response. It also checks transfer
size/alignment, X-valued control signals, the Caliptra no-BUSY profile, SEQ
context, and the two-cycle ERROR response shape. These wait-state exceptions
follow [Arm IHI 0033B section 3.6.2](https://documentation-service.arm.com/static/5f91607cf86e16515cdc2a27).
HBURST is absent from Caliptra's reduced interface, so the checker can reject a
leading SEQ but cannot check a burst's declared length.
The monitor also marks malformed response sequences on its transaction record
and raises a sticky protocol-error indicator. These are subset checks, not a
QVIP or complete AMBA assertion-suite replacement.

The standalone memory subordinate and its synthetic-target UVM smoke do not
integrate with the Caliptra DUT. The two ECC runners above do exercise the
actual ECC unit RTL; neither uses the generated QVIP/UVMF environment. The
native UVM agent publishes `ahb_lite_caliptra_transaction` items through its
own analysis port. The UVM monitor also exposes clean-room compatibility streams for the
predictor, scoreboard, and coverage consumer keys. A thin
`ahb_lite_caliptra_qvip_compat_agent` presents them through the observed keyed
`ap[...]` shape and provides `m_sequencer`; details are in
[`../uvm/README.md`](../uvm/README.md). This covers observed fields, methods,
and analysis-port names only; it does not provide QVIP's subenvironment,
configuration, sequences, or coverage model and is not a full QVIP substitute.
The compatibility smoke exercises all three keyed streams with read, write,
wait-state, and ERROR traffic; it checks output object independence. The MVC
driver accepts up to 256 beats, and the monitor groups contiguous accepted SEQ
beats through the next IDLE/NONSEQ address boundary. HBURST is absent, so the
monitor infers item boundaries from accepted address phases. The UVM run checks
a four-beat write/read, first-beat abort, and a partial burst with one successful
beat followed by ERROR; unissued beats stay intact in the request. The generated-
name QVIP smoke checks full bursts through active and passive keyed streams.
The native sequencer transfer implements field-complete UVM copy/compare and
printing; its agent regression clones a populated request/response item and
checks that address and write-data mutations compare unequal.

Current-state update (2026-10-10): the ECC UVM smoke now connects the
monitor's burst stream to `ahb_reg_predictor` with RAL auto-prediction disabled.
It checks a direct sequence's `0 -> 1` mirror update and a later RAL frontdoor
`1 -> 0` update against the actual ECC RTL. The four monitored records pass
under IEEE 2012, 2017, and 2023 with zero UVM warnings, errors, or fatals; logs
and tool provenance are in the
[published-main rerun evidence](../../../evidence/caliptra-bfm-ecc-ahb-uvm-main-20261009/README.md#current-state-rerun-monitor-driven-ral-prediction-2026-10-10).

Current-state update (2026-10-10):
`tests/run_caliptra_hmac_ahb_bfm.sh` drives the native 32-bit AHB manager,
checker, and monitor against the pinned `hmac_ctrl` RTL. It writes a fixed
SHA-512 key/block/seed vector, reads and compares the complete 512-bit tag,
and checks idle/no-error status. The 172-transfer known-answer smoke passes
under IEEE 2012, 2017, and 2023 on clean published Icarus
`4b3f3424c440aca6af92153b6860a7253b925234`; see the [dated evidence](../../../evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/README.md).
This is direct unit-level RTL coverage, not generated UVMF or full-top
qualification.

The same HMAC known-answer case also runs through the native UVM
`ahb_lite_caliptra_agent` sequencer, driver, and monitor using
`tests/run_caliptra_hmac_ahb_uvm_bfm.sh`. All 172 checked transfers and the
512-bit digest pass under IEEE 2012, 2017, and 2023 with zero UVM warnings,
errors, or fatals. This adds native UVM-agent integration coverage; generated
UVMF and full-top qualification remain open. See the [dated evidence](../../../evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/README.md#current-state-rerun-through-the-native-uvm-agent-2026-10-10).
Current-state update (2026-10-10): the native UVM HMAC sequence now runs both
SHA-384 and SHA-512 known-answer cases through the same agent. All 344 bus
transfers and both full tag comparisons pass in IEEE 2012, 2017, and 2023;
see the [current results](../../../evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/README.md#current-state-sha-384-and-sha-512-uvm-rerun-2026-10-10).
The same sequence now checks a SHA-512 two-block `INIT`/`NEXT` digest as well;
the combined three-case run observes 612 transfers and passes in all three
editions ([current evidence](../../../evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/README.md#current-state-multi-block-continuation-rerun-2026-10-10)).
Current-state update (2026-10-10): the HMAC UVM test now connects the native
agent's completed-transfer stream to `ahb_reg_predictor` with RAL auto-predict
disabled. Its smoke map covers the 78 CSR words exercised by the three KATs;
the test checks that the observed final CTRL write updates the mirror. All 612
transfers pass in IEEE 2012, 2017, and 2023 with zero UVM warnings, errors, or
fatals. This checks monitor-driven prediction, not generated HMAC RAL or RAL
frontdoor coverage. See the [dated rerun evidence](../../../evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/README.md#current-state-monitor-driven-hmac-ral-prediction-2026-10-10).
Current-state update (2026-10-10): the native HMAC UVM test now also uses the
native RAL adapter for frontdoor access to the actual controller: it writes
key word 0, reads status, and writes CTRL zeroize. With RAL auto-prediction
disabled, the monitor predictor updates the corresponding mirrors. The full
KAT plus these three RAL operations passes in IEEE 2012, 2017, and 2023 with
615 transfers and zero UVM warnings, errors, or fatals. See the [frontdoor
evidence](../../../evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/README.md#current-state-native-agent-ral-frontdoor-2026-10-10).

`tests/run_caliptra_ahb_native_ral.sh` exercises the native AHB agent and RAL
adapter against the open memory subordinate in both 32-bit and 64-bit bus
profiles. It performs byte and halfword frontdoor write/read pairs, verifies
monitor-driven prediction with auto-prediction disabled, and injects one
target ERROR to check `UVM_NOT_OK`. All six bus-width/IEEE-edition runs pass;
the expected failed-read predictor skip emits one UVM warning per run. This
validates the generic AHB BFM path against its memory target, not narrow writes
to a Caliptra peripheral. See the [six-run evidence](../../../evidence/caliptra-bfm-ahb-native-ral-published-20261010/README.md).

2026-10-10 latest published-main follow-up: the 615-transfer native UVM AHB
HMAC SHA-384/SHA-512 and multi-block `INIT`/`NEXT` known-answer run also passes
under IEEE 2017 on Icarus `127b887dfdc09283ab0187a2e618421dee3d5dcc`, with
zero UVM warnings/errors/fatals. See the [dated rerun](../../../evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/README.md#latest-published-main-recheck--2026-10-10).
