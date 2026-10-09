# Caliptra BFM / UVMF recreation plan — 2026-10-03

**Status: active implementation.** This branch carries the Apache-licensed
QD-BFM single-beat AXI seed, a Caliptra-profile AXI checker, a burst-capable
AXI manager that permits one read and one write concurrently, a single-window
AXI SRAM subordinate, and passive AXI handshake and bounded completed-record
monitors. Directed regressions now exercise one simultaneous read/write pair
and two queued IDs per direction, including response backpressure. The recovery policy,
stream-FIFO subordinate, DMA SRAM/FIFO map, and generated recovery sequence
pass focused standalone Icarus tests, including autonomous FIFO push/pop. The
native AHB-Lite slice has a serialized manager, passive transfer monitor,
profile checker, and bounded memory subordinate; its directed read/write,
wait, and ERROR response test
passes, and eleven injected protocol violations are rejected with the expected
checker codes while a legal two-cycle ERROR response is accepted. A separate
four-beat INCR extension drives NONSEQ/SEQ through the MVC command path; its
monitor groups bounded queue items, preserves native per-beat records, and
passes synthetic-target read/write, first-beat abort, and partial-burst ERROR
smokes. The
generated PV `pv_rand_wr_rd_test` also reruns successfully through the updated
AHB adapter/predictor under the documented Icarus overlay. These checks do not
qualify the full Caliptra top. A separate
32-bit native manager/checker/monitor smoke and native UVM
sequencer/driver/monitor smoke now write and read the ECC interrupt-enable CSR
against the pinned Caliptra `ecc_top` RTL in 2012, 2017, and 2023 modes. The
actual `axi_dma_top` completes a seeded 65-word SRAM transfer from Caliptra's
own DMA randomizer through the recreated target and passive UVM monitor; a
second run injects AXI `SLVERR` and checks the DMA error state after a partial
destination write. A third DUT run moves 65 auto-generated FIFO words to SRAM
in five 64-byte recovery-sized bursts, using the real `recovery_data_avail`
input and one packed generated block-size entry. This recovery tuple is
directed because Icarus rejected it under the pinned class constraints. These
are unit/block-level DUT checks, not
full-top or generated-UVMF qualification. Separately, the real
`dma_testcase_generator` defaults to 25 testcase records, which are staged into
a bounded DCCM shadow; the DUT replay requests 29 to add FIFO-destination and
AXI2AXI, AXI2MBOX, and AXI2AHB recovery profiles. It also drives multiple
generated block-size entries through the open recovery sequencer under Icarus.
The actual-DUT runner now selects and replays all 29 records through
`axi_dma_top`, checking stored payload ECC and the full read/write data path.
For this DUT lane, a hash-guarded overlay selects among
all five named DMA routes, eight short sizes (1, 4, 5, 16, 64, 65, 255, and
256 words), a 16,384-word maximum checked SRAM payload on AXI2AXI, a maximum
65,536-word fixed-read FIFO-to-SRAM stream, generated fixed-write SRAM-to-FIFO
records at eight sizes, and 65-word FIFO recovery records for AXI2AXI,
AXI2MBOX, and AXI2AHB. Generated recovery sweeps cover every legal one-hot
block size for each route: 4–64 bytes on AXI2AXI and 4–2048 bytes on AXI2MBOX
and AXI2AHB. Short records retain per-record randomized payloads, route-valid
offsets, and Caliptra's randomized delay flag. One record observed five
target-stall cycles; the generated 65-word FIFO-destination record observed
160. Other generated FIFO mode/flag combinations and firmware-triggered reset injection remain
unqualified. Three non-recovery FIFO-source records also complete 65-word
AXI2AXI-to-SRAM, AXI2MBOX, and AXI2AHB transfers through the actual DMA DUT;
the UVM bench checks FIFO drain, route payload, and randomized stalls. See the
[`generated FIFO-source route evidence`](../../evidence/caliptra-bfm-dma-fifo-source-routes-20261007/README.md).
Generated FIFO-source AXI2AXI, AXI2MBOX, and AXI2AHB transfers now pass at 1,
4, 5, 16, 64, 65, 255, and 256 words through the actual DUT, checking FIFO
drain, route payload, and randomized stalls; see the
[`FIFO-source size-sweep evidence`](../../evidence/caliptra-bfm-dma-fifo-source-size-sweep-20261007/README.md).
Generated SRAM-to-FIFO AXI2AXI transfers now also pass at all eight sizes,
checking every queued payload word and randomized backpressure; see the
[`FIFO-destination size-sweep evidence`](../../evidence/caliptra-bfm-dma-fifo-destination-size-sweep-20261007/README.md).
The actual generated AXI2AXI recovery record also passes through
the real DMA DUT with not-empty, threshold, and pulse `recovery_data_avail`
policies. A separate 32-record generated replay adds 65-word SRAM FIXED-read,
FIXED-write, and both-FIXED AXI2AXI profiles, with the scoreboard checking the
repeated address behavior and final SRAM contents. Directed DUT runs
cover all five named DMA routes in a directed/constrained 65-word profile:
AXI2MBOX and MBOX2AXI with one-cycle mailbox backpressure, AHB2AXI through the
component `WRITE_DATA` register, and AXI2AHB through `READ_DATA`. The AHB lanes
are block-level register-side checks, not a full AHB bus test. A separate
65-word AXI2AXI profile also writes from SRAM to the AXI FIFO in fixed bursts
under weighted channel stalls and checks the observed backpressure and queued
payload. Other transfer sizes/flags, firmware, and full-top execution remain
open. See the
[`Earlier 25-record DMA DUT replay evidence`](../../evidence/caliptra-bfm-dma-generator-dut-replay-20261006/README.md).
The generated FIFO-destination follow-up is recorded in
[`generated FIFO-destination evidence`](../../evidence/caliptra-bfm-dma-generated-fifo-destination-20261006/README.md).
The generated recovery block-size case is recorded in
[`generated recovery evidence`](../../evidence/caliptra-bfm-dma-generated-recovery-block-20261006/README.md).
The AXI2MBOX/AXI2AHB generated recovery sweeps are recorded in
[`routed recovery evidence`](../../evidence/caliptra-bfm-dma-routed-recovery-sweep-20261006/README.md).
The directed routes are recorded in
[`all-route DUT evidence`](../../evidence/caliptra-bfm-dma-all-routes-20261006/README.md).
Full-suite qualification across generated UVMF environments and licensed
agent APIs also remains open.
The actual Caliptra `soc_ifc_top` now completes a four-word DMA copy programmed
by the open AHB manager, through the open target under Icarus 2012, 2017, and
2023. The test checks both AXI bursts, each payload/response/last marker,
destination SRAM contents, and the final DMA status read over AHB; a second
injected-`SLVERR` run confirms the actual `soc_ifc_top` reports `DMA_ERROR`
through `STATUS0`. Separately,
the generated SoC-IFC `hdl_top`'s tied-off DMA manager port has a hash-guarded
disposable overlay that connects the target through Caliptra's `axi_if`
modports, and the typed 256-beat interface smoke passes. A separate static
compile now elaborates the actual generated SoC-IFC `hdl_top`, real
`soc_ifc_top` RTL, seven generated interface/driver/monitor BFM sets, and the
open AHB/AAXI sources using hash-guarded disposable source overlays and
compile-only proxy class surfaces. This HDL-top compile is separate from the
bounded generated-environment runtime described below. See the
[`SoC-IFC AHB-to-DMA runtime evidence`](../../evidence/caliptra-bfm-soc-ifc-dma-runtime-20261004/README.md) and
[`SoC-IFC open DMA target overlay`](../../evidence/caliptra-bfm-soc-ifc-axi-target-20261004/README.md), and
[`generated SoC-IFC HDL-top compile`](../../evidence/caliptra-bfm-soc-ifc-generated-hdl-20261004/README.md).

The generated SoC-IFC runtime probe uses the generated bench sequence, starts
the generated responders, and performs AAXI traffic through the actual top. Its
default lane checks a write/read at `0x30048`; the opt-in open-mailbox lane also
checks four host-written words in the attached SRAM target. Both currently
pass with zero UVM errors or fatals. An opt-in `--generated-axi-user-init`
lane now also runs Caliptra's stock generated RAL sequence: five MBOX valid-user
writes, five MBOX lock writes, and the TRNG valid-user and lock writes. The
completed AAXI monitor checks all 12 mapped addresses, data values, strobes,
and reset-derived AWUSER; the SoC-IFC scoreboard reports 18 matches and zero
mismatches. The CPTRA reset/key status and default AXI scoreboards match. The
optional `--generated-ahb-ral-read` path reads the mailbox lock through the
generated AHB RAL map and returns its initial unlocked value, zero; the
Caliptra CSR sets the lock bit on read, so the probe schedules this access
after mailbox traffic. The AHB predictor and scoreboard complete without UVM
errors or fatals. The combined guarded run has 70% free
memory at preflight and its minimum. The disposable Icarus adaptations connect
the default reset pulse, correct the packed security-state input net, set
deterministic debug-locked production state, normalize generated AHB transfer
types, and align initial monitor/predictor startup. This covers the exercised
generated reset/power-on, stock AXI USER RAL sequence, generated AHB mailbox
claim plus MBOX_DLEN write/readback, and four-word mailbox path, not all
generated sequences or the full Caliptra top. The AHB write/readback lane reads
`MBOX_LOCK` first because that read claims the mailbox; writing MBOX_DLEN before
the claim is ignored. Its combined run reports 21 matches, zero mismatches, and
zero UVM errors/fatals. The generated AHB RAL path also sends a four-word
mailbox request through command, length, DATAIN, and execute, then checks the
open SRAM target. Its scoreboard reports 15/15 matches; single-bit injection
passes on the same path. Post-lifecycle no-injection and single-bit runs report
16/16 matches; the double-bit run reports 17/17 matches. All three check the
first mailbox word against the expected data for its ECC mode and confirm the
other three words remain unchanged. No dropped sequencer responses remain
during traffic. The retained payload-only logs predate explicit responder
shutdown and include four parent-process warnings at test teardown; the full
roundtrip below now stops those sequences explicitly.
The combined stock AXI USER initialization and double-bit AHB payload run
reports 29/29 matches with zero mismatches, no-comparison items, missed items,
UVM errors, or fatals.

