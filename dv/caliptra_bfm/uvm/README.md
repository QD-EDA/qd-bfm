# Caliptra AXI UVM adapter

## RAM guard for large simulator runs

All Caliptra BFM test runners under `dv/caliptra_bfm/*/tests` use
`scripts/run_with_memory_pressure_guard.py`. On macOS it samples every 0.25
seconds and stops a command if its process group exceeds 6 GiB resident memory,
or system-available memory falls below a 6 GiB reserve. Available memory is
measured conservatively as free plus inactive pages. It fails closed when host
memory or process telemetry is unavailable. Set
`CALIPTRA_BFM_MAX_PROCESS_BYTES`, `CALIPTRA_BFM_MIN_AVAILABLE_BYTES`, or
`CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS` to adjust the byte limits or
timeout. For standalone heavy commands, use:

```sh
python3 scripts/run_with_memory_pressure_guard.py \
  --max-process-bytes 6442450944 --min-available-bytes 6442450944 \
  --timeout-seconds 300 \
  --log /tmp/caliptra-bfm.log -- \
  sh dv/caliptra_bfm/uvm/tests/run_aaxi_compat.sh
```

Set `IVERILOG_BIN` and `VVP_BIN` for the local UVM-enabled Icarus fork as
required by each run script. The runner reports the minimum observed available
memory and maximum observed resident memory for the process group.

For a bounded full-top `rand_test_dma` reset diagnostic, use
`--rand-dma-iterations 1 --force-first-rand-dma-reset`. The optional
`--rand-dma-reset-delay-cycles N` fixes the testbench warm-reset wait to 5–1023
cycles in a hash-checked temporary overlay; without it, Caliptra's weighted
random delay is unchanged. For example:

```sh
sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh \
  --case rand_test_dma --rand-dma-iterations 1 \
  --force-first-rand-dma-reset --rand-dma-reset-delay-cycles 512 \
  --output /private/tmp/caliptra-rand-dma-reset-probe
```

The diagnostic remains subject to the same 60% memory floor. It does not
qualify warm-reset recovery until the firmware resumes and the run finishes.

## PCRVault client agent

`pv_caliptra_uvm_pkg.sv` adds a native UVM transaction, sequencer, active
driver, completion monitor, and agent for the PCRVault crypto-client path. The
driver sends requests through `pv_caliptra_master_cmd_if.sv`;
`pv_caliptra_uvm_master_proxy.sv` invokes the standalone
`pv_caliptra_master.sv`, preserving its bounds checks, reset-abort behavior,
and response sampling. The monitor publishes completed command-boundary
transactions containing the returned data, `last`, and status. It samples
responses returned from the connected PV pins; it cannot act as an independent
raw-pin read monitor because PV reads have no explicit request-valid signal.

The actual-RTL smoke uses a UVM sequence to write and read all dword offsets
of a PCR entry, reject an invalid dword offset, and confirm reset-abort response
handling. It checks sequence responses and monitor records against the pinned
PCRVault RTL. Run
`evidence/caliptra-bfm-pv-uvm-actual-rtl-20261004/run.sh` with
`IVERILOG_BIN` and `VVP_BIN` set to the fork's UVM-capable executables. The
command interface and UVM package are included in `caliptra_bfm_uvm.f`; include
the proxy module after Caliptra's `pv_defines_pkg.sv` and standalone PV master.

`axi4_caliptra_uvm_pkg.sv` provides clean-room UVM transaction classes, an
active sequencer/driver path, and a passive monitor adapter. The passive monitor
samples completed records produced by `axi4_caliptra_transaction_monitor.sv` on
the falling clock edge, then publishes read and write objects through
its native `ap` analysis port. In standalone mode it also publishes a second
`aaxi_master_tr` stream on `aaxi_ap`.

