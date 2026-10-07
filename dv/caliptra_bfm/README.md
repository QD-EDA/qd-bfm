# Open Caliptra BFM source set

This BFM source set is licensed under Apache-2.0; see [`LICENSE`](LICENSE).

The combined source list is [`caliptra_bfm.f`](caliptra_bfm.f). Invoke it from
the repository root and append the selected testbench/top and simulator
options. It contains the standalone AXI4 and AHB-Lite modules documented in
[`axi/README.md`](axi/README.md) and
[`ahb_lite/README.md`](ahb_lite/README.md), including the Apache-licensed
QD-EDA single-beat AXI seed. WD's `axi-vip` is retained as a research
reference; it is not the Caliptra-profile implementation because its observed
interface omits LOCK and the Icarus integration probe does not pass. The
source review is in the
[`Caliptra BFM research note`](../../docs/conformance/caliptra_bfm_research_2026-10-03.md).

Caliptra-specific integrations go in
[`caliptra_bfm_caliptra_if.f`](caliptra_bfm_caliptra_if.f). It now includes a
bounded synchronous mailbox SRAM subordinate using the pinned
`soc_ifc_pkg::cptra_mbox_sram_req_t` and `cptra_mbox_sram_resp_t` contract; see
[`mailbox/README.md`](mailbox/README.md). The opt-in generated SoC-IFC
attachment passes four-word host-to-SRAM probes through AAXI and generated AHB
RAL. Both routes pass single- and double-bit injection through the generated
agent's live configuration. The AHB route's post-lifecycle runs check the
injected word and the three unaffected words in SRAM; see the
[`generated-runtime evidence`](../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md).
The generated AHB/AAXI response path passes without ECC, with single-bit ECC,
and with deterministic double-bit ECC. The double-bit run scores 27/27
transactions; its disposable predictor overlay suppresses duplicate status
expectations while the non-fatal interrupt remains asserted.
The complete response path also passes with Caliptra's stock AXI USER
initialization enabled: the SoC AXI host uses the programmed MBOX valid-user
slot, and no-ECC, single-bit ECC, and double-bit ECC runs score 38/38, 38/38,
and 39/39 with zero UVM errors/fatals. The larger Caliptra firmware and full
top remain unqualified.

The AXI files provide a USER/LOCK-capable manager that allows one read and one
write to proceed concurrently, with one outstanding operation per direction,
a profile checker, bounded SRAM and FIFO subordinates, combined DMA map,
channel monitor, and bounded completed-transaction records. The AHB-Lite files provide a directed
manager, passive monitor, profile checker, and bounded SRAM subordinate.
`axi4_caliptra_recovery_avail.sv` models three recovery-data availability
policies and is instantiated by the combined DMA subordinate.
The typed interface list also includes `caliptra_top_tb_axi_complex_bfm.sv`,
a drop-in replacement for Caliptra's testbench module of the same name. It
maps `axi_complex_ctrl_t` FIFO/recovery fields, supplies independent weighted
channel stalls for `rand_delays`, and implements the one-shot
`ERR_RESP_START_ADDR`/`ERR_RESP_END_ADDR` `SLVERR` mode. A selected error read
forwards target data and USER while changing each response to `SLVERR`; a FIFO
read still consumes its words. An error write is consumed without changing
SRAM/FIFO. Reset rearms error injection. Compile the replacement instead of
Caliptra's original module; do not connect both models to `m_axi_if`. Define
`CALIPTRA_BFM_CHECKER` to connect the native Caliptra-profile checker to the
bus. It also preserves Caliptra's firmware preload path through
`i_axi_sram.i_sram.ram[addr][byte_idx]`, exercised by
`axi/tests/run_caliptra_axi_complex_bfm.sh`. This checker covers the documented
BFM profile and is not a full ARM Axi4PC replacement. Its generated recovery
sequence is enabled only with Caliptra's `+CPTRA_RAND_TEST_DMA` plusarg, which
is also required for the pinned testbench to initialize the block-size array.
The top-level firmware smoke and its diagnostic limits are recorded in
[`open-top smoke evidence`](../../evidence/caliptra-bfm-open-top-smoke-20261006/README.md).
These are reusable module-level components; they do not include the full UVMF
base library, a complete Avery-compatible agent/environment, or ARM Axi4PC. A
bounded clean-room `uvmf_lite/` slice is described below.
Caliptra already supplies its DMA testcase generator at
`src/integration/tb/dma_testcase_generator.sv`. The recovery sequence consumes
that generator's packed block-size array, skips zero entries, selects
per-block thresholds, and is wired into the DMA wrapper. Optional autonomous
FIFO push/pop controls are also present. Focused
Icarus simulations now cover the FIFO/DMA/recovery path, the AHB-Lite manager,
subordinate, checker, and monitor, and the AXI completed-transaction monitor.
The AHB-Lite manager/checker/monitor also complete and record an ECC interrupt-
enable CSR write/readback against Caliptra's pinned `ecc_top` RTL through
`ahb_lite/tests/run_caliptra_ecc_ahb_bfm.sh` using this fork's Icarus build.
The native UVM AHB sequencer/driver and passive monitor now drive the same
actual ECC unit through `ahb_lite/tests/run_caliptra_ecc_ahb_uvm_bfm.sh`; this
is unit-level DUT integration, not generated UVMF or full-top qualification.
The three-edition tool/source provenance is recorded in
[`evidence/caliptra-bfm-ecc-ahb-uvm-20261004`](../../evidence/caliptra-bfm-ecc-ahb-uvm-20261004/README.md).