The generated AHB/AAXI BFM now completes the mailbox response leg: the AAXI
host reads command, length, and four DATAOUT words, writes `CMD_COMPLETE`, and
the AHB sequence reads status and clears execute. The no-ECC and
single-bit ECC runs each report 26/26 scoreboard matches with zero UVM errors
or fatals. The double-bit ECC run reports 27/27 matches with zero errors or
fatals. Its disposable runtime predictor overlay only predicts an interrupt
status transaction when the non-fatal output rises, avoiding a duplicate
expectation when a second corrupt word is read while the interrupt is already
asserted.
The complete roundtrip also passes with the stock AXI USER initialization
sequence enabled. The generated host uses MBOX valid-user slot 0 for the
response reads and status write; no-ECC and single-bit ECC score 38/38, and
double-bit ECC scores 39/39, with zero UVM errors or fatals. This verifies the
configured-user path. A new combined probe also sends a mailbox-lock read with
an unlisted `ARUSER`, observes SLVERR, then confirms the following AHB mailbox
claim still reads the initial unlocked value. Its complete four-word
AHB/AAXI handshake reports 39/39 scoreboard matches, zero errors/fatals, and
74% minimum free memory against the 60% guard floor. Explicit responder
shutdown removes the four `SEQPRTZMB` teardown warnings in each current run;
three coverage/RAL warnings remain.
The AAXI compatibility comparator uses `beatQ` for read response data and
checks its legacy scalar `data` field only on writes.
See the
[`SoC-IFC generated-runtime evidence`](../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md).

A bounded pin-level mailbox SRAM subordinate is now in the open BFM set. Its
focused run against Caliptra's actual `soc_ifc_pkg` checks a 16-word instance
for registered reads/writes, reset retention, bounds, deterministic XOR masks,
and single-/double-bit ECC injection, then checks first/last-word access on a
second instance at the full 65,536-word Caliptra depth. The guarded run observed
74% minimum free memory against the 60% floor. A hash-guarded opt-in generated `hdl_top`
overlay connects the target to the real mailbox SRAM request/response pins and
mirrors live ECC injection settings from the generated driver. The target now
lazily supplies zero for unwritten words using a packed initialized-word
bitmap; the focused component regression passes with this version. The
generated-environment probe now reads mailbox lock state, writes a 16-byte
command through `MBOX_CMD`, `MBOX_DLEN`, four `MBOX_DATAIN` writes, and
`MBOX_EXECUTE`, then checks all four words in the connected SRAM target. The
generated AAXI monitor verifies the CSR transfers; the run completes with zero
UVM errors and fatals. This qualifies the generated environment's four-word
host-to-SRAM path. The full command/status response handshake now also passes
without ECC, with single-bit ECC, and with deterministic double-bit ECC, as
detailed above. The injected double-bit error raises the non-fatal interrupt
and scores against the generated status monitor. The generated BFM's live
configuration drives one-shot single- and double-bit injection
through the open target. Separate runtime probes verify mode propagation,
auto-clear, deterministic corruption in word zero, and intact remaining words.
These masks verify the live hook, not the generated responder's randomized
mask. Separately, the
actual-RTL SoC-IFC harness
validates four-word mailbox traffic in both directions: the open-AHB flow sends
data for AXI to read, and the generated-name UVM AAXI flow sends data for AHB
to read and return before UVM reads the response. Both use the integrated SRAM
BFM and close the status/execute handshake. This qualifies the local BFM path,
not the full generated UVMF environment or firmware. The deterministic
injected bit locations preserve the requested fault class but do not reproduce
the responder sequence's random mask. See the
[`mailbox component evidence`](../../evidence/caliptra-bfm-mbox-sram-20261005/README.md)
and [SoC-IFC runtime evidence](../../evidence/caliptra-bfm-soc-ifc-dma-runtime-20261004/README.md), plus the
[generated-runtime evidence](../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md).

The AXI SRAM subordinate also now models AXI4 exclusive accesses per Caliptra
transaction ID: successful read/write pairs return EXOKAY, overlapping writes
invalidate reservations, and failed exclusive writes return OKAY without
updating memory. The focused subordinate and combined DMA-target regressions
pass. This covers the LOCK behavior omitted by
the WD-associated AXI VIP candidate, within Caliptra's visible AXI profile;
full Axi4PC equivalence remains open. See the
[`exclusive-access evidence`](../../evidence/caliptra-bfm-axi-exclusive-20261005/README.md).

The reduced generated `soc_ifc_reg_model_top_pkg.sv` compile passes on a
focused filelist. A retained RAM-guarded compile runner now also compiles the
generated `soc_ifc_env_pkg` and register-model package with the seven generated
interface packages, open BFM/UVM compatibility packages, and hash-guarded
disposable overlays. After the AAXI driver began requiring and consuming the
generated `ports` VIF, this package set recompiled with exit 0, 364 warnings,
and no hard or unsupported-syntax diagnostics; the memory guard observed 81%
free before and 80% minimum during the run, above its 70% floor. This is a
compile-only result: generated UVMF
sequence execution, meaningful coverage, full-agent behavior, and end-to-end
DV qualification remain open. The initial failure on
three arrayed wildcard bins (`ROM[16]`, `ICCM0[16]`, and `ICCM1[16]`) led to a
narrow parser/elaboration implementation for unsigned integral coverpoints
through 64 bits and literal masks with trailing don't-care bits. The exact
ROM/ICCM boundary regression is registered and passes under IEEE 2017 and
2023. Hash-guarded disposable overlays now also supply the copied-package
include paths, AAXI imports, generated-code syntax adaptations, and the
clean-room AHB `ahb_rnw_e` type used by generated mailbox sequences. The initial
host-package runs were stopped after three and two minutes; the selected
control package was stopped after 60 seconds. Follow-up bisection traced that
stall to the generated `generic_input_val` coverage bins: full-width `[0:$]`
ranges overflowed the compiler's `uint64_t` candidate count and skipped its
4,096-value guard. The compiler now reports an explicit error for unsupported
non-`inside` filters over the limit. The paired 2017/2023 focused legacy and
JSON suites pass 10/10 each, including the exact 4,096-candidate boundary,
and the original control-package replay exits with eight coverage errors in
2.59 seconds. The retained bounded replay runner and filelist template
reconstruct the control-package reducer from the pinned checkout and reproduce
the eight diagnostics in 2.07 seconds. This does not implement those generated
coverage bins. One invocation of the larger filelist emitted unresolved-type
and macro-visibility diagnostics followed by parse cascades, but its copied
inputs and log were not retained, so those errors have not been root-caused.
An exact hash-guarded overlay now rewrites the eight generated nonzero-byte
predicates to equivalent wildcard-mask bins in a disposable source copy. The
generated control-package reducer compiles in 2.8 seconds with that overlay,
and a standalone 64-bit covergroup smoke checks every nonzero value in all
eight byte positions plus a two-byte overlap. This is package-elaboration and
bin-semantics evidence only; it does not add generic full-domain `with`
support or establish the generated coverage class's UVMF runtime.
The reduced RAL compile now uses a hash-guarded overlay that adds explicit
name-forwarding constructors to 47 registered classes across 39 disposable
generated source files. It exits 0 with 48 warnings and no hard or unsupported-
syntax diagnostics in 2.8 seconds; the selected filelist excludes generated
interface-agent package copies. This proves the RAL package compile only. Its
captured filelist refers to temporary absolute paths and is not a portable
replay. The current whole host-package compile uses Icarus-specific
adaptations in disposable generated-source copies and compile-progress stubs;
it does not establish generated UVMF runtime or behavior, and it does not
change the separate generated SoC-IFC HDL-top result above.
See the
[`host-package compile evidence`](../../evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/README.md).