The transaction class exposes direction (`kind`, `is_read()`, `is_write()`),
address/control, ID and response, USER, first-beat `data`, full `beatQ`, write
strobes, per-beat USER/response/LAST queues, and monitor protocol status. It
implements UVM object copy/compare/print hooks. `caliptra_aaxi_compat_pkg.sv`
adds a clean-room lower-bound `aaxi_uvm_pkg::aaxi_master_tr` with the fields
and methods visible in Caliptra's SoC-IFC consumers. The `aaxi_ap` stream
projects completed monitor items into that type. It also supplies a lower-
bound `aaxi_uvm_mem_adapter`, `aaxi_uvm_reg_predictor`, and active
`axi4_caliptra_aaxi_uvm_agent` with an `aaxi_uvm_sequencer`. The monitor
publishes Caliptra's observed `ms_tx_AW_W_export`, `ms_rx_rvalid_export`,
`write_done_export`, and `read_done_export` ports. The write request port
publishes the assembled AW/W request after all W beats are accepted and before
B; `write_done_export` publishes after B. Read request and done ports publish
the assembled read on the final R beat. A focused smoke checks that write
request precedes write completion. Avery's object reuse, partial snapshots,
read granularity, and exact timing remain unverified. The active AAXI path
drives the same AXI manager as the native `axi4_caliptra_uvm_agent`.

The active UVM smoke checks projected SRAM and SLVERR
items through `copy`, `compare`, and `sprint`, including USER and LOCK fields;
the DMA smoke also checks FIFO and 256-beat items. The test also checks
`type_id::create`, UVM cloning, and that a kind mismatch fails comparison
without changing the source. These tests validate the fallback's observed
lower-bound surface, not full Avery behavior.
The two-beat readback uses an ordinary write. The active native UVM agent also
checks successful and invalidated exclusive accesses through the SRAM target;
both UVM register adapters map `EXOKAY` to success. Standalone AXI target tests
cover failed exclusive stores and multi-beat locks.
See the [guarded native agent regression](../../../evidence/caliptra-bfm-uvm-agent-20261005/README.md).
Define `CALIPTRA_BFM_EXTERNAL_AVERY` or omit the fallback file when the
licensed Avery package is present.

`caliptra_aaxi_uvmf_compat_pkg.sv` adds the generated component path
`aaxi_tb.env0.master[0]` and its observed `driver.cfg_info`, sequencer, and
analysis ports. Its active and passive agents both construct and connect a
pin-record monitor; only active agents construct a sequencer and pin driver.
The driver configuration initializes `passive_mode` from the agent's active
state, while generated environment assignments can override that field. The
focused generated-path smoke uses Caliptra's actual
`axi_if` and DMA SRAM subordinate for a write/read round trip. By default,
`aaxi_monitor_wrapper` installs the command VIF and embeds the existing open
task-based AXI manager proxy, so the generated-path sequencer drives its AAXI
pins directly. The test checks configured bus width and both pin-derived
completed monitor records. Run
`tests/run_aaxi_compat.sh`. This verifies the observed component names and a
working open bus path for the active master. The generated AAXI pins are the
live bus path; the checker accepts both read/write handshakes and the active
and passive monitors each publish both completed records. The smoke also
checks that the passive agent has neither a sequencer nor a pin driver and
that its configuration reports passive mode. The smoke exercises the `ports`
virtual-interface config path installed by the wrapper. It does not instantiate
the generated `soc_ifc_environment` or `hdl_top`, verify their
`intf_uc`-to-driver handoff at runtime, or reproduce Avery's lifecycle.
The captured run and RAM guard details are in
[`AAXI active/passive smoke evidence`](../../../evidence/caliptra-bfm-aaxi-compat-20261004/README.md).

The same hierarchy also has an actual-RTL SoC-IFC run: its UVM sequence writes
and reads `CPTRA_MBOX_VALID_AXI_USER[0]` through
`soc_ifc_top.s_axi_if`, while the AHB manager runs the real DMA success and
injected-`SLVERR` cases. Run
`evidence/caliptra-bfm-soc-ifc-dma-runtime-20261004/run_uvm.sh`. This uses the
clean-room generated-name hierarchy and open manager, not Caliptra's full
generated UVMF environment or licensed Avery agent. The evidence README
records the pinned DUT, commands, and results.