The [`pv/`](pv/README.md) client master drives PCRVault read/write request
lanes and samples the actual read response. It passes a direct DUT smoke with
concurrent channels, AHB readback, bounds checking, and reset abort under
IEEE 2017/2023; details and hashes are in
[`evidence/caliptra-bfm-pv-actual-rtl-20261004`](../../evidence/caliptra-bfm-pv-actual-rtl-20261004/README.md).

The native UVM PV sequencer and driver use the same task BFM through a
command proxy. The UVM smoke writes and reads all PCR dword offsets through
the real client pins, checks bounds/reset handling, and validates completed
command records. See
[`evidence/caliptra-bfm-pv-uvm-actual-rtl-20261004`](../../evidence/caliptra-bfm-pv-uvm-actual-rtl-20261004/README.md).

The separate `uvm/` layer provides active/passive AXI and AHB-Lite UVM agents.
The AXI agent uses the Caliptra AXI manager proxy and publishes completed AXI
records. Its clean-room AAXI compatibility path adds the observed transaction
fields, four manager port names, a lower-bound sequencer/driver, RAL adapter,
and predictor exports. The AAXI-style smoke performs register reads/writes and
predicts from completed monitor items. The current command bridge serializes
sequence items and returns the response ID observed on BID/RID. Caliptra
configures the generated AAXI master with one total outstanding transaction
and one per ID, so this serialization matches the observed setting. Deeper
outstanding limits remain unsupported. The local generated-path sequences
inspect response fields immediately after `finish_item`, so the shim waits for
completion before returning each item; early item completion would need a
separate response routing contract. Exact Avery event timing and full UVMF
integration remain unverified. The AXI UVM smoke now checks matching and invalidated exclusive
accesses through the native and projected monitor paths; both RAL adapters map
`EXOKAY` to success. Its basic run is recorded in
[`evidence/caliptra-bfm-uvm-agent-20261005`](../../evidence/caliptra-bfm-uvm-agent-20261005/README.md).
Directed reset-abort runs cover an accepted read stalled before R and an
accepted write stalled before B; both abort without publishing a completed
record and recover for a post-reset burst. See
[`reset-abort evidence`](../../evidence/caliptra-bfm-uvm-agent-reset-abort-20261006/README.md).
The AHB-Lite agent uses its manager proxy and
publishes completed AHB transfers through the observed keyed streams. The
AHB UVM file list includes a raw-pin-to-record adapter for the passive monitor
boundary. The
UVM/DPI smokes pass after the AXI 256-beat payload-width update,
including a full-length 256-beat write through the DMA map. These are clean-room
adapter APIs, not
drop-ins for the full Avery API, QVIP, or a complete UVMF agent. Their combined
file list is `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f`; run
`dv/caliptra_bfm/uvm/tests/run_uvm_adapter.sh`,
`dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh`,
`dv/caliptra_bfm/uvm/tests/run_uvm_dma_agent.sh`, and
`dv/caliptra_bfm/uvm/tests/run_ahb_lite_uvm_agent.sh` with this fork's `-uvm`
toolchain selected through `IVERILOG_BIN`/`VVP_BIN` or `PATH`. The DMA agent
smoke exercises the native AXI UVM manager through the actual open SRAM/FIFO
address map, including FIXED FIFO traffic, exclusive access, and an invalidated
exclusive write.