The native active UVM AXI sequencer/driver and passive analysis monitor pass
focused UVM/DPI simulations, including a two-beat read/write through the
manager proxy and Caliptra DMA SRAM/FIFO map, fixed-burst FIFO traffic, and an
injected SLVERR response check.
The native active/passive AHB-Lite UVM agent also passes a focused UVM/DPI
smoke for read/write, configured wait states, injected ERROR, and analysis
records. A raw-pin adapter now connects the 32-bit-address/64-bit-data AHB
signals to the UVM record interface; the agent smoke exercises that bridge. The
AHB monitor now adds a lower-bound clean-room compatibility item,
separate predictor/scoreboard/coverage streams, and the three keyed analysis
port names observed in Caliptra's QVIP connection. The AXI monitor now also
publishes a lower-bound clean-room
`aaxi_master_tr` item stream covering fields and methods observed in SoC-IFC.
The AAXI fallback includes the observed predictor export names, a register
adapter, sequencer, and active driver. Its focused smoke performs real RAL
frontdoor traffic through both native and AAXI-style paths and connects
completed monitor records to both predictor exports. The clean-room
manager-event ports publish write requests after AW and all W beats, before B;
write completion follows B. The read-valid and read-done exports publish at
final R. The pin-level record regression checks the write-request-before-B
order; Avery's partial-item lifecycle and exact timing remain unverified. A generated-name
`aaxi_tb.env0.master[0]` hierarchy smoke now drives SRAM write/read traffic
through the actual Caliptra `axi_if` using the open task-based manager proxy,
checks `driver.cfg_info`, and receives both completed analysis records from
active and passive monitors. The passive agent has no sequencer or pin driver.
See the
[`AAXI active/passive smoke evidence`](../../evidence/caliptra-bfm-aaxi-compat-20261004/README.md),
[`native UVM agent evidence`](../../evidence/caliptra-bfm-uvm-agent-20261005/README.md),
and [`Caliptra manager evidence`](../../evidence/caliptra-bfm-caliptra-axi-mgr-20261004/README.md).
This is a component-path smoke only; it exercises the clean-room `ports`
virtual-interface config path. The generated-environment runtime described
above also exercises the pinned `intf_uc`-to-driver handoff. A separate compile-only lane
elaborates the generated pin-level `hdl_top` with proxy class declarations,
and another compiles the generated host package set, but neither builds the
actual generated environment at runtime. The
same actual-RTL harness has a UVM-enabled mode that replaces the direct manager
with the generated-name `aaxi_monitor_wrapper` and `aaxi_uvm_testbench`
hierarchy. Its native UVM sequence writes and reads
`CPTRA_MBOX_VALID_AXI_USER[0]` at host address `0x30048` through
`soc_ifc_top.s_axi_if`; the UVM monitor observes both completed pin records.
The AHB side of that same harness now starts the active clean-room
QVIP-compatible sequencer to read the mailbox lock, transfer all four request
and response words, write mailbox completion status, and program all seven
DMA registers through actual `soc_ifc_top` pins. Its passive agent publishes
the keyed `burst_transfer` stream; the success case records six reads and
twelve writes, and the injected-`SLVERR` case records twelve reads and twelve
writes. The real DMA runtime and injected-`SLVERR` cases pass in this mode as
well as with the standalone manager. This separate harness does not compile
Caliptra's full generated UVMF environment; the generated-runtime result
described above covers that environment's `intf_uc`-to-driver binding. The filelist
supplies the visible AAXI width/interface surface and a monitor
wrapper around the open Caliptra profile checker; the generated-name smoke
uses the wrapper's open task-based manager proxy to drive those pins, mirrors
them through the same AAXI interface shape, and receives records from its pin
monitor. Write request publishes after AW and all W beats are accepted,
before B; write completion publishes after B. Read request and done publish
the assembled record on final R. Focused smoke checks cover write request
before completion. Avery's partial-item lifecycle remains unverified. The
generated-only xactor/PLL
namespaces and unused `rw_txn_pkg` are empty; `aaxi_pkg_test` supplies only
the observed `aaxi_log` constructor. These are import compatibility shims, not
implementations of those libraries' APIs.
Neither compatibility projection recreates the proprietary agent/configuration
behavior or full protocol coverage. The AHB layer now includes a clean-room
lower-bound `qvip_ahb_lite_slave_params_pkg` / `qvip_ahb_lite_slave_pkg`
configuration and environment wrapper over the existing monitor/driver. It
exposes the observed active/passive setting, `set_monitor_item` keys, keyed
analysis ports and `m_sequencer`. A clean-room `hdl_qvip_ahb_lite_slave`
replacement now preserves the generated module and internal wire names used by
Caliptra `hdl_top.sv`, registers local record/command interfaces, and has been
exercised in a generated-style active/passive harness with a synthetic memory
target. The three-edition Icarus smoke checks read/write data, sequencer mode,
and independent predictor/scoreboard/coverage items. The generated PCRVault
`hdl_top` now elaborates with this replacement under 2017 and 2023 using a
hash-guarded Icarus overlay; the full generated UVMF environment remains
unqualified, and the replacement does not reproduce QVIP sidebands, policies,
or internal coverage. The AXI projection now passes the basic
and DMA-target UVM smokes, including factory creation/cloning, `copy`,
`compare`, `sprint`, USER/LOCK fields, FIFO traffic, and 256-beat records. These are
lower-bound item/port checks, not validation of the official VIP event graph
or full environment.
After those runs, the AXI UVM mailbox, monitor, and proxy were widened from
16 to 256 beats to match Caliptra's 8-bit AXI `LEN`; the existing short-burst
smokes were also corrected to pack four WSTRB bits per beat. The updated UVM
smokes pass, including a full 256-beat write through the DMA SRAM map. A typed
adapter smoke also passes against Caliptra's actual `axi_if` for DMA target
write/read and transaction monitoring. That typed-interface smoke now carries
a full 256-beat SRAM round trip through the task-based manager and combined
DMA target. The active native UVM agent now also drives SRAM, FIFO, and
256-beat traffic through the pinned `axi_if`; the open target and UVM monitor
check the same transactions. A further smoke connects the pinned Caliptra
`axi_mgr_rd`/`axi_mgr_wr` modules to the recreated target, checking manager-
generated AXI requests and completed UVM records with Caliptra's assertion
macros enabled. A further UVM smoke programs the pinned `axi_dma_top` through
its CSR request interface and drives a 65-word transaction from Caliptra's
randomizer through the actual register block, control FSM, managers, open
target, and passive UVM monitor. Its second case injects `SLVERR` and checks
the observed partial write and DMA error state. A third case transfers a
65-word FIFO stream through the real recovery input and checks five fixed FIFO
reads against five SRAM writes. This is block-level DUT integration; it does
not exercise the full Caliptra top, firmware scenarios, or generated UVMF
environment. A source-compatible
`caliptra_top_tb_axi_complex` replacement now
maps Caliptra's FIFO/recovery controls, randomized channel delays, and gated
one-shot address-range `SLVERR` injection. A separate pin-level smoke checks
those behaviors against Caliptra's actual `caliptra_top_tb_pkg.sv`,
`soc_ifc_pkg`, `axi_pkg`, and typed `axi_if`, so the test uses the pinned
`axi_complex_ctrl_t` rather than a local layout stand-in. It still does not run
the Caliptra DUT top. With `CALIPTRA_BFM_CHECKER`, the
replacement connects the native profile checker; the smoke checks multi-beat
R/B response stability under backpressure and uses a read ID with the 5-bit
DMA ID's high bit set. It also preserves the firmware loader's
`i_axi_sram.i_sram.ram[addr][byte_idx]` SRAM preload hierarchy, checked by a
backdoor-seed/readback in the pin-level smoke. Separately, the native AHB
manager/checker/monitor pass
a focused write/readback run against the actual pinned ECC unit RTL via
`ahb_lite/tests/run_caliptra_ecc_ahb_bfm.sh`; that run is not a generated UVMF
environment.

**Track A integration update (2026-10-06).** The replacement now gates the
generated recovery sequence on the same `+CPTRA_RAND_TEST_DMA` plusarg that
enables Caliptra's block-size generator; without that plusarg the array is
uninitialized by design. A regression reproduced the unknown-array fatal and
passes with the gate. The full `caliptra_top_tb` compiles with the replacement
and a disposable packed SRAM-export compatibility copy. `smoke_test_veer`
reaches its firmware pass marker and normal finish with no SVA/runtime errors,
but the sandbox rejects the JTAG DPI socket bind and the test has no DMA
traffic. Record this as diagnostic top integration only, not a qualified L0
pass; see the
[`open-top smoke evidence`](../../evidence/caliptra-bfm-open-top-smoke-20261006/README.md).
The firmware-driven DMA top path and a JTAG-capable runner remain open.
**Track A DMA update (2026-10-08).** A one-iteration full-top
`CPTRA_RAND_TEST_DMA` in-flight reset/replay run later emitted the firmware
`* TESTCASE PASSED` marker and reached `$finish` inside a 5,400-second guard.
The marker is the firmware success-mailbox write, not a ROM-flow banner. This
demonstrates that the replay can complete, but remains diagnostic only: the
Icarus build was dirty and unpublished, and JTAG DPI logged a socket-bind
permission warning. Earlier 3,600-second timeout records are unchanged. See
the [full-top replay evidence](../../evidence/caliptra-bfm-fulltop-rand-dma-208-reset-20261008/README.md).
**Track A AES/DMA update (2026-10-08).** Twelve isolated short-suite vectors now
pass through the full-top target with the open checker enabled, exercising
one- through twelve-beat source buffers. Destination writes are split for
vectors five through twelve, ranging from 4+1 to 4+4+4. These diagnostic runs
used dirty, unpublished Icarus `ac4532fa-dirty`, so they do not qualify the full
suite. See the
[`twelve-vector trace evidence`](../../evidence/caliptra-bfm-open-top-wstate-20261008/README.md).
The clean-room PV client master also runs against the actual PCRVault RTL. Its
direct DUT probe covers concurrent PV read/write, client readback, AHB
readback and control-register access, terminal `last`, invalid offsets, and
reset aborts under IEEE 2017 and 2023. This remains IP-level evidence, not a
full generated-environment or full Caliptra top run.
The native UVM PV sequencer/driver now reaches the same task BFM through a
command proxy and verifies actual PCRVault write/readback plus completion
records. It is still a focused IP-level agent, not generated UVMF integration.
The actual generated PCRVault `hdl_top` elaborates against the clean-room AHB
HDL shell in IEEE 2017 and 2023. Clean-room wrappers provide the generated
QVIP `reg2ahb_adapter` and `ahb_reg_predictor` surfaces over the native scalar
RAL adapter and standard UVM predictor. With hash-guarded overlays for
Icarus-specific source limitations and the generated PV read BFM/monitor
gaps, the actual generated `pv_rand_wr_rd_test` runs against the real PV RTL
and generated scoreboard with zero UVM errors/fatals and normal termination.
Its 768 warnings are preserved and the generated pass marker is checked. This
is PCRVault block-level evidence, not full Caliptra-top or licensed UVMF/QVIP
qualification. See the reproducible
[`generated PCRVault UVMF evidence`](../../evidence/caliptra-bfm-pv-generated-uvmf-20261004/README.md).
The generated KeyVault `hdl_top`, actual KeyVault RTL, and its reset/read/write
BFM interfaces also elaborate with the open AHB shell in 2017 and 2023. The
generated `hvl_top` and `kv_rand_wr_rd_test` first ran under 2017, where the
initial runtime reported seven read-response mismatches. A pin/model trace
shows that the generated write monitor publishes one clock after the RTL
accepts the write, while the read monitor notifies subscribers immediately.
The read predictor therefore sees stale `KEY_CTRL`/last-dword state before the
same-timestamp write predictor callback. A hash-guarded Icarus overlay adds a
zero-time yield after read capture; the generated test now passes under IEEE
2017 and 2023 with zero UVM errors and fatals. The unconditional sequence pass
marker is still not used as the gate. The 2023 run's 68,229 warnings are
preserved and reported. This qualifies only the pinned KeyVault block test with
the local compatibility overlay, not licensed full UVMF/QVIP or the full
Caliptra top. See the
[`generated KeyVault HDL evidence`](../../evidence/caliptra-bfm-keyvault-generated-hdl-20261004/README.md).
This document is not a conformance status source and does not change any
matrix entry.