The filelist also provides a 64-bit-address/32-bit-data/8-bit-ID
`aaxi_pkg`/`aaxi_intf` profile, matching the generated SoC-IFC manager's visible
configuration, and maps `aaxi_monitor_wrapper` to the open Caliptra AXI
protocol checker and completed-transaction monitor. The wrapper installs the
monitor's record interface in UVM config DB, so the active compatibility agent
publishes transactions sampled from those pins. The smoke exercises this path
for completed writes and reads. The generated-only `aaxi_pkg_xactor`,
`aaxi_pll`, and `rw_txn_pkg` namespaces are empty import shims;
`aaxi_pkg_test` defines only the observed constructor-only `aaxi_log`. These
do not implement the corresponding library APIs. The manager-event monitor
publishes the assembled write request after AW and all W beats are accepted,
before B, then publishes write completion after B. Read request and done
events publish the assembled record on the final R beat. Focused smoke checks
cover this fallback ordering: the read-valid export carries the complete read
on final R, its timestamp matches read-done, and mutating its record does not
affect the independently cloned read-done record. The same smoke checks write
request precedes write completion. Avery's partial-item lifecycle, read
granularity, and exact timing remain unverified.

`axi4_caliptra_record_if.sv` carries completed records into the class monitor.
Its fixed record storage can represent the full AXI4 ID field (8 bits) and
256-beat `LEN` range; this is storage capacity, not the width of every
connection. WSTRB is packed with four bits per beat, matching the 32-bit data
width. Interface widths remain parameterized; the pinned Caliptra DMA
connection uses a 48-bit address, 32-bit data/USER, and 5-bit ID. Normal DMA
requests are capped at 256 bytes (64 beats) by its FIFO sizing.

`axi4_caliptra_uvm_agent` packages the monitor and, in active mode, the
`axi4_caliptra_uvm_sequencer` and `axi4_caliptra_uvm_driver`. It publishes the
monitor stream on its `ap` analysis port. The active path uses
`axi4_caliptra_uvm_transfer` items. The driver hands commands through
`axi4_caliptra_master_cmd_if.sv` to
`axi4_caliptra_uvm_master_proxy.sv`, which invokes the standalone task-based
manager. The basic active smoke writes and reads a two-beat INCR burst against
the bounded SRAM subordinate at Caliptra's DMA SRAM base. The DMA-target UVM
run connects the same manager to the full SRAM/FIFO address map and sends an
additional fixed-burst write and read through the FIFO window. Both runs check
completed monitor records, USER values, strobes, LAST positions, IDs, and
responses. An injected SLVERR confirms the active driver returns
`success == 0` with the AXI response code intact while the monitor still
reports valid transaction framing.
The active test also performs UVM RAL frontdoor traffic through both the
native transfer adapter and the AAXI compatibility sequencer/adapter, then
checks that both AAXI predictor exports update the register model. Its two
injected SLVERR observations produce the expected UVM `PREDICT_NOK` warnings;
the smoke ends with zero UVM errors and fatals.

`tests/run_uvm_axi_if.sh` binds the UVM manager proxy directly to Caliptra's
actual `axi_if` signals, connects the open DMA target through the `w_sub` and
`r_sub` modports, and samples the same interface through the passive UVM
monitor. It checks SRAM and FIFO traffic plus a full 256-beat SRAM
write/readback and an injected `SLVERR` read in the monitor analysis stream.
This is interface/target integration evidence; it does not instantiate the
Caliptra DMA engine. Tool and source hashes are recorded in
[`evidence/caliptra-bfm-axi-uvm-if-20261004`](../../../evidence/caliptra-bfm-axi-uvm-if-20261004/README.md).

`tests/run_caliptra_axi_mgr_uvm_bfm.sh` uses Caliptra's pinned `axi_mgr_rd` and
`axi_mgr_wr` RTL as initiators. Their real internal request interfaces drive
5-bit-ID AXI traffic through the open SRAM/FIFO target on `axi_if`; the passive
UVM adapter checks completed transactions. The read/write manager assertions
are compiled with the default Caliptra assertion macros. This exercises the
Caliptra AXI manager datapath with the recreated target, but omits the DMA
control FSM and full `axi_dma_top`.

