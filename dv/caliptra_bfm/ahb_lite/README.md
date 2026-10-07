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
for the directed Icarus test. It covers 64-bit full-word and half-word lane
behavior, configured wait cycles, injected and out-of-window two-cycle ERROR
responses, and verifies that the checker and monitor remain clean while
counting 14 completed transfers, including two four-beat INCR bursts and six
accepted SEQ phases.

`tests/run_checker.sh` accepts a legal transfer and two-cycle ERROR response,
then checks ten negative controls against the expected checker error code:
unknown control, BUSY, excessive transfer size, misalignment, unstable
address/control, unstable write data, malformed ERROR completion, single-cycle
ERROR, orphan SEQ, and orphan ERROR.

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
and a UVM RAL frontdoor operation each write `1` to CSR `0x804` and read it
back; the monitor checks all four records and the profile checker must remain
clean. It passes in 2012, 2017, and 2023 modes with the local
Icarus `-uvm` fork and Accellera UVM 2020.3.1. This exercises the open UVM AHB
agent against a real Caliptra unit; the generated UVMF agent and full Caliptra
top remain outside this smoke.
The command, pinned inputs, tool hashes, source hashes, and three-edition result
are recorded in
[`evidence/caliptra-bfm-ecc-ahb-uvm-20261004`](../../../evidence/caliptra-bfm-ecc-ahb-uvm-20261004/README.md).

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