**Evidence basis update (2026-10-03).** The read-only pinned Caliptra checkout
is present at `/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl`;
the local QD-BFM checkout is present at
`/Users/danielellerbrock/projects/quick-and-dirty-eda/qd-bfm`. The focused
consumer findings and source/license provenance are recorded in
[`caliptra_bfm_research_2026-10-03.md`](caliptra_bfm_research_2026-10-03.md).
The Phase 0 source census is in
[`caliptra_bfm_phase0_inventory_2026-10-03.md`](caliptra_bfm_phase0_inventory_2026-10-03.md),
with its hash-recorded output at
[`caliptra_bfm_consumer_manifest_2026-10-03.json`](caliptra_bfm_consumer_manifest_2026-10-03.json).
Phase 0 is partially complete: the consumer sources and all 44 unit-filelist
surfaces/outcomes are indexed, including provider variables, include roots,
visible package/DPI references, five absent Adams Bridge source paths, and
literal test-YAML names, seeds, and plusargs. Resolving providers and the
effective runtime argument flow, completing the API/method inventory, and
recording redistribution decisions remain open. Rows still tagged
`[unverified]` are not requirements.

Pinned sources `[repo: release_overlays/README.md]`: Caliptra `v2.1.2`
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge `v2.0.3`
`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.

The direct-pin native simulations use system Icarus 13.0. The typed Caliptra
`axi_if` wrapper tests, ECC RTL smoke, and UVM/DPI agent smokes use the local
Icarus fork; the wrapper needs typed interface-port support, the ECC smoke
needs the fork's Caliptra RTL language support, and the UVM tests need its
`-uvm` support. Most runs are standalone protocol/adapter checks; the ECC
smoke is a unit-level DUT check. None is a top-level Caliptra or generated
UVMF environment qualification.

---

## 1. What "the needed BFM" actually is

The word covers two different gaps. They have different owners and must not be
conflated.

### Track A — L0 integration lane (firmware-driven, `caliptra_top_tb`)

The BFMs are **already in the pinned tree** and compile: `caliptra_top_tb_soc_bfm.sv`,
`axi_if.sv` (task-bearing AXI BFM interface), `caliptra_top_tb_axi_complex.sv`,
plus the JTAG DPI bundle (`jtagdpi.vpi`, built natively in
`evidence/caliptra-jtagdpi-native-20260923`). `[repo]`

The open source-compatible `caliptra_top_tb_axi_complex` replacement is now
part of this work. It removes the replacement's interface-task mixed drivers
and compiles with the full top using the documented disposable SRAM-export,
checker, and reset overlays. The L0 smoke reaches the firmware pass marker but
is diagnostic only: the sandbox rejects JTAG DPI socket creation, and
`smoke_test_veer` does not issue DMA traffic. A real full-top DMA firmware run
is still open. The one external piece in this lane is
the licensed ARM `Axi4PC.sv`, whose placeholder is intentionally invalid at
`Axi4PC.sv:17` and is excluded by a filelist-only edit
(`evidence/caliptra-l0-icarus-baseline-20260923`). That is a Track B item
(§3.4).

### Track B — Official DV: UVMF unit/block and top environments

The pinned-source scan finds 219 active YAML <code>testname:</code> fields in
Caliptra and 52 in Adams Bridge, 27/2 files under
<code>stimulus/testsuites</code>, and 29/3 regression-named YAML candidates.
The 44 unit <code>.vf</code> entry points come from the frozen compile-only
census. The earlier 293-test (241/52) and 33-list totals are not reproduced
from these roots; their cited evidence directory is absent from this QD
checkout, so they are not a verified coverage denominator. The earlier note
cited `evidence/caliptra-l0-52-and-full-dv-gap-20260923/README.md`; that file
is not tracked in this QD checkout. The official regressions need VCS plus
inputs that are **absent**: UVMF 2022.3, Questa QVIP 2021.2.1, Avery AXI VIP
2025.1, licensed ARM Axi4PC.

Recorded unit census (44 entries, compile-only, not a runtime result)
`[repo: evidence/caliptra-icarus-dv-baseline-20260923]`: 20 compile pass, 6
fail, 17 setup (missing external input or include root), 1 unsupported (VVP
512-flag ceiling). Only 2 of 3 attempted unit runtimes pass.

**Track B is what this plan covers:** a clean-room, in-repo substitute for the
missing verification infrastructure, targeting meaningful Caliptra traffic
and checking on Icarus. Running the official UVMF environments unmodified is a
target only if the Phase 0 inventory and legal inputs make that achievable; the
observed `aaxi_master_tr` dependencies are a concrete compatibility boundary,
not something a generic transaction record can satisfy by itself.

### Why the evidence is thin

The same session logs say "UVMF, ARM AXI checker, and Avery inputs still
prevent a full Caliptra DV runtime claim" without ever recording *which UVMF
classes, which VIP sequences and which macros the pinned environments use*.
That inventory is the first deliverable (Phase 0). Without it, the surface
below is a guess.

---

## 2. Ground rules specific to this program

1. **Clean room, license first.** Do not copy Siemens/Mentor UVMF, QVIP or
   Avery source or encrypted models. Phase 0 must first determine whether UVMF
   is redistributable under its own license. If it is, vendoring the real
   library (as a pinned, hash-recorded input) beats recreating it and
   collapses Phase 2. QVIP and Avery are not assumed redistributable.
2. **Specified from use, not from memory.** The substitute implements exactly
   the API consumed by the pinned Caliptra/Adams Bridge sources, as measured by
   the Phase 0 manifest. Unused API is not built.
3. **A BFM that does nothing is not a BFM.** Per the AGENTS semantic-degradation
   rules: no always-ready slave that never checks, no monitor that never
   publishes, no scoreboard that never compares, no protocol checker that is an
   empty module. The Axi4PC substitute must either perform real checking or be
   left unbound and reported as an unsupported checker. It must not turn a
   missing licensed checker into a silent pass.
4. **The BFMs are themselves qualified artifacts.** A recreated VIP is a
   source of false passes and false failures. It needs its own negative
   controls (inject a protocol violation; the monitor/checker must flag it)
   before its results count as DUT evidence.
5. **Pinned Caliptra stays pristine.** Substitutes live in this repository and
   are supplied through filelists, `+incdir`, and environment-variable provider
   mappings (`UVMF_HOME`, `CALIPTRA_AXI4PC_DIR`, and the VIP equivalents found in
   Phase 0). Any unavoidable source change is a named, hash-guarded overlay in
   `release_overlays/`, recorded separately from unmodified-source results.
6. **Compiler gaps are blockers, not part of this program.** When the
   substitute exposes an Icarus defect, record a blocker/discovery with a
   minimal reducer and select it through the normal protocol. Do not widen a
   BFM item to fix the compiler, and do not rewrite the BFM to dodge the
   defect when the original construct is legal. A workaround in the substitute
   is allowed only when the original VIP's API is not what is being exercised,
   and it is labeled as such.
7. **Edition and mode honesty.** Report 2017 and 2023 separately. Name the
   generation mode that `.github/uvm_test.sh` used. A result in the
   "Icarus + recreated BFM" lane is not a VCS/Questa qualification and must not
   be reported as one.
8. **Results use the AGENTS UVM evidence ladder**: compiles, mechanisms
   execute, regression passes, real DPI, complex env compiles, meaningful
   traffic and checking, drains and terminates. Report the highest level
   actually reached per environment.

---

## 3. Target architecture

Layered so each layer is testable before the next depends on it.

```
L4  Caliptra / Adams Bridge UVMF environments   (pinned, unmodified)
L3  Protocol agents (QVIP / Avery replacements) (this program)
L2  UVMF base library: uvmf_base_pkg + util     (this program, or vendored)
L1  UVM (uvm-core, pinned; 2017 and 2023 modes) (existing)
L0  Icarus language/runtime                     (existing; gaps -> blockers)
```

### 3.1 L2 — UVMF base library

UVMF-generated environments split into an HVL (class) side and an HDL
(interface/module) side joined by proxy handles. The substitute must reproduce
the *observable contract* of the following, **subject to Phase 0 confirmation
of which are used** `[unverified]`:

| Area | Contents to confirm |
| --- | --- |
| Base classes | transaction, sequence, driver, monitor, parameterized agent, environment, test, virtual-sequence, predictor, scoreboard bases |
| Scoreboards | in-order, in-order race-free, out-of-order comparators with their mismatch/leftover reporting |
| HDL/HVL bridge | driver/monitor BFM interfaces with a `proxy` class handle, config-DB registration of virtual BFM interfaces, `initiate_and_get_response` / `wait_for_*` task protocol |
| Config/params | agent configuration objects, `*_parameters_pkg`, `*_typedefs` |
| Macros/utilities | the `uvmf_*` macros and util package |
| Register layer | any reg-adapter/predictor glue the environments instantiate |
| Top scaffolding | `hdl_top` / `hvl_top` / `*_test_base` startup order, clock/reset generation |

Deliverable is not "a package named `uvmf_base_pkg`". It is a package whose
behavior is pinned by tests derived from the consumer manifest (§5, Phase 2).

### 3.2 L3 — Protocol agents

Replace only the VIP endpoints the pinned environments instantiate. The
inspected Caliptra SoC path needs AXI4 and a passive AHB-Lite observer; a full
Phase 0 census still determines the wider unit-environment set. The internal
AXI interface shows USER and LOCK are exercised, with multi-beat mailbox
transfers `[repo]`. Each active agent provides:

- manager and subordinate roles, as the environments require;
- full-handshake, backpressure-capable driving, with configurable ready/valid
  behavior (including stalls), because always-ready hides bugs;
- bursts, IDs, response codes, USER sideband, exclusive/lock where the DUT uses
  them;
- a passive monitor publishing analysis transactions to the scoreboards;
- memory-model subordinate with defined behavior for unmapped/error accesses;
- inline protocol self-checks that raise real errors.

Ordering: follow the Phase 0 census; start with the protocol used by the
largest number of compile-passing units.

For AXI4, the permissively licensed [CHIPS Alliance `axi-vip`](https://github.com/chipsalliance/axi-vip)
was checked in `BFM WORK` at commit
`16d0f444299014b2079c941925ea8b43d85a13f7`. It has UVM agent/driver/monitor/
sequence sources, but its package fails to compile unchanged on the local
Icarus fork, and its present interface omits LOCK and does not match Caliptra's
32-bit USER/data profile. The exact probe is recorded in the research document.
It remains a source of reference patterns, not an integrated agent; the native
Caliptra implementation is the current open path.

### 3.3 Reference prior art and current implementation

The locally available QD-EDA source is copied with its Apache-2.0 license to
`dv/caliptra_bfm/axi/qd_axi4_single_master.sv`. It remains a directed
single-beat helper without USER/LOCK, bursts, or safe timeout recovery.

The new `dv/caliptra_bfm/axi/axi4_caliptra_checker.sv` checks stable payloads
on all five channels, the supported burst shape and 4KB rules, AW/W beat
pairing and WLAST, and response ID/length matching. It accepts one outstanding
transaction per ID, matching the inspected Caliptra Avery setup, and applies
an aligned-transfer profile. Its positive simulation and nine negative
controls pass with Icarus 13.0. This checker is not a complete Axi4PC
replacement; it cannot observe CACHE/PROT/QOS/REGION absent from Caliptra's
interface, and it does not enforce mailbox USER/LOCK policy.

The passive `axi4_caliptra_monitor.sv` records channel handshakes. The
additional `axi4_caliptra_transaction_monitor.sv` assembles bounded completed
read/write records, including W-before-AW buffering, USER/LOCK, beat framing,
and responses. It supports bounded concurrent reads and writes, including
interleaved R beats, AW-ordered W pairing, out-of-order B/R completion across
IDs, and request-order completion for repeated IDs; it emits procedural event
records. The current direct-monitor result is recorded in
`evidence/caliptra-bfm-axi-concurrency-20261005/README.md`.
`axi4_caliptra_uvm_pkg.sv` publishes native items and
a lower-bound `aaxi_master_tr` projection on `aaxi_ap` for the visible SoC-IFC
consumer fields/methods. A bounded second-model audit found no missing direct
transaction members for the inspected predictor, scoreboard, and coverage
subscriber. It also confirmed this is not a drop-in connection: the pinned
environment wires four manager exports, two request-side sources to the
predictor and coverage plus separate read/write done sources to the
scoreboard. The fallback now exposes each observed port name: write request
publishes after AW and all W beats are accepted, before B; write completion
publishes after B; read request and done publish on final R. Focused smoke
checks verify request-before-completion ordering. Avery's object reuse,
partial-item lifecycle, read granularity, and exact event ordering remain
unknown. It also lacks the other Avery
packages and generated agent/configuration types imported by the environment.
Event timing and licensing must be established before recreating those
surfaces. The fallback projection now passes focused basic and DMA-target UVM
tests, including the direct transaction methods consumed by SoC-IFC; this does
not make it a drop-in Avery agent.

The companion `axi4_caliptra_recovery_avail.sv` models not-empty, threshold,
and pulse availability policies and is wired into the DMA map wrapper. It
is connected to optional autonomous FIFO push/pop controls that model the
pinned shared-queue traffic. `axi4_caliptra_recovery_sequence.sv` consumes the
100-entry packed block-size array emitted by Caliptra's Apache-2.0
`src/integration/tb/dma_testcase_generator.sv`, skips zero entries, selects a
threshold for each nonzero block, and advances after emulation ends. Focused
standalone tests cover this interface shape and the FIFO/DMA/recovery sources.
The actual generator runs into a bounded DCCM shadow and drives multiple
entries through this sequencer. The actual-DUT runner now selects every one of
the 29 generated records in a separate simulation, validates the staged
metadata and payload ECC, and checks each generated transfer through
`axi_dma_top`. A hash-guarded replay profile spans all five named route types,
eight short sizes (1, 4, 5, 16, 64, 65, 255, and 256 words), a maximum
65,536-word fixed-read FIFO-to-SRAM stream, a 65-word fixed-write SRAM-to-FIFO
profile with randomized target delays, a 65-word AXI2AXI FIFO recovery profile,
and 65-word AXI2MBOX and AXI2AHB recovery profiles. The generated recovery
profiles sweep legal block sizes from 4–64 bytes on AXI2AXI and 4–2048 bytes
on AXI2MBOX and AXI2AHB. Short records retain per-record payloads,
route-valid offsets, and the generated delay flag. The maximum stream
validates every destination word and drains the FIFO; FIFO destination checks
all queued words and stalls; recovery checks all route outputs. Three 65-word
non-recovery FIFO-source records also validate AXI2AXI-to-SRAM, AXI2MBOX, and
AXI2AHB routes under randomized target stalls. Other generated FIFO mode/flag
combinations and firmware-triggered reset injection remain unqualified. Generated FIFO-source
AXI2AXI, AXI2MBOX, and AXI2AHB transfers now each pass 1, 4, 5, 16, 64, 65,
255, and 256-word profiles; the runner checks FIFO drain, route payload, and
randomized stalls.
See the [`FIFO-source size-sweep evidence`](../../evidence/caliptra-bfm-dma-fifo-source-size-sweep-20261007/README.md).
Generated SRAM-to-FIFO AXI2AXI transfers also pass 1, 4, 5, 16, 64, 65, 255,
and 256-word profiles, checking fixed-write bursts, randomized stalls, and
every queued payload word. See the
[`FIFO-destination size-sweep evidence`](../../evidence/caliptra-bfm-dma-fifo-destination-size-sweep-20261007/README.md).
A focused route replay also covers the legal FIXED-read AXI2MBOX and
FIXED-write MBOX2AXI modes through the actual DMA DUT, checking sequential
mailbox requests and repeated SRAM destination addressing. A second replay
covers FIXED-read AXI2AHB and FIXED-write AHB2AXI through the component data
path. Default mixed DMA profiles and firmware remain open.
The AHB routes use component `WRITE_DATA`
and `READ_DATA` registers, not an AHB bus. A separate SRAM-to-FIFO profile
checks fixed write bursts, weighted channel stalls, and queued words.
See the
[`Earlier 25-record DMA DUT replay evidence`](../../evidence/caliptra-bfm-dma-generator-dut-replay-20261006/README.md).
The additional generated FIFO-destination case is recorded in
[`generated FIFO-destination evidence`](../../evidence/caliptra-bfm-dma-generated-fifo-destination-20261006/README.md).
The generated recovery block-size case is recorded in
[`generated recovery evidence`](../../evidence/caliptra-bfm-dma-generated-recovery-block-20261006/README.md).
The directed route profiles are recorded in
[`all-route DUT evidence`](../../evidence/caliptra-bfm-dma-all-routes-20261006/README.md).

**2026-10-08 diagnostic update:** The new
[`FIFO no-injected-delay sweep`](../../evidence/caliptra-bfm-dma-fifo-no-delay-20261008/README.md)
replays generated 65-word FIFO-source AXI2AXI, AXI2MBOX, and AXI2AHB records,
plus an AXI2AXI FIFO-destination record, with `inject_rand_delays=0`. All four
records pass through `axi_dma_top`; the three source records drain all 65 FIFO
words. This remains diagnostic on the dirty, unpublished Icarus build recorded
in the evidence.

**2026-10-09 diagnostic update:** Generated record 67 now also runs as a
65-word fixed-read FIFO-source AXI2AXI reset-abort profile. The accepted write
is aborted before B, then the DMA replays the full transfer; the checker
verifies the payload and that all 65 FIFO words were consumed and drained. The
existing SRAM-source reset-abort profile still passes. Both results are
diagnostic on the dirty, unpublished Icarus build. See the
[`FIFO-source reset-abort evidence`](../../evidence/caliptra-bfm-dma-fifo-source-reset-abort-20261009/README.md).

### 3.4 Axi4PC (ARM protocol checker)

Treat as a distinct item. The new Caliptra-profile checker is useful
independent checking, but it is not equivalent to Arm Axi4PC. Report full
Axi4PC as absent unless its assertion inventory can be legally established
and the replacement is qualified with violation-injection controls. Never
bind a no-op module in its place.

### 3.5 JTAG DPI

Done natively and loaded with `vvp -d <bundle>` `[repo]`. Out of scope.

---

## 4. Compiler-readiness preview (to be measured, not assumed)

UVMF/VIP code is idiom-heavy. These are the Icarus capabilities the substitute
will lean on. Each is a *question for Phase 1*, not a known gap. The repo
already records evidence for some (virtual interfaces, modports, clocking,
parameterized classes, `bind` — see the 2017 clause matrix rows 8, 14, 25).

| Idiom | Question |
| --- | --- |
| Interface BFM holding a class `proxy` handle; interface tasks calling class methods and vice versa | Works across edition modes, with `-g2017` and `-g2023`? |
| `uvm_config_db#(virtual X_bfm)` set from `hdl_top`, get in `hvl_top` | Parameterized/typedef'd virtual interfaces, exact-type matching |
| Parameterized interfaces and agents with type parameters | Identity and modport-qualified VIF compare (matrix notes parameter-specialized VIF identity as open) |
| Interface task with `output`/`ref` args consumed from a class | Calling convention across `wait`/clock events |
| Clocking-block driving from interface tasks | Skew and region semantics (§14, §16.14) |
| Same-member continuous + procedural writes within a BFM interface | The exact §6.5 trap that blocks Track A today; the substitute must be legal under it |
| `bind` of checkers/SVA to BFM interfaces | Existing `bind` subset |
| Wide packed structs and dynamic arrays for burst data | Known strengths per census |
| Compile scale (VVP 512-flag ceiling hit by one unit) | Image size of full env |