The clean-room `uvmf_lite/` layer now includes the shared HDL/HVL enums,
transaction base, typed configuration/agent bases, driver/monitor hooks,
sequencer and test bases, and the in-order scoreboard used by ECC, HMAC, and
SHA-512. Its active/passive toy-DUT smoke exercises config handoff, factory
override, monitor publication, prediction, and matching/mismatch controls in
both SystemVerilog editions. Its transaction inherits the clean-room UVMF base
and verifies metadata cloning without comparing timestamp metadata. Generated
Caliptra ECC's packages, all four actual BFM interfaces, both bus interfaces,
environment, and sequence/test packages now compile in generated source order
under both editions. The generated `test_top` runtime probe also builds the
actual environment and verifies all three driver/monitor proxy identities.
The generated SoC-IFC runtime probe now passes its reset/power-on path and one
real AAXI write/read with zero UVM errors or fatals. Its key trace confirms the
randomized obfuscation key reaches the real RTL register. Icarus-specific
fixes run only on disposable generated sources and synchronize predictor and
monitor startup around reset; they do not modify the pinned Caliptra checkout.
This qualifies the exercised generated environment path, not every generated
sequence or full-chip DV. Details and the retained run log are in
[`SoC-IFC generated-runtime evidence`](../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md).
The generated ECC `hdl_top` uses hash-pinned disposable overlays and runs the
generated driver BFM's AHB write/read of the interrupt-enable register against
actual `ecc_top` under both editions. Its 512-clock status-poll overlay also
completes a keygen transaction and matches the predicted vector under IEEE
2017 and 2023 with zero UVM errors/fatals. The
compile and runtime evidence is in
[`generated ECC HDL-top evidence`](../../evidence/caliptra-bfm-generated-ecc-hdl-20261004/README.md).
The generated SHA-512 `SHA512_random_test` also runs against the actual
`sha512_ctrl` RTL: the clean-room scoreboard matches all 13 expected/observed
transactions after the disposable reset-event monitor overlay. Without that
overlay the stock output monitor shifts the stream by one reset-only sample.
See [generated SHA-512 runtime evidence](../../evidence/caliptra-bfm-generated-sha512-runtime-20261005/README.md).
Wide automatic bins use exact leading-bit prefixes;
the 384-bit ECC case and 512-bit output case are covered by the focused
2017/2023 regression, along with a 65-bit non-power-of-two partition, a
word-boundary case, and wide crosses. Named
`INITIATOR`/`RESPONDER` re-exports now resolve in both editions, and generated
coverage-stub warnings remain. The generated-top probe stops at elaboration, so
it is not DUT runtime qualification. Focused regressions now cover 512-bit explicit
ranges, endpoint/bin identity, overlap diagnostics, and X/Z-to-zero sampling.
The generated SoC-IFC reset/power-on runtime compiles the status/control
packages through disposable Icarus overlays and passes its bounded AAXI/status
scoreboard probe against the real `soc_ifc_top`. The status full-snapshot probe
checks all 17 fields and delivers all three records through the generated
coverage subscriber; Icarus covergroup stubs mean functional bin collection is
still open. Generated sequence coverage remains partial. The generated
`maps[j].get_full_name` shape is covered by the no-parentheses regression,
including an inherited method on a selected queue element. No pinned Caliptra
source was changed. Slang's separate virtual-interface type diagnostic remains
unqualified. These probes are documented in the research note. The layer is
not a full UVMF replacement. See
[`uvmf_lite/README.md`](uvmf_lite/README.md).