`tests/run_caliptra_axi_dma_top_uvm_bfm.sh` goes one layer higher: it instantiates
the pinned `axi_dma_top` with its real CSR/register block, control FSM, and AXI
managers, then connects the DMA `axi_if` to the same open SRAM/FIFO target and
passive UVM monitor. It compiles Caliptra's DMA transfer randomizer with a
temporary one-line Icarus `$fatal` compatibility rewrite, then drives its
seeded 65-word AXI-to-AXI scenario through the component request interface.
The scoreboard checks boundary-limited read/write bursts and randomized
payload. Its second run injects AXI `SLVERR`, verifies the DMA error state and
both response records, then checks the partial destination prefix and untouched
tail. A third run drives a directed 65-word FIFO-to-SRAM recovery case with the
pinned class's valid `test_block_size` tuple, the generated block-size array,
FIFO auto-fill, and the real `recovery_data_avail` input. The UVM scoreboard
checks five fixed FIFO reads, five incrementing SRAM writes, and end-to-end
payload equality. Icarus rejected this recovery tuple under the pinned class
constraints, so this one tuple is directed rather than randomized. This
is focused DMA-block integration, not a full Caliptra top or firmware test.
The runner's `+RESET_ABORT` profile holds B and waits until the real DMA DUT
accepts AW and the final W beat before reset. It checks the pending B is
discarded, target queues clear, only the accepted first-burst data remains in
SRAM, and the UVM monitor publishes no aborted write. It then reprograms the
DUT and checks a complete 65-word transfer after reset. Run this focused case
with `tests/run_caliptra_axi_dma_top_uvm_bfm.sh --reset-abort-only`. This
block-level reset test does not run Caliptra's firmware-triggered warm-reset
service.
The reset run is recorded in
[`DMA reset-abort evidence`](../../../evidence/caliptra-bfm-dma-reset-abort-20261006/README.md).
The current generated-DUT run instantiates Caliptra's actual testcase
generator, selects each of 29 DCCM records in a separate simulation, checks the
staged metadata and payload ECC, and replays each profile through the DUT and
UVM monitor. The hash-guarded profile covers all five generated DMA route
types, eight short sizes (1, 4, 5, 16, 64, 65, 255, and 256 words), a maximum
65,536-word fixed-read FIFO-to-SRAM stream, a 16,384-word maximum checked SRAM
payload on AXI2AXI, a 65-word fixed-write SRAM-to-FIFO case with randomized
delays, and a 65-word FIFO recovery case with a generated block. Both maximum
payload streams check all destination words; the FIFO stream also drains its
source. The max-size SRAM profile uses disjoint source/destination ranges.
The opt-in `--fixed-sram-modes-only` runner extends the generated record set to
32 and replays 65-word AXI2AXI SRAM transfers with FIXED reads, FIXED writes,
and both channels FIXED. Its scoreboard checks repeated burst addresses, beat
payloads, and final SRAM locations.
Generated recovery records sweep every legal one-hot block size: 4–64 bytes
for AXI2AXI and 4–2048 bytes for AXI2MBOX and AXI2AHB. Recovery checks the
generated FIFO reads and end-to-end route output; see the
[`generated recovery route evidence`](../../../evidence/caliptra-bfm-dma-routed-recovery-sweep-20261006/README.md).
The generated AXI2AXI recovery record also passes through the real DMA DUT in
not-empty, threshold, and pulse availability modes, with the bench checking the
selected policy; see the
[`recovery availability mode evidence`](../../../evidence/caliptra-bfm-dma-recovery-availability-modes-20261007/README.md).
The normal-size generated FIFO-source profile also now passes 65-word AXI2AXI,
AXI2MBOX, and AXI2AHB transfers through the real DUT. The FIFO producer and
consumer counts must match, and output data is checked in SRAM, the mailbox
request stream, or the component data register. Each route observed randomized
target stalls; see the
[`generated FIFO-source route evidence`](../../../evidence/caliptra-bfm-dma-fifo-source-routes-20261007/README.md).
The AXI2AXI, AXI2MBOX, and AXI2AHB FIFO-source lanes now each pass generated
transfers of 1, 4, 5, 16, 64, 65, 255, and 256 words through the real DUT. Each
run checks FIFO drain, route payload, and randomized target stalls; see the
[`FIFO-source size-sweep evidence`](../../../evidence/caliptra-bfm-dma-fifo-source-size-sweep-20261007/README.md).
Generated SRAM-to-FIFO transfers also pass at all eight sizes. The runner
checks fixed-write transactions, randomized stalls, and every queued FIFO word;
see the [`FIFO-destination size-sweep evidence`](../../../evidence/caliptra-bfm-dma-fifo-destination-size-sweep-20261007/README.md).
Other generated FIFO mode/flag combinations and firmware-triggered reset injection remain
unqualified. Directed
65-word cases now cover all five
DMA routes through the real DUT. AXI2MBOX and MBOX2AXI apply one-cycle mailbox
backpressure and check request addresses and payload data. AHB2AXI enters words
through the component `WRITE_DATA` register; AXI2AHB drains through `READ_DATA`.
These two lanes use the register-side component interface, not an AHB bus.
The same DUT runner also writes 65 SRAM words to the AXI FIFO in five fixed
bursts under Caliptra's weighted random-delay profile; it checks observed
backpressure and every queued payload word. Other sizes/flags remain open.
Earlier source/tool hashes are in
[`evidence/caliptra-bfm-caliptra-dma-top-20261004`](../../../evidence/caliptra-bfm-caliptra-dma-top-20261004/README.md);
the recovery run is recorded in
[`evidence/caliptra-bfm-dma-recovery-top-20261006`](../../../evidence/caliptra-bfm-dma-recovery-top-20261006/README.md).
The earlier DCCM replay is recorded in
[`evidence/caliptra-bfm-dma-generator-dut-replay-20261006`](../../../evidence/caliptra-bfm-dma-generator-dut-replay-20261006/README.md).
The latest all-route run is recorded in
[`evidence/caliptra-bfm-dma-all-routes-20261006`](../../../evidence/caliptra-bfm-dma-all-routes-20261006/README.md).
The generated FIFO destination and recovery block are recorded in
[`FIFO-destination evidence`](../../../evidence/caliptra-bfm-dma-generated-fifo-destination-20261006/README.md)
and [`recovery-block evidence`](../../../evidence/caliptra-bfm-dma-generated-recovery-block-20261006/README.md).