---

## 5. Phases and exit gates

Each phase ends in a recorded, revision-scoped evidence directory. A phase is
not complete on "it compiled".

### Phase 0 — Consumer inventory and licensing (read-only)

The pinned Caliptra and Adams Bridge checkouts are present. The focused AXI and
AHB consumer paths have been inspected and a reproducible, hash-recorded source
manifest now exists. It identifies SoC-IFC, PCRVault, KeyVault, Adams Bridge
ML-DSA, and top-level check/monitor use. It also found a dummy Avery AXI schema
with only a one-bit placeholder port; this is not evidence of a real Avery
pin-level producer. The frozen 44-filelist census was mapped exactly to 17
Caliptra and 27 Adams Bridge entries; a filename glob gave the wrong split.
The legacy 293-test / 33-group totals remain unverified and are not used as the
coverage denominator. The pinned source-defined inventory is recorded above.
UVMF license terms are not visible in the user-linked mirror, so no source is
copied.

Deliverables (scripted and re-runnable, hash-recorded):
- License determination for UVMF, QVIP, Avery, Axi4PC; redistribution decision.
- `consumer_manifest.json`: for every UVMF-dependent test/env, the set of
  external packages imported, classes extended, methods called (with arity and
  override points), macros used, plusargs and `+define`s, filelist provider
  variables, and DPI imports. Counts per symbol; which of the 44 units and
  which UVMF top/block envs need each.