`uvm/tests/run_caliptra_top_firmware_bfm.sh --case smoke_test_dma --output <new-dir>`
attaches the open AXI complex replacement to the full Caliptra testbench top
and runs the real DMA firmware. The runner also accepts Caliptra's
`smoke_test_dma_aes_gcm_short_1_dword` case for a smaller full-top DMA firmware
scenario. Add `--fast-trng` for a diagnostic copied-top override that changes
the physical RNG model cadence from 500 to 50 cycles; the default retains
the pinned cadence. Fast-TRNG results do not qualify entropy timing. For a
startup diagnostic, `--fast-boot-data-preload` supports the short AES DMA and
`rand_test_dma` cases; it validates CRT0 layout, preloads the firmware's `.data`
bytes into DCCM, and skips the copy loop. The BSS clear and firmware remain
active, but this modified-image run is not stock firmware qualification. Its
result records stock and simulated image hashes plus the preload range. The
`--skip-pq-vector-generation` option skips unrelated MLDSA/MLKEM testbench
vector generation for the short AES case while retaining all 12 firmware
AES/DMA cases. `--quiet-firmware` compiles supported DMA cases with
`CPT_VERBOSITY=ERROR` to suppress low-priority firmware prints; for the short
AES case it retains all 12 cases.
`--limit-aes-cases N` builds a disposable firmware copy for the first N of the
12 AES/DMA cases, with the same data preload, PQ-vector skip, and quiet mode as
the one-case diagnostic. This provides an incremental path from one case to
the complete suite. `--first-aes-case-diagnostic` remains the one-case alias.
These modes are diagnostic, can be combined with `--fast-trng` and `--trace-axi`,
and do not qualify stock firmware. `CALIPTRA_BFM_PROFILE` can use Caliptra's
pinned `src/integration/config/caliptra_top_tb.vf`; the generated Icarus profile
omits its unavailable ARM `Axi4PC.sv` placeholder. No stub is compiled in its
place, and this run does not claim Axi4PC-equivalent checking. The runner also
requires `CALIPTRA_RTL`, a profile containing the original AXI-complex source
exactly once, `CALIPTRA_GCC_PREFIX` (toolchain name or path, with or without a
trailing hyphen), and `CALIPTRA_JTAGDPI_VPI`. It builds and checks the
open native crypto-vector helpers in `native_vectors/`; this currently requires
macOS ARM64, Homebrew OpenSSL 3 and mbedTLS 3, Clang, Make, and Python 3.12.
Hash-checked disposable Icarus overlays also allocate Caliptra's missing AXI
read response-user array and work around the pinned SRAM, reset, JTAG-port, and
debug-print compatibility issues. The AES package overlay keeps `aes_mul2`
equivalent while replacing its bitwise local-result writes with one vector
assignment to avoid the reproduced Icarus `always_comb` time-zero retrigger;
the original RTL checkout is left untouched.
Compile, firmware, vector, and simulation logs plus hashes are retained in the
requested output directory. The runner uses the 60%-free-memory guard and also
accepts `rand_test_dma`. Count the run as passed only when the firmware pass
marker appears and no simulator, SVA, or JTAG errors are reported.

## Connecting to the Caliptra DMA port