`tests/run_caliptra_dma_testcase_generator_bfm.sh` separately runs Caliptra's
actual `dma_testcase_generator` for 25 iterations, captures its DCCM writes in
a bounded shadow, validates ECC and metadata across the complete 25-case
record stream, and checks that the real recovery sequencer consumes nonzero
generated entries. The current DUT runner replays all 27 records across the
five constrained route types, including the maximum 65,536-word FIFO-source
stream, a generated FIFO-destination profile, and a generated 64-byte recovery
block profile. Other default size and flag combinations remain open.
Hashes are in
[`evidence/caliptra-bfm-dma-generator-20261006`](../../../evidence/caliptra-bfm-dma-generator-20261006/README.md).

## UVM register frontdoor

`axi4_caliptra_uvm_reg_adapter` maps scalar 32-bit UVM register reads and
writes to one-beat AXI4 INCR transfers with 48-bit addresses, ID zero, and
four byte enables mapped to WSTRB. The
`axi4_caliptra_uvm_user_extension` supplies AWUSER/ARUSER; absent an extension,
the adapter uses all ones. `bus2reg` maps read data, byte enables, and AXI
response status back to the register operation, including `SLVERR` as
`UVM_NOT_OK`. The active smoke runs real UVM RAL frontdoor write/read
operations with an extension and verifies an injected `SLVERR` read returns
`UVM_NOT_OK`. The separate AAXI adapter maps the same USER extension through
`aaxi_master_tr`, making the lower-bound AAXI sequencer usable for a
Caliptra-style RAL map. For prediction callbacks, `bus2reg_user_obj` retains the
AWUSER/ARUSER value from the most recent bus item. This is a native adapter
for the BFM transfer item. The separate AAXI-style adapter subclasses the
clean-room fallback `aaxi_uvm_mem_adapter`; it is not Avery's implementation,
and passing monitor records to the fallback predictor does not reproduce
Caliptra's full generated environment.