- Required-versus-present matrix over the manifest's source-defined test/config
  records, 44 units, and listed test suites; do not use the unverified 293/33
  totals as the denominator.
- Decision record: vendor vs. recreate for UVMF; protocol set and order for L3.

Gate: the source inventory regenerates byte-identically; the old 293/33 source
is found or replaced with the pinned source-defined denominator; every
`[unverified]` row in §3 is resolved to confirmed, refuted, or unused; required
license terms are recorded.

### Phase 1 — Idiom reducers (compiler readiness)

Minimal reducers (one per §4 row) in strict 2017 and 2023, with Slang as
differential evidence. Each failure becomes a `BLOCKERS.md` / DISCOVERED_DEBT
entry with the failing reproducer. No implementation here.

Gate: every idiom the manifest says is *used* is either PASS in both editions
or has a recorded blocker.

### Phase 2 — UVMF base library

The clean-room package has started with the generated transaction base and
`uvmf_in_order_scoreboard #(T)`, a surface instantiated by the pinned ECC,
HMAC, and SHA-512 environments. Its focused UVM smoke checks publisher-side
mutation safety, in-order matching, mismatch severity, independent
expected/actual leftovers, and end-of-test counts. The package now also has
the source-observed `uvmf_sim_level_t` type and an HDL package for the shared
`uvmf_active_passive_t` and `uvmf_initiator_responder_t` enums. The host-side
package re-exports those exact enum types for generated configuration code.
It has an environment configuration base that stores the arguments passed by generated
Caliptra tops. A parameterized agent configuration base resolves typed driver
and monitor BFMs from the observed `UVMF_VIRTUAL_INTERFACES` config-DB scope
and interface-name key during driver/monitor connect, after agent build and
configuration initialization. The focused toy-agent test publishes those
handles from a later build-phase component that asserts both agents have
completed build. Driver and monitor `configure()` hooks now run only after
their typed handles are resolved and assigned. The positive and
mismatch-control cases pass under IEEE 2017 and 2023, including response-clone
isolation. The generated ECC reset scoreboard and IRQ_EN AHB write/readback
also pass under IEEE 2017 and 2023 after this phase change. See the
[`late-registration smoke evidence`](../../evidence/caliptra-bfm-uvmf-late-vif-20261007/README.md).
The generated derived configuration performs the agent/configuration
publication itself.
Generic driver
and monitor bases now provide the hooks used by generated agents: typed BFM
handles, `configure`, proxy installation, driver `access`, and monitor
analysis publication. Environment and agent bases provide the generated
`set_config` handoff. Virtual sequencer, sequence, virtual-sequence, and test
bases now cover the generated test → environment → agent → sequence path. The
parameterized agent creates the monitor, adds the sequencer and driver for
`ACTIVE`, conditionally creates coverage, publishes the sequencer under
`UVMF_SEQUENCERS`, and exports the monitor stream as `monitored_ap`. The
self-authored active/passive environment smoke follows a generated-style
hierarchy: top test
initialization retrieves distinct typed driver/monitor VIFs, the environment
passes configs to active and passive agents, a bench sequence retrieves
`TOP_ENV_CONFIG`, a
virtual sequence starts on the environment virtual sequencer, and an agent
sequence exercises the driver. The active agent monitor captures the request
to a tiny combinational toy DUT, a predictor computes the expected response,
and a separate passive agent observes the output. Its transaction reaches the
observer, coverage sink, and in-order scoreboard through `monitored_ap`. The
positive run records one match; a second run perturbs the prediction and the
scoreboard reports exactly one mismatch. The smoke transaction derives from
the UVMF transaction base and verifies that timestamp/view metadata copies
while timestamp differences do not affect comparisons; changing the
transaction value still produces a mismatch. The observer
and coverage sinks use explicit `uvm_analysis_imp` connections. In an
intermediate local Icarus probe, a sink derived from `uvm_subscriber #(agent_item)` received a
null handle; the existing native AXI subscriber smoke passes, so generated
Caliptra coverage subscribers still need separate qualification. The focused
agent and scoreboard smokes now pass under `-g2017` and `-g2023` with the
bundled Accellera UVM 2020.3.1 library. These
selected component-base slices are exercised against generated ECC and
SoC-IFC environments below. The self-authored toy-DUT reference now reaches the
end-to-end portion of the Phase 2 gate in the current local UVM/Icarus mode.
The out-of-order scoreboard now passes a focused reordered-match and mismatch
smoke under IEEE 2017 and 2023; actual Caliptra traffic remains unqualified.
The gate also remains open because only one UVM release has
been exercised. The
generated ECC packages compile and elaborate in the focused source-order
probe. The generated ECC runtime proxy blocker (DD-105) is now fixed locally:
the generated `test_top` and agents build and all BFM proxies install under
both IEEE editions. This proxy probe does not cover ECC DUT traffic or generated
component overrides beyond the checked agents. A separate generated-top
runtime probe now exercises the generated driver's AHB BFM tasks against
`ecc_top` for an interrupt-enable register read/write; cryptographic
operations remain open.
These are incremental Phase 2 slices, not a complete base library; the rest
of the manifest-selected API remains to be implemented.

The generated ECC compile probe has progressed through the original proxy
syntax blocker (DD-104), now fixed locally. Icarus compiles the actual
`ECC_in_pkg` and `ECC_out_pkg` packages in focused probes in both editions;
the generated interface proxy class-handle shape has a separate paired
reducer. A grouped package-first
compile initially appeared to expose an interface cycle. The corrected probe
follows Caliptra's `config/compile.yml` source order and compiles all four actual
generated BFM interfaces, both bus interfaces, and the actual `ECC_env_pkg`,
parameter, sequence, and test packages without elaboration errors in either
edition. The runtime probe then builds the generated `test_top`, actual ECC
environment, and agents. After DD-105's interface-layout property repair, the
generated driver and monitor proxies install and the UVM summary reports zero
errors and fatals under both editions. The repeatable proxy-only result is
recorded in
`evidence/caliptra-bfm-generated-ecc-runtime-20261004/verify_fixed.log`. That
probe does not compile generated `hdl_top`/`hvl_top`, instantiate the ECC DUT,
or run the generated testbench. Icarus represents wide automatic bins as exact
prefix blocks, including non-power-of-two limits; focused regressions cover a
65-bit three-bin partition, the generated 384-bit ECC and 512-bit HMAC/SHA512
output shapes, a 130-bit word-boundary prefix, and wide crosses. The explicit
wide-range regression also checks endpoint identity, X/Z-to-zero sample
coercion, overlapping-bin warning and hit behavior. Focused status wildcard
transition bins pass under 2012, 2017, and 2023, with no increase in Bison
conflict counts. The generated status source-order probe gets through those
coverage declarations. Its pristine compile stops on trailing-empty-argument
`$psprintf` calls in the generated configuration and BFM files; the named
hash-guarded overlay in
[`release_overlays/README.md`](release_overlays/README.md) removes those three
empty arguments from disposable copies. The resulting status package,
interface, driver, and monitor elaborate under 2017 and 2023 with seven
compiler warnings each. This is compile/elaboration evidence only: status bus
traffic, coverage, DUT use, and the full generated environment remain open.
The actual generated active status agent now also constructs under both
editions using the hash-guarded overlay; its driver and monitor proxy handles
match the generated UVM components, with zero UVM warnings, errors, or fatals.
That bounded runtime smoke sends no status transactions and does not qualify
the protocol monitor or coverage.
The passive-monitor probes now check the published `monitored_ap` transaction
under both editions. The full-snapshot probe validates all 17 status fields on
the startup reset-deassertion record and two later event snapshots, then
confirms the generated coverage subscriber receives all three records through
its `write()` method; the runtime has zero UVM warnings, errors, or fatals.
Icarus covergroup stubs prevent functional bin-hit measurement. The separate
generated SoC-IFC runtime also exercises the status monitor and scoreboard
against real `soc_ifc_top` outputs through reset.
The pinned SoC environment configures this status agent as `RESPONDER`; its
generated initiator task is a clock-wait/copy skeleton that does not drive
status pins. Do not treat the active-agent construction smoke as proof of
status stimulus capability.
The clean-room UVMF transaction base now has overridable `set_key`/`get_key`
methods, and a focused set/get/copy probe passes in both editions. The control
package has a separate trailing-empty-argument error and is not covered by the
status overlay. `ACTIVE`, `PASSIVE`, `INITIATOR`, and
`RESPONDER` lookup warnings are resolved by named exports from the clean-room
base package, exercised with the actual ECC packages in both editions. The
probe is an elaboration check, not an environment or DUT run.
The 2026-10-04 package list, run command, and source hashes are recorded in
[`generated ECC package probe evidence`](../../evidence/caliptra-bfm-generated-ecc-packages-20261004/README.md).
The generated `hdl_top.sv` now has a paired integration compile check against
actual ECC RTL. The pristine top reproduces two input-driver writes through
`initiator_port` inputs under both editions; a disposable three-selector
overlay elaborates the actual top and RTL. A follow-on runtime executes
generated `hvl_top` with the actual `ecc_top`, matches the reset scoreboard,
and verifies an `ECC_IRQ_EN` write/readback through the generated input
driver's BFM tasks under both editions. A separate 1,200,000-clock run also
completes a keygen operation and matches its predicted vector under both
editions, as recorded below. Full generated sequence and coverage behavior
remain open. See
[`generated ECC HDL-top evidence`](../../evidence/caliptra-bfm-generated-ecc-hdl-20261004/README.md).
The probe also covers the `uvm_reg_map` indexed inherited `get_full_name` method; a focused
2017/2023 regression now guards the same selected-queue method and string
concatenation shape. The earlier Slang virtual-interface type diagnostic
remains unqualified. Probe details and commands are recorded in the research
note; generated ECC integration is qualified for reset monitoring, this
IRQ-enable readback, and one predicted keygen transaction per IEEE edition.