In the pinned Caliptra testbench, `m_axi_if` is the DMA AXI interface. The DUT
is its manager (`w_mgr`/`r_mgr`); `axi4_caliptra_dma_subordinate` is the BFM
target. The `axi4_caliptra_dma_if_subordinate` wrapper connects that target to
the actual `axi_if` type, and `axi4_caliptra_dma_if_monitor` connects the pins
to the UVM record interface. Compile Caliptra's `axi_pkg.sv` and `axi_if.sv`
first, then include `caliptra_bfm.f` and
`caliptra_bfm_caliptra_if.f` from the repository root. The monitor wrapper
expects widths matching the connected `axi_if`. The pinned Caliptra checkout
uses 48-bit DMA addresses, 32-bit data/USER, and a 5-bit DMA ID; standalone
smokes may select a different ID width.

`axi4_caliptra_master_if_manager` adapts the task-based manager to
`axi_if.w_mgr`/`axi_if.r_mgr` and exposes reset, burst-write, and burst-read
tasks. Its width parameters must match the connected interface. The manager's
default 19-bit address width matches Caliptra's inbound SoC interface; the DMA
integration smoke overrides it to 48 bits.

The underlying target connects to the interface signals with these directions:

| AXI channel | BFM subordinate request inputs | BFM subordinate response outputs |
| --- | --- | --- |
| AW | `AWID/ADDR/LEN/SIZE/BURST/LOCK/USER/VALID` ← `m_axi_if.aw*` | `AWREADY` → `m_axi_if.awready` |
| W | `WDATA/STRB/USER/LAST/VALID` ← `m_axi_if.w*` | `WREADY` → `m_axi_if.wready` |
| B | `BREADY` ← `m_axi_if.bready` | `BID/RESP/USER/VALID` → `m_axi_if.b*` |
| AR | `ARID/ADDR/LEN/SIZE/BURST/LOCK/USER/VALID` ← `m_axi_if.ar*` | `ARREADY` → `m_axi_if.arready` |
| R | `RREADY` ← `m_axi_if.rready` | `RID/DATA/RESP/USER/LAST/VALID` → `m_axi_if.r*` |

Use Caliptra's interface widths (DMA address, data, ID, and USER widths) when
overriding the BFM defaults. Wire the subordinate's FIFO/recovery controls to
the testbench scenario controls; its `recovery_data_avail` output supplies the
corresponding Caliptra input when that behavior is under test. The source list
[`caliptra_bfm_caliptra_if.f`](caliptra_bfm_caliptra_if.f) includes a replacement
module with the exact `caliptra_top_tb_axi_complex` name and port contract.
Compile it instead of Caliptra's original source; the replacement was
smoke-tested against Caliptra's actual `axi_if` and control-struct layout.
That smoke is module-level, not a full Caliptra DUT run.