The UVM source list is `caliptra_bfm_uvm.f`. Each smoke uses
`IVERILOG_BIN`/`VVP_BIN` when set and otherwise resolves `iverilog`/`vvp` from
`PATH`. Point the variables at an Icarus build with this fork's `-uvm` support
before running; the system Icarus installation may not include it:

```sh
export IVERILOG_BIN=/path/to/iverilog
export VVP_BIN=/path/to/vvp
./dv/caliptra_bfm/uvm/tests/run_uvm_adapter.sh
./dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh
./dv/caliptra_bfm/uvm/tests/run_uvm_dma_agent.sh
./dv/caliptra_bfm/uvm/tests/run_uvm_axi_if.sh
./dv/caliptra_bfm/uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh
./dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
./dv/caliptra_bfm/uvm/tests/run_caliptra_dma_testcase_generator_bfm.sh
```

The passive test checks native UVM analysis publication for one read and one
write, field mapping, object copy/compare/printing, and zero UVM errors. The
active tests check native and projected AAXI burst read/write, UVM RAL
frontdoor read/write, and injected SLVERR through the manager proxy and SRAM
path; the DMA run checks the FIFO and 256-beat projections as well. The test
also passes `item.kind` directly to the
compatibility `compare`, matching the class-member argument form used by the
pinned Caliptra scoreboard.
These are native UVM adapters and lower-bound compatibility surfaces, not a
full UVMF environment, a full Avery agent, or a Caliptra DUT regression.

## AHB-Lite Caliptra adapter

`ahb_lite_caliptra_pin_monitor_adapter` connects raw 32-bit-address/64-bit-data
AHB-Lite pins to `ahb_lite_caliptra_record_if`. The AHB smoke uses this adapter
between its manager/subordinate pins and UVM record interface, covering the
pin-to-record step needed by Caliptra's passive QVIP monitor path.

The native AHB monitor keeps its `ahb_lite_caliptra_transaction` `ap` stream
and also publishes the observed Caliptra consumer streams through
`burst_transfer_ap`, `burst_transfer_sb_ap`, and `burst_transfer_cov_ap`. The
`ahb_lite_caliptra_qvip_compat_agent` maps those streams onto the observed
keyed `ap["burst_transfer"]`, `ap["burst_transfer_sb"]`, and
`ap["burst_transfer_cov"]` ports and exposes the active sequencer as
`m_sequencer`, which is a clean-room `mvc_sequencer` carrying the observed
MVC transaction base type. Its active path accepts 1..256 queue entries and
drives one item as NONSEQ followed by SEQ beats through the directed manager
proxy. The native `ahb_lite_caliptra_reg_adapter` maps scalar UVM register
operations onto one-entry `ahb_master_burst_transfer` items, including subword
bus-lane formatting and AHB ERROR to `UVM_NOT_OK` status mapping. Its bus width
defaults to 64 bits for the Caliptra SoC-Lite profile; `set_bus_data_width(32)` selects
the 32-bit ECC unit profile. The memory-backed smoke performs 32-bit RAL
frontdoor writes/reads and confirms an injected ERROR is reported. A separate
three-edition smoke runs both direct UVM sequence traffic and 32-bit RAL
frontdoor read/write through the actual Caliptra ECC unit. Each analysis stream
carries a clean-room
`ahb_master_burst_transfer #(1, 1, 1, 32, 64, 64)` derived from
`mvc_sequence_item_base`, with `RnW`, `address`, `size`, bounded `data` and
`resp` queues, plus `copy`, `compare`, and `convert2string`. The monitor groups
contiguous accepted SEQ beats with matching direction and size, ending an item
at an accepted IDLE/NONSEQ boundary or after 256 beats. HBURST is absent, so
item boundaries are inferred from accepted address phases. Each output is a
separate object because Caliptra predictors copy and mutate queue data.
The pin proxy zero-fills its fixed 256-lane response vector and copies only
completed beats into it, keeping scalar register access proportional to the
actual transfer count while preserving partial-ERROR lane contents.
`tests/run_ahb_lite_uvm_agent.sh` exercises four-beat MVC write/read traffic, a
first-beat ERROR abort, and a partial burst with one successful beat followed
by ERROR; unissued beats remain unchanged. The focused Icarus 2012 run passes
with zero UVM warnings, errors, or fatals. The generated-
name active/passive smoke also carries four-beat items through all three keyed
streams; Icarus reports the expected warning that proprietary internal QVIP
covergroups are not recreated. See
[`AHB QVIP compatibility evidence`](../../../evidence/caliptra-bfm-ahb-qvip-compat-20261004/README.md).