The UVMF-lite config base now requires a driver BFM only for `ACTIVE` agents;
the active/passive smoke omits the passive driver's virtual-interface
registration and passes in both IEEE editions. This removes one generated ECC
build blocker because its output agent is passive and instantiates only a
monitor. The generated ECC vector-generator C source builds natively against
the host Mbed TLS package, avoiding the checked-in Linux-only binary. The input
monitor republished while the initialization flag was held high, and a longer
reset-only probe exposed a second unmatched output from that reset marker. A
source-hash-guarded overlay
waits for a fresh input completion and ignores the output reset marker before
accepting operation completions. The actual generated `hdl_top`/`hvl_top` run
against ECC RTL now matches exactly one reset transaction after 250 clocks in
IEEE 2017 and 2023, with zero UVM errors or fatals. A follow-up reset-plus-one-
keygen run under IEEE 2017 produces no keygen predictor event within 500,000
clocks. Bounded 1,000- and 10,000-clock AHB traces confirm the generated driver
completes seed/nonce/IV/control transfers and polls status with `HREADY` and
`HREADYOUT` high. HMAC-DRBG completes by the 6,000-clock checkpoint and the
point-multiplication program and Montgomery counters advance by 10,000 clocks,
with all three KV client-ready signals high. This rules out an AHB handshake
stall and shows active ECC computation in the bounded window. The captured
hash-guarded overlay spaced generated-driver status reads by 64 clocks; its
traced 2,500,000-clock attempt reached 155,889 clocks, with the Montgomery
counter at 497 after 100,000 clocks, before interruption without a scored
result. The current replay overlay spaces polls by 512 clocks while preserving
the same ready-bit check. Under IEEE 2017 and 2023, this cadence completes the
generated keygen transaction at 717,997 clocks and matches its predicted
result with zero UVM errors/fatals. The two guarded runs retained at least 59%
free memory against a 50% floor. The results are recorded in the
[generated ECC HDL-top evidence](../../evidence/caliptra-bfm-generated-ecc-hdl-20261004/README.md).

The actual SHA-512 controller `hdl_top` and generated `SHA512_random_test`
also run through the clean-room UVMF base. The stock output monitor publishes
one reset-only zero sample before digest reads, yielding 12 scoreboard
mismatches and one leftover actual item; its `TESTCASE PASSED` message is
unconditional. A hash-guarded disposable overlay waits through reset and
captures the next flagged digest in the same monitor call. The resulting
scoreboard matched 13 expected and 13 observed transactions with zero pending
items and zero UVM warnings/errors/fatals. This is limited to that test and
overlay, with generated coverage stubs and seven `eval_object_select`
compile warnings still present. The checkout-relative filelist, logs, and
source hash are recorded in
[generated SHA-512 runtime evidence](../../evidence/caliptra-bfm-generated-sha512-runtime-20261005/README.md).

Build only the manifest-selected surface (or vendor if licensing allows).
Pin behavior with unit tests of the library itself under the real-DPI UVM
driver:
- scoreboard in-order/out-of-order: match, mismatch, extra expected, extra
  actual, leftover at end — each must report the right count and severity;
- proxy/BFM startup order and config-DB handoff, including late registration;
- factory/override behavior of generated-style components.

Gate: tests pass in both editions; each has a negative control that fails when
the behavior is broken; a UVMF-style reference environment (toy DUT,
self-authored in generated style) runs end to end with nonzero traffic and a
scoreboard that is demonstrably able to fail.

### Phase 3 — Protocol agents (one protocol per sub-phase)

For each protocol: agent + monitor + subordinate memory model + self-checks.
- Cross-check against the in-tree Caliptra RTL (`ahb_lite_bus`, AXI fabric,
  `axi_if` tasks) used as an independent counterparty.
- Violation injection: dropped valid, early ready, wrong burst length, ID
  reordering, out-of-range address — monitor/checker must report each.
- Backpressure and stall sweeps; reset-in-the-middle recovery.
- Report agent's own functional coverage with denominators (not only 100%).

Gate: all injection controls detected; no false positives on the in-tree
counterparty; both editions.

Current AHB manager reset-abort coverage (2026-10-09) now forces reset during
single-transfer address wait, single-transfer data wait, and an incrementing
burst. It checks idle outputs, poison-until-reset behavior, and a successful
post-reset read. The guarded standalone regression passes with published
Icarus `4b3f3424c440aca6af92153b6860a7253b925234` under IEEE 2017 and 2023;
this closes those manager reset paths, not the full Phase 3 gate. See
[`AHB BFM regression`](../../dv/caliptra_bfm/ahb_lite/README.md).
The active UVM compatibility path also verifies `response_aborted`, no
completed-item publication on reset, and successful post-reset traffic under
the same published revision; it uses a synthetic target, not generated
Caliptra UVMF. See the
[`AHB UVM reset-abort evidence`](../../evidence/caliptra-bfm-ahb-uvm-reset-abort-main-20261009/README.md).
The standalone AHB and active UVM reset gates also pass on the latest locally
available `iverilog-uvm` `origin/main` SHA
`197f9baece79e66d25524906fb7b54c9faa8f4e2`; a fresh remote-head check was
unavailable because GitHub DNS resolution failed.
**2026-10-09 latest locally available main agent rerun:** the synthetic AXI,
AAXI-compatibility, and AHB UVM-agent smokes also pass on clean
`origin/main` `0d8815febc260928e62d5c2ce82b14afd2e38dc3`, with zero UVM errors
or fatals. Remote DNS remains unavailable; this does not close Phase 3's
protocol-violation and actual-RTL gates. See the
[`0d8815f agent evidence`](../../evidence/caliptra-bfm-uvm-agents-main-0d8815f-20261009/README.md).

### Phase 4 — Unit-level Caliptra/Adams Bridge UVMF environments

Order by the Phase 0 census: units already at "compile pass" first, then the
"setup" units that need only provider mapping (several fail solely on missing
`MLDSA_MEM_ADDR_WIDTH` / include roots — those are parameter/filelist setup
items `[repo]`, not BFM items, and must be classified as such rather than
credited to the BFM).

Per environment, required evidence (AGENTS UVM ladder):
- nonzero intended traffic and request/response activity;
- scoreboard compares performed, count recorded;
- zero unexpected UVM_ERROR/UVM_FATAL;
- no unexplained outstanding objections/transactions;
- normal termination.
A run with zero traffic or an unchecked scoreboard is recorded as failed.