For UVM observation, connect the same bus pins to
the provided monitor wrapper and provide its record interface to the passive
UVM agent. The AXI UVM active manager is useful for standalone component tests;
the real Caliptra DMA path requires the passive agent plus a subordinate
target. `axi/tests/run_caliptra_axi_if.sh` compiles the wrappers against the
pinned Caliptra `axi_if` and runs a full 256-beat SRAM write/read through the
typed manager, subordinate, and transaction monitor. This checks the
interface adapters, not the Caliptra DUT top or its existing scenario control.
`uvm/tests/run_uvm_axi_if.sh` also drives the pinned interface through the
active native UVM agent. The open DMA target responds to SRAM, FIFO, and
256-beat traffic plus an injected `SLVERR` read, and the UVM monitor checks
completed analysis records. It is component-level interface evidence, not a
Caliptra DMA-engine run.
`uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh` connects Caliptra's actual read and
write AXI manager modules to the recreated subordinate and UVM monitor. It
checks 5-bit-ID address/control, payload, USER, response, and LAST fields
through the pinned interface, with Caliptra's assertion macros enabled. This
manager-level check is complemented by `uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh`,
which programs the actual pinned `axi_dma_top` through its CSR request interface
and drives a seeded 65-word transaction from Caliptra's own DMA randomizer
through the same open target and UVM monitor. The scoreboard checks its
boundary-limited bursts and randomized payload. A separate case injects AXI
`SLVERR` and checks Caliptra's DMA error state plus the resulting partial
destination write. A third case transfers 65 auto-generated FIFO words to
SRAM through the real fixed-burst recovery path. The test uses one seeded case
from Caliptra's
`dma_transfer_randomizer`. Separately, the actual generator's multi-case DCCM
records feed the BFM recovery sequencer. The actual-DUT bench now ECC-checks
and replays all 29 DCCM records through `axi_dma_top` under a hash-guarded
profile covering all five named DMA routes, eight short sizes, and a 65,536-word
fixed-read FIFO-to-SRAM stream. It also replays a 65-word fixed-write SRAM-to-
FIFO case with randomized delays. Recovery record 26 sweeps 4-, 8-, 16-, 32-,
and 64-byte AXI2AXI blocks; records 27 and 28 sweep all legal one-hot block
sizes from 4 through 2048 bytes on AXI2MBOX and AXI2AHB. Each sweep overrides
the selected generated DCCM block-size entry. Payloads and
route-valid offsets remain per-record randomized, as does Caliptra's delay
flag; the maximum stream drains the FIFO and checks all destination words. The
actual DMA DUT reset-abort profile now
holds B after AW and the final W beat, resets the DUT and target, then verifies
a complete post-reset 65-word transfer. See
[`DMA reset-abort evidence`](../../evidence/caliptra-bfm-dma-reset-abort-20261006/README.md).
Other generated FIFO modes, firmware-triggered reset injection, and full
firmware remain open. The generated AXI2AXI sweep covers one AXI FIXED request
per recovery block through the 64-byte maximum at Caliptra's 32-bit DMA data
width. An exploratory 128-byte AXI2AXI override remained in Caliptra's
`DMA_WAIT_DATA` state with 16 internal FIFO words buffered and
`recovery_data_avail` asserted; it is outside the pinned AXI2AXI constraint.
Generated DCCM records 27 and 28 pass 65 FIFO words through AXI2MBOX and
AXI2AHB for every legal one-hot recovery block size from 4 through 2048 bytes.
The hash-guarded Icarus generator overlay sets each route's legal block
metadata, then the runner overrides the selected generated block-size entry.
See the
[`AXI2MBOX/AXI2AHB recovery evidence`](../../evidence/caliptra-bfm-dma-routed-recovery-sweep-20261006/README.md).
Run only the generated recovery-size sweep with
`uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh --recovery-block-sweep-only`.
Run only the route sweep with
`uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh --recovery-route-sweep-only`.
Caliptra's `inject_rst` metadata is consumed by `rand_test_dma.c`, which sends
stdout-control request `0xEE`; `caliptra_top_tb_services.sv` turns that request
into a delayed warm reset. The focused DMA replay does not run that firmware or
testbench service, so generated metadata alone does not qualify reset injection.
That focused
block integration includes the register
block, DMA control FSM, and real AXI managers. It is not a full Caliptra top,
firmware, or generated UVMF run. Tool and source hashes are recorded in
[`evidence/caliptra-bfm-caliptra-dma-top-20261004`](../../evidence/caliptra-bfm-caliptra-dma-top-20261004/README.md)
and [`evidence/caliptra-bfm-dma-recovery-top-20261006`](../../evidence/caliptra-bfm-dma-recovery-top-20261006/README.md).
The DCCM-to-DUT replay is recorded in
[`evidence/caliptra-bfm-dma-all-routes-20261006`](../../evidence/caliptra-bfm-dma-all-routes-20261006/README.md),
with follow-up evidence for the [FIFO destination](../../evidence/caliptra-bfm-dma-generated-fifo-destination-20261006/README.md)
and [generated recovery block](../../evidence/caliptra-bfm-dma-generated-recovery-block-20261006/README.md).
The [generated recovery block-size sweep](../../evidence/caliptra-bfm-dma-generated-recovery-sweep-20261006/README.md)
covers the supported 4–64-byte range for AXI2AXI recovery blocks.
`axi/tests/run_caliptra_axi_complex_bfm.sh` compiles against Caliptra's actual
`caliptra_top_tb_pkg.sv`, `soc_ifc_pkg`, `axi_pkg`, and `axi_if`, then
smoke-tests the replacement with Caliptra's `axi_complex_ctrl_t` and pinned
48/32/5/32 DMA widths. It covers one-shot range errors, SRAM/FIFO
write/read, injected R/B responses held under backpressure, FIFO
auto-push/pop/clear, recovery availability, random stalls, and the opt-in native
profile checker. The read-error case uses a 5-bit ID with its upper bit set.
The run selects Caliptra's `VERILATOR` helper branch because the smoke does not
use its randomization-only bit-flip helper; this keeps the actual control type
and BFM interface under test. The result is a pin-level component test, not
full-DUT qualification.
The runner defines `XCELIUM` to skip optional dynamic-array helper tasks in
Caliptra's `axi_if.sv`; the signal declarations and modports remain present.
Those optional interface tasks are not covered by this smoke.
The AXI UVM record interface uses variable members so Icarus can propagate the
procedural transaction-monitor outputs through the typed wrapper.