`caliptra_ahb_qvip_compat_pkg.sv` adds the consumer-facing names
`qvip_ahb_lite_slave_params_pkg`, `qvip_ahb_lite_slave_pkg`,
`qvip_ahb_lite_slave_env_configuration`, and
`qvip_ahb_lite_slave_environment#()`. Its configuration accepts the observed
three `set_monitor_item` keys and rejects unknown keys or item types; enabling
scoreboard/coverage streams connects those real monitor outputs. The
environment exposes `ahb_lite_slave_0.ap[string]` and `m_sequencer`, and maps
Caliptra's active/passive setting onto the existing UVM manager wrapper. The
fallback parameter package is pinned to the observed 32-bit address, 64-bit
data AHB profile.

`ahb_lite_caliptra_qvip_hdl.sv` provides a clean-room module named
`hdl_qvip_ahb_lite_slave` with the internal wire names referenced by the
pinned Caliptra generated `hdl_top.sv`. It registers the local
`ahb_lite_caliptra_record_if` and, in active mode,
`ahb_lite_caliptra_master_cmd_if` under the observed
`UVMF_VIRTUAL_INTERFACES` keys. The focused generated-style smoke instantiates
this HDL wrapper in active and passive modes, configures the QVIP-named
environment and all three analysis streams, then checks real AHB write/read
traffic against a synthetic memory target. For other harnesses, register the
same local interfaces with the configured name and `.cmd` suffix, or call
`set_bfms` on the fallback config. Environment build reports a fatal if a
required interface is missing.

This preserves the generated module/hierarchy contract and exercises it in a
standalone harness. Since that smoke was added, the replacement has also been
compiled in generated PCRVault, KeyVault, and SoC-IFC environments. The
generated PCRVault and KeyVault block tests exercise scalar AHB RAL traffic
against their actual RTL. The SoC-IFC generated runtime qualifies reset, AAXI,
and selected active-AHB RAL/mailbox lanes against actual RTL; other generated
AHB sequences and full coverage remain unqualified. The full Caliptra top and
Adams Bridge top remain unqualified. See the
[PCRVault](../../../evidence/caliptra-bfm-pv-generated-uvmf-20261004/README.md),
[KeyVault](../../../evidence/caliptra-bfm-keyvault-generated-hdl-20261004/README.md),
and [SoC-IFC](../../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md)
runtime evidence. The clean-room files do not recreate the proprietary
`mgc_ahb` virtual interface, QVIP sideband behavior, policies/sequences,
internal covergroups, full MVC, or the UVMF base library. For licensed
providers, define
`CALIPTRA_BFM_EXTERNAL_AHB_QVIP`, `CALIPTRA_BFM_EXTERNAL_MVC`, and
`CALIPTRA_BFM_EXTERNAL_UVMF`, or use a provider-specific filelist that selects
one implementation of each package and HDL module. The generated-style smoke
runner is `tests/run_ahb_qvip_compat_env.sh`; it has passed under Icarus
SystemVerilog editions 2012, 2017, and 2023. Evidence and hashes are recorded
in `evidence/caliptra-bfm-ahb-qvip-compat-20261004/README.md`.