Current-state note (2026-10-09): the standalone packed-member reproduction on
the locally recorded published Icarus `origin/main`
`b452394f148af5a5bcfa744e615f4681d6b80e5e` still loses the generated MLDSA
`RW_READ` field when the 15-bit packed address member is assigned an expression
containing the 32-bit operand counter. The existing preflight correctly stops
before the long keygen run; no QD or pinned RTL workaround is appropriate.
The keygen and its scoreboard readback remain open. See the
[`b452394f preflight evidence`](../../evidence/caliptra-bfm-adams-mldsa-ahb-20261009/README.md#latest-locally-recorded-main-recheck--2026-10-09).

### Phase 5 — Top-level UVMF environments and tests

Only after Phase 4 is stable across a meaningful set. Reconcile with Track A
(shared `axi_if`/mailbox concerns) without letting one lane's results stand in
for the other.

**2026-10-09 full-top diagnostic:** the first short AES/DMA firmware vector
passes through the pinned Caliptra top with the open AXI target and native
checker under the clean locally available `origin/main` build
`197f9baece79e66d25524906fb7b54c9faa8f4e2`. This is one diagnostic vector with
fast TRNG, `.data`/`.bss` preload, and PQ-vector suppression, not full-top or
stock-firmware qualification. See the
[`full-top result`](../../evidence/caliptra-bfm-fulltop-aes-main-197f9ba-20261009/README.md).

**Later 2026-10-09 current-state note:** the locally recorded `origin/main`
advanced to published Icarus SHA
`b452394f148af5a5bcfa744e615f4681d6b80e5e`; GitHub DNS still prevented a fresh
remote-head check. A clean source archive at that SHA was built in temporary
storage and passed the final, 12-beat AES/DMA vector through the open full-top
AXI target and native checker. This remains a one-vector diagnostic using the
same fast-TRNG, `.data`/`.bss` preload, and PQ-vector-suppression modes. The
older 12-case batch on `197f9ba` was stopped before its terminal marker when
the newer local main ref was found and is not counted. See
[`case 12 on Icarus b452394f`](../../evidence/caliptra-bfm-fulltop-aes-case12-main-b452394f-20261009/README.md).

**2026-10-09 latest locally available main rerun:** the same final, 12-beat
AES/DMA vector passes on clean `origin/main`
`0d8815febc260928e62d5c2ce82b14afd2e38dc3` with the native checker enabled.
This remains one diagnostic vector using fast TRNG, `.data`/`.bss` preload,
and PQ-vector suppression; it does not qualify stock firmware or full-top
coverage. GitHub DNS prevented a live remote-head check. See the
[`case 12 on Icarus 0d8815f`](../../evidence/caliptra-bfm-fulltop-aes-case12-main-0d8815f-20261009/README.md).

### Phase 6 — Qualification of the substitute

- Mutation controls over the BFMs and base library (flip a compare, drop a
  response, swap beat order) — each mutant must be caught by at least one test.
- Fingerprints recorded: compiler/runtime hashes, UVM generation mode, corpus
  revisions, seeds, commands, provider mappings.
- Published claim is capped at: "Icarus + recreated BFM, unmodified pinned
  sources, N of M environments at ladder level X, editions Y". Nothing in
  this program qualifies VCS/Questa behavior or IEEE 1800.2 conformance.

---

## 6. Proposed layout

```
dv/caliptra_bfm/                 # open Caliptra BFM components
  uvmf_lite/   (or third_party/uvmf if vendoring is permitted)
  agents/{ahb_lite,apb,axi4}/
  checkers/axi4_protocol_checker/
  providers/   env-var mapping + filelists consumed with -f
  tests/       library self-tests, negative controls, injection controls
docs/conformance/release_overlays/caliptra/   # only for unavoidable source overlays
evidence/caliptra-bfm-<phase>-<date>/         # revision-scoped, hash-recorded
```

Final layout and naming is a Phase 0 decision.

---

## 7. Proposed work items (not selected)

| Proposed ID | Phase | Depends on | Notes |
| --- | --- | --- | --- |
| CALIPTRA-BFM-INVENTORY | 0 | pinned checkouts | Read-only; first and mandatory |
| CALIPTRA-BFM-LICENSE-DECISION | 0 | inventory | Vendor vs recreate gate |
| CALIPTRA-BFM-IDIOM-REDUCERS | 1 | inventory | Reducers only |
| UVMF-LITE-CORE | 2 | decision, idiom results | Base classes + bridge |
| UVMF-LITE-SCOREBOARDS | 2 | CORE | With negative controls |
| UVMF-LITE-REFERENCE-ENV | 2 | CORE, SCOREBOARDS | Toy DUT, end-to-end gate |
| CALIPTRA-VIP-<PROTOCOL> | 3 | REFERENCE-ENV | One per protocol, census order |
| CALIPTRA-AXI4PC-DECISION | 3 | inventory | Unbound-and-report vs real checker |
| CALIPTRA-UNIT-ENV-<NAME> | 4 | protocol agents | One per unit environment |
| CALIPTRA-BFM-MUTATION-QUAL | 6 | all above | Gate for any published claim |

Per AGENTS, "Unrelated discoveries" found along the way go to
`DISCOVERED_DEBT.md`, and compiler work found by Phase 1 or later goes
through its own blocker, not this list.

---

## 8. Risks

- **Inventory may show the surface is large.** Full QVIP is thousands of
  lines; only the consumed subset is built, but a heavily used subset can
  still be large. Phase 0 sizes this before commitment.
- **Behavioral fidelity.** Hidden VIP defaults (response latency, error
  injection defaults, memory fill value) can change test outcomes. Where the
  environment depends on a default, the manifest must record it; unknown
  defaults are listed as assumptions, never silently picked.
- **Compiler blast radius.** Phase 1 may surface blockers in virtual-interface
  identity, interface-task/class interplay, or scale limits. These compete with
  the OpenTitan queue for the one-active-blocker slot.
- **False confidence.** A passing environment on a permissive BFM proves little.
  Phase 6 mutation controls exist to counter this and are not optional.
- **Wall-clock.** The census shows full-top runs are slow (Adams Bridge adders
  dominate: `session_logs/2026-09-28_caliptra_singlecore_compiler_assessment.md`).
  Unit-level environments are the realistic first target; top-level is
  deferred.

## 9. Open questions for the owner

1. The pinned checkout is at
   `/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl`; the read-only
   Phase 0 consumer inventory is recorded in
   `docs/conformance/caliptra_bfm_phase0_inventory_2026-10-03.md` and its
   machine-readable manifest.
2. Is a licensed UVMF 2022.3 copy available locally for *reading* (not
   redistribution), and does its license permit vendoring?
3. QD-EDA/qd-bfm is the identified Apache-2.0 source and is reused as a bounded
   AXI directed helper; it is not a full AXI VIP substitute.
4. The native AXI/AHB slices, completed AXI transaction monitor, FIFO/DMA/
   recovery modules, passive/active UVM AXI paths, and the testbench AXI
   complex replacement pass focused simulations.
   The native and AAXI-style AXI paths perform RAL frontdoor reads/writes and
   connect monitor items to predictor exports; the AHB path performs RAL
   frontdoor reads/writes through the lower-bound MVC compatibility agent and
   now completes a native write/readback against Caliptra's ECC unit RTL.
   UVMF consumer/API integration and full profile qualification remain open.
   The DUT smoke runs one seeded class-generated AXI2AXI scenario, directed
   65-word AXI2MBOX and MBOX2AXI scenarios, and replays all 29 ECC-checked
   DCCM records through the real generator across all five named DMA routes
   and eight short sizes (1, 4, 5, 16, 64, 65, 255, and 256 words), plus a
   maximum 65,536-word FIFO-source stream, one generated fixed-write
   SRAM-to-FIFO profile, and generated recovery profiles for AXI2AXI,
   AXI2MBOX, and AXI2AHB.
   Directed DUT
   cases cover all five routes at 65 words, plus an AXI2AXI SRAM-to-FIFO profile using fixed
   write bursts and weighted channel stalls. The generated replay preserves
   and exercises its delay flag; one record observed five target-stall cycles
   and the generated FIFO destination observed 160. Other default size/flag
   profiles beyond the four directed route FIXED modes, other FIFO modes, and
   firmware reset remain unqualified.
   The generator also stages its default mixed profiles and drives the recovery
   sequencer, but the default size and flag combinations are not replayed through the DUT. AHB2AXI and
   AXI2AHB use component registers and do not exercise an AHB bus. Evidence is in
   [`the all-route run`](../../evidence/caliptra-bfm-dma-all-routes-20261006/README.md).
   **2026-10-08 diagnostic update:** `run_caliptra_axi_dma_top_uvm_bfm.sh
   --default-mixed-replay-only` now replays 25 deterministically seeded stock
   randomizer records through `axi_dma_top`, covering all routes and observed
   FIFO-source, FIFO-destination, fixed-burst, randomized-delay, and recovery-
   block profiles. It excludes reset injection, transfers above 16,384 words,
   and overlapping AXI2AXI SRAM ranges; those remain in their separate lanes.
   All 25 records passed with zero UVM errors on the locally installed Icarus
   binary, but its clean, published revision was not established, so this run
   is diagnostic and does not qualify the profile.
   **2026-10-08 diagnostic update:** the FIFO-destination size sweep now adds
   generated record 68 at 16,384 words, filling the BFM's full 65,536-byte
   FIFO. All nine records passed through `axi_dma_top`; the maximum record
   checked all 16,384 stored payload words and observed randomized stalls, with
   zero UVM warnings, errors, or fatals. This run used Icarus/VVP
   `13.0 (devel) (ac4532fa-dirty)` (`iverilog` SHA-256
   `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114`,
   `vvp` SHA-256
   `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867`).
   Diagnostic only; no clean, published Icarus revision is established.
   **2026-10-09 clean local-main rerun:** all 25 seeded records pass through
   `axi_dma_top` with zero UVM warnings/errors/fatals on the clean build of
   locally available `origin/main` `197f9baece79e66d25524906fb7b54c9faa8f4e2`.
   The remote head could not be refreshed because GitHub DNS resolution
   failed. See the [dated replay evidence](../../evidence/caliptra-bfm-dma-default-mixed-main-20261009/README.md).
   **2026-10-09 HMAC current-state check:** the generated HMAC runtime runner
   stops before simulation on package-qualified parameterized proxy class
   handles when compiled with the same clean local `origin/main` build. This
   is recorded as an Icarus parser blocker without a QD workaround; see the
   [HMAC compile evidence](../../evidence/caliptra-bfm-generated-hmac-runtime-20261005/README.md#current-state-compile-check-2026-10-09).
5. Is a real Axi4PC substitute wanted, or is "unbound, reported absent"
   acceptable for the first qualification claim?

## 10. RAM safety for replay runners

Every retained Caliptra BFM evidence runner that compiles or executes Icarus
enters `scripts/run_with_memory_pressure_guard.py` before starting the work.
The guard samples every 0.25 seconds and stops the complete child process group
when its process group exceeds 4 GB resident memory or system-available memory
falls below 6 GB. This budgets three concurrent agent runs and retains the
system reserve. System availability is counted conservatively from free plus
inactive pages. It fails closed if macOS memory or process telemetry is unavailable.
`CALIPTRA_BFM_MAX_PROCESS_BYTES` and `CALIPTRA_BFM_MIN_AVAILABLE_BYTES` can
override the byte limits. The 26 direct test runners under
`dv/caliptra_bfm/*/tests` source `scripts/caliptra_bfm_memory_guard.sh`, which
applies the same limits with a 300-second default bound. The generated SoC-IFC runtime streams VVP output to a
retained evidence log and suppresses only the repetitive volatile-register
mirror warning; scoreboard errors remain visible and fail the probe.
Percentage settings in dated evidence command snapshots record the earlier
guard behavior; current runners ignore `CALIPTRA_BFM_MIN_FREE_PERCENT`.
The SoC-IFC generated-environment/package lanes use a 300-second bound; the
other BFM replay lanes use a 600-second bound. Direct ad hoc compiler commands
should use the same guard explicitly. The wrappers do not change compiler
arguments or simulation inputs; existing evidence logs were not regenerated
by this safety-only update, so their recorded command hashes remain historical.

## 2026-10-09 current-state addendum

A live remote-head query confirmed `iverilog-uvm` `main` remains at published
SHA `0d8815febc260928e62d5c2ce82b14afd2e38dc3`, matching the clean simulator
build already used by current BFM evidence. The AXI and AHB standalone checker
regressions were rerun on that build and rejected all 41 and 11 injected
violations, respectively. See the [latest-main checker evidence](../../evidence/caliptra-bfm-protocol-checkers-main-0d8815f-20261009/README.md).

### Generated KeyVault on latest published main

The generated KeyVault four-beat AHB probe was checked against the same live-
verified published Icarus `main` SHA `0d8815febc260928e62d5c2ce82b14afd2e38dc3`.
Compilation still stops at package-qualified proxy declarations in the
generated read/write driver and monitor BFMs, before simulation. No QD
workaround was added. See the [current KeyVault result](../../evidence/caliptra-bfm-keyvault-main-0d8815f-20261009/README.md).

### Standalone checker edition coverage

The AHB checker runner now selects IEEE 2012 (default), 2017, or 2023 with
`SV_EDITION`; invalid selections fail before compilation. On published Icarus
`0d8815febc260928e62d5c2ce82b14afd2e38dc3`, both AXI and AHB checker suites
pass under IEEE 2017 and 2023, rejecting all 41 and 11 injected violations
per run. This verifies standalone checker behavior across editions, not the
remaining actual-Caliptra protocol-agent gate. See the [cross-edition checker
evidence](../../evidence/caliptra-bfm-protocol-checkers-main-0d8815f-20261009/README.md#cross-edition-rerun--2026-10-09).

### Generated-name AHB compatibility on latest published main

The AHB QVIP-compatible clean-room environment passed its synthetic-target
burst/scoreboard smoke on published Icarus `0d8815febc260928e62d5c2ce82b14afd2e38dc3`
for 32-bit and 64-bit profiles under IEEE 2017 and 2023. Each run checked
12 transfers with no UVM errors or fatals. This advances provider compatibility
coverage only; generated Caliptra KeyVault still stops at the simulator parser
blocker above. See the [latest-main AHB compatibility evidence](../../evidence/caliptra-bfm-ahb-qvip-compat-main-0d8815f-20261009/README.md).