Run the focused AXI and AHB simulations from the repository root with
`dv/caliptra_bfm/axi/tests/run_*.sh` and
`dv/caliptra_bfm/ahb_lite/tests/run_ahb_lite.sh`. Run the unit-level Caliptra
ECC RTL checks with `dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_bfm.sh`
and `dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_uvm_bfm.sh`.
The direct-pin tests use system Icarus 13.0. The tests that compile Caliptra's
typed `axi_if` or ECC RTL
(`run_caliptra_axi_if.sh`, `run_caliptra_axi_complex_bfm.sh`,
`run_caliptra_ecc_ahb_bfm.sh`, and `run_caliptra_ecc_ahb_uvm_bfm.sh`) require
this
repository's Icarus fork with interface-port support and Caliptra RTL language
support; set `IVERILOG_BIN` and `VVP_BIN` to that build as shown for the UVM
smokes above. The ECC and DMA runs exercise Caliptra unit/block RTL. The
generated PCRVault UVMF test now also runs against actual PV RTL with the
clean-room base/AHB compatibility layer; it does not qualify the full
Caliptra top or the licensed full UVMF/QVIP libraries. See
[`../../evidence/caliptra-bfm-pv-generated-uvmf-20261004/README.md`](../../evidence/caliptra-bfm-pv-generated-uvmf-20261004/README.md).
The actual generated KeyVault `hdl_top`, reset/read/write interfaces, KeyVault
RTL, and clean-room AHB shell elaborate in 2017 and 2023. The generated
`kv_rand_wr_rd_test` also passes in IEEE 2017 with zero UVM errors/fatals using
the hash-guarded Icarus overlay. The original failures came from the generated
read monitor notifying subscribers before the write monitor's one-clock-late
analysis callback. The overlay yields one delta after read capture so same-edge
write prediction settles first; it does not advance simulation time or alter
the sampled response. The sequence's unconditional pass marker is not used as
the runtime gate. This qualifies the generated KeyVault block test with the
local compatibility layer, not licensed full UVMF/QVIP or the full Caliptra
top.
See
[`../../evidence/caliptra-bfm-keyvault-generated-hdl-20261004/README.md`](../../evidence/caliptra-bfm-keyvault-generated-hdl-20261004/README.md).

The top-level research and implementation plan is in
[`../../docs/conformance/caliptra_bfm_uvmf_recreation_plan_2026-10-03.md`](../../docs/conformance/caliptra_bfm_uvmf_recreation_plan_2026-10-03.md),
with source and reuse findings in
[`../../docs/conformance/caliptra_bfm_research_2026-10-03.md`](../../docs/conformance/caliptra_bfm_research_2026-10-03.md).