The Adams Bridge ML-DSA YAML includes `ap_key: "trans_ap"` with a placeholder
comment, but its checked-in generated `mldsa_environment.svh` omits that
connection. The generated environment instead connects `ap["burst_transfer"]`
to the predictor and `ap["burst_transfer_sb"]` to the scoreboard; no generated
source references `trans_ap`. Those real keys are provided here, so no fake
`trans_ap` stream is needed. The checked-in Adams Bridge environment package,
predictor, scoreboard, and RAL package now compile with the clean-room provider
through `tests/run_adams_mldsa_env_compile.py`. Its actual generated HDL top
also passes a focused runtime against `abr_top`: the generated RAL frontdoor
writes one seed word at `0x58` and reads `MLDSA_VERSION` at `0x8`, receiving
`0x302e322e` over 32-bit AHB with zero UVM errors, fatals, or scoreboard
mismatches. The generated predictor and scoreboard intentionally skip
version-register comparisons, so this probe checks both RAL frontdoor paths
and the absence of unexpected mismatches; it does not qualify MLDSA signing,
KAT, error-path, or full-top behavior. Its checked-in
`qvip_ahb_lite_slave_params_pkg.sv` sets one master, one slave, 32-bit address,
and 32-bit write/read data. Compile the clean-room provider with
`+define+CALIPTRA_BFM_AHB_32BIT` for this environment; the default Caliptra
profile remains 64-bit. Set `AHB_PROFILE=32` when invoking
`tests/run_ahb_qvip_compat_env.sh` to exercise the 32-bit MVC item and packed-
beat path. The generated predictor and
scoreboard cast items to the parameterized `ahb_master_burst_transfer` type;
they use `RnW`, `address`, `data[0][31:0]`, `resp[0]` (for mismatch reporting),
and `convert2string()`. The clean-room item exposes those fields and method.
The generated MLDSA filelists already name the current `abr_*` RTL paths; the
five stale paths elsewhere in Adams Bridge belong to separate unit-test
filelists and are not this environment's blocker.

The same runner now has an opt-in `--actual-keygen-smoke` path. It builds the
pinned native reference helper in a temporary directory, writes all eight seed
words through generated RAL, observes `abr_top` busy/ready around keygen, then
reads one public-key and one private-key word through RAL for predictor
scoreboard comparison. This path remains unqualified: the first simulation
reached the reference helper but timed out during repeated status-register
polling. The revised busy-signal harness compiles against the full actual-RTL
file list. Its runtime launched generated keygen, then the 60% memory guard
stopped it at 59% free before key readback. The normal `--actual-rtl-smoke`
passed in the previous checkpoint; the updated shared runner has not been
rerun in that mode. Keygen uses a 600-second default timeout and the same 60%
free-memory floor. The current harness flushes `keygen_progress.log` every
10,000 observed cycles so a guard stop records whether the DUT stayed busy.

`caliptra_ahb_mvc_compat_pkg.sv` supplies fallback definitions for only these
visible types, including `ahb_rnw_e` with `AHB_READ`/`AHB_WRITE`, and the
transfer-size/response constants. This is clean-room
compatibility scaffolding, not an implementation of MVC, QVIP policies, or the
full AHB transaction class. When
compiling with licensed packages, exclude this file or
define both `CALIPTRA_BFM_EXTERNAL_MVC` and `CALIPTRA_BFM_EXTERNAL_AHB_QVIP`.
The compatibility wrapper supplies the observed keyed port names and
lower-bound sequencer/driver/register-adapter path. The clean-room generated
configuration/environment shim provides the observed setup surface and
stream switches, but not the full QVIP coverage model or policy. The focused
AHB UVM smokes exercise generated-style active/passive streams and the RAL
path with read, write, wait-state, and ERROR traffic, and check that configured
predictor/scoreboard/coverage outputs are separate objects.
