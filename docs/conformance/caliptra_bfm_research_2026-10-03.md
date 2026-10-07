# Caliptra BFM research and implementation progress — 2026-10-03

## What the pinned environment uses

The local Caliptra checkout is present at
`/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl`, pinned to v2.1.2
(`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`) with Adams Bridge v2.0.3
(`b77e3d899e828d626cfc2a0d26a6b5704cc121e0`). It was inspected read-only.

The official UVMF SoC interface environment configures Avery's AXI master with
one total outstanding transaction and one per-ID outstanding transaction. Its
setup enables AW/W/B/AR/R USER support. The pinned Caliptra `axi_if` exposes
AWUSER, WUSER, BUSER, ARUSER, RUSER, and LOCK. Caliptra's SoC environment also
instantiates a QVIP AHB-Lite subordinate agent and uses AXI analysis ports in
its predictor and scoreboard. These are separate replacement targets; a small
AXI manager alone cannot replace the environment.

Caliptra v2.1.2's internal AHB interconnect uses a 32-bit address and 64-bit
data path. Its reduced `CALIPTRA_AHB_LITE_BUS_INF` carries address, write data,
read data, select, direction, size, transfer type, ready, and the one-bit
AHB-Lite response; the integration interface omits HBURST, HPROT, lock, and
USER. The isolated generated SoC-IFC top sets `AHB_LITE_SLAVE_0_ACTIVE(1)`;
its QVIP xactor drives HADDR/HWDATA/HSEL/HWRITE/HTRANS/HSIZE into the DUT and
receives HREADYOUT/HRDATA/HRESP. Despite the generated
`qvip_ahb_lite_slave` name, that configuration actively initiates transfers.
The integrated Caliptra top instead sets `AHB_LITE_SLAVE_0_ACTIVE(0)`, making
the same QVIP component a passive observer there. The native AHB slice is
documented in
[`dv/caliptra_bfm/ahb_lite/`](../../dv/caliptra_bfm/ahb_lite/README.md). It
contains a serialized directed manager with bounded 1..256-beat INCR support,
an address/data-phase monitor, subset profile checker, and bounded
single-window memory subordinate. Its focused Icarus test passes read/write
lane, wait-state, injected-error, range-error, checker, monitor, and two
four-beat burst cases. The active/passive UVM agent publishes native per-beat
records and the observed MVC `burst_transfer`/scoreboard/coverage streams; its
Icarus smoke passes four-beat queue write/read, first-beat ERROR abort, and a
partial burst with one successful beat followed by ERROR. It checks that
unissued read/write beats stay unchanged. The generated-name active and
passive QVIP facade smoke also passes the four-beat streams. These are
clean-room lower-bound APIs and do not reproduce proprietary QVIP lifecycle,
internal covergroups, configuration behavior, or sequences.

## Caliptra DMA AXI target semantics

The pinned `src/integration/tb/caliptra_top_tb_axi_complex.sv` decodes two
separate DMA regions by address prefix: SRAM at `0x0001_2344_0000` with a
256 KiB window, and FIFO using the high 30 bits of
`0x0000_fa57_0000`. The FIFO prefix therefore selects the 256 KiB block from
`0x0000_fa54_0000` through `0x0000_fa57_ffff`; the nominal FIFO base is at
offset `0x30000` within that block. The testbench tracks read and write
activity separately for each endpoint and muxes responses back to the manager.
The AXI FIFO path asserts that accepted AR and AW requests use FIXED bursts.
Although the package declares `AXI_FIFO_ADDR_WIDTH` and `AXI_FIFO_DEPTH` from
the SRAM size, the FIFO instance receives `AXI_FIFO_SIZE_BYTES` (64 KiB) as
its capacity. Address decode aperture and queue capacity are separate
properties in this testbench.

The protocol package defines an 8-bit AXI `LEN` range of up to 256 beats and a
16-beat FIXED-burst limit in `src/axi/rtl/axi_pkg.sv`. Caliptra's present DMA
controller imposes a smaller request limit: with its 512-byte FIFO, it uses
half the FIFO capacity as the maximum block size, or 256 bytes / 64 beats on
the 32-bit DMA bus. The open BFM retains 256-beat protocol capacity; actual
traffic from this pinned DMA controller is bounded to 64 beats.

The pinned `caliptra_top_tb_axi_fifo.sv` turns each accepted AXI W beat into a
word pushed to a synchronous FIFO and each AXI read data request into one word
consumed by the subordinate component. Its other behaviors are scenario
controls: randomized automatic push/pop, synchronous clear, and
recovery-data-availability modes selected as not-empty, threshold, or pulse.
Pulse mode tracks configurable DMA block sizes and read/write counts. These
details explain why an SRAM array is not a valid stand-in for the FIFO target,
and why reproducing the entire testbench scenario model is a separate boundary
from the bus endpoint.

The pinned recovery model selects exactly one mode using plusargs or random
one-hot selection: `CLP_DMA_TB_MODE_NOT_EMPTY`,
`CLP_DMA_TB_MODE_THRESH`, or `CLP_DMA_TB_MODE_PULSE`. Without the random-DMA
plusarg, its block size is 256 bytes; with `CPTRA_RAND_TEST_DMA`, it consumes
up to 100 configured 12-bit block sizes after `dma_gen_done`, chooses a random
threshold in FIFO words, and advances to the next block after recovery
emulation drops while reset is released. Pulse mode asserts after enough
accepted FIFO writes for one block and deasserts after the configured read
count, retaining write/read accounting across an emulation reset but clearing
it when emulation is disabled or reset is asserted. A rising recovery-enable
is required to find the FIFO empty. `auto_push` and `auto_pop` share the same
FIFO data port with AXI traffic; when the random writer is valid, its word is
selected over AXI WDATA in the pinned model. The open FIFO now has optional
autonomous push/pop controls, with matching write priority and shared queue
accounting. `axi4_caliptra_recovery_sequence.sv` consumes the pinned block-size
array, advances between recovery tests, skips zero-sized entries, and selects a
random threshold in words. The source generator already exists in the pinned
Caliptra tree as Apache-2.0 `src/integration/tb/dma_testcase_generator.sv`,
backed by `dma_transfer_randomizer.sv`; no generator source needs to be
recreated. It publishes 100 packed 12-bit entries, where zero means that a
testcase does not exercise recovery and nonzero block sizes are one-hot values
from 4 through 2048 bytes. The BFM's flattened 1200-bit input uses the same
packed ordering (`entry i` occupies bits `i*12 +: 12`). Its unit test now uses
that full interface width and checks leading, interior, and trailing zeros.
The new `axi4_caliptra_recovery_avail.sv` models the three availability signal
policies from explicit FIFO-level/event inputs. The combined DMA subordinate
instantiates it and exposes `recovery_data_avail`; callers provide the
emulation enable and may select sequenced or manual block/threshold inputs.
`tests/run_recovery_sequence.sh` and `tests/run_dma_subordinate.sh` pass under
Icarus 13.0. They cover generated block sizing/thresholds, reset retry,
end-of-list behavior, DMA SRAM/FIFO routing, optional controls, autonomous
FIFO push/pop, and sequencer integration. They do not run the Caliptra DUT or
the official UVM testbench.

The new [`axi4_caliptra_fifo_subordinate.sv`](../../dv/caliptra_bfm/axi/axi4_caliptra_fifo_subordinate.sv)
implements the narrower stream endpoint: a 64 KiB word queue selected by the
pinned 256 KiB address prefix, with one outstanding read and write,
backpressure, clear, and injected DECERR/SLVERR behavior. The
[`axi4_caliptra_dma_subordinate.sv`](../../dv/caliptra_bfm/axi/axi4_caliptra_dma_subordinate.sv)
composes it with the SRAM target and Caliptra address routing. The FIFO and
combined map pass standalone Icarus tests for queue traffic, address routing,
optional controls, autonomous push/pop, and recovery sequence integration.
The autonomous controls use a portable weighted draw for the pinned 0..255-cycle
delay distribution and model asynchronous reset plus a first-cycle FIFO
ready/valid hold. Random sequences are not cycle-for-cycle identical.

The current [public Caliptra README](https://github.com/chipsalliance/caliptra-rtl/blob/main/README.md)
lists Avery AXI VIP 2025.1, Mentor QVIP 2021.2.1 AHB models, UVM 1.1d, and
UVMF 2022.3 as verification inputs. It also requires ARM Axi4PC
`BP063-BU-01000-r0p1-00rel0` and says its copyrighted source must be acquired
from ARM rather than the repository. The linked UVMF mirror claims open source
in its README, but a recursive current-main tree scan found no framework
license; the only `LICENSE`/`COPYING` files are for bundled Python
dependencies. Do not copy or vendor it until the framework's license is
established. Caliptra's Axi4PC placeholder is not an implementation of ARM's
checker.

## Reuse decision

The existing [QD-EDA/qd-bfm](https://github.com/QD-EDA/qd-bfm) source is
Apache-2.0 and explicitly targets Caliptra's inbound SoC AXI subordinate. Its
single-beat directed manager is copied into
[`dv/caliptra_bfm/axi/`](../../dv/caliptra_bfm/axi/README.md) with its license
and provenance. This is the smallest useful executable seed already available
locally; it avoids recreating a second copy of the same directed helper.

Its limits are material: no AXI USER/LOCK, no multi-beat bursts or outstanding
transaction queues, no monitor/scoreboard/coverage, no UVMF API, and no safe
recovery after timeout. The QD seed targets Caliptra's inbound SoC bus
(AW=19, DW=32, IW=8), so its default AW=32 must be overridden for that use.
That bus is distinct from the DMA `m_axi_if` targeted by the new BFM
(AW=48, DW=32, IW=5, UW=32, including AW/AR LOCK). This imported helper is for
directed zero-USER transactions and is not an Avery replacement or a Caliptra
qualification result.

That USER limitation excludes official mailbox coverage: the SoC random test
selects `RAND_AXI_USER` and `RAND_AXI_USER_*_UNLOCK` sequences, and the AXI
USER sequence varies user-valid probabilities. Register callbacks compare the
transaction's AXI_USER against the configured mailbox owner and inspect LOCK.
Those paths need a richer manager than this helper.

## Public candidates checked

| Candidate | Evidence | Assessment |
| --- | --- | --- |
| [CHIPS Alliance `axi-vip`](https://github.com/chipsalliance/axi-vip) | The [CHIPS Alliance Caliptra presentation](https://www.chipsalliance.org/events/presentations/2024-osseu/OSSVienna2024-New-open-source-IP-tools-and-verification-flows-for-Caliptra-2_0.pdf) identifies the source package as Western Digital's `axi-vip`. At commit [`16d0f444299014b2079c941925ea8b43d85a13f7`](https://github.com/chipsalliance/axi-vip/tree/16d0f444299014b2079c941925ea8b43d85a13f7), its root `LICENSE` and file headers state ISC. Its UVM AXI agent, driver, monitor, sequencer, transaction, memory, and test sources are present. | **Not a direct Caliptra drop-in based on the recorded profile.** The interface/profile differences and reproduced local-Icarus compile errors are documented below. These results do not establish compatibility with VCS or Questa. |
| [OSVVM AXI4](https://github.com/OSVVM/AXI4) | Open AXI4, AXI4-Lite, and AXI-Stream verification components, including manager and subordinate models. | Broader protocol source candidate, but VHDL/OSVVM APIs do not replace Caliptra's SystemVerilog/UVMF environment. |
| [`funningboy/uvm_axi`](https://github.com/funningboy/uvm_axi) | Public UVM BFM; README lists valid/ready and ID checks, but says it requires `irun > 10` and Python 2.7 and does not support AXI USER. | Its documented tool requirements and missing USER make it a poor fit for this Caliptra target. |
| [User-linked UVMF mirror](https://github.com/muneeb-mbytes/UVMF) | README calls it open source, but recursive current-main tree scan found no framework license; visible licenses cover bundled Python dependencies. | No vendoring until the framework's terms are confirmed. |

The user's [PR #397](https://github.com/dsellerbrock/iverilog-uvm/pull/397)
is the planning-only change that introduced the recreation plan; its PR body
explicitly limited that change to documentation. This active user request
subsequently authorizes implementation in the separately named `BFM WORK`
clone. The [local QD-EDA repository](https://github.com/QD-EDA/qd-bfm) is
clean at `d761ee8cc6594656e95582a28f471c473ebd1afc`; its Apache-2.0
single-beat manager has already been copied with its license and provenance.

The linked [UVMF mirror](https://github.com/muneeb-mbytes/UVMF) currently lists
`UVM_Framework/`, `README.md`, `make_filelist.py`, and `yaml2uvmf.py` at its
root. Its recursive tree exposes license files only for bundled Python
dependencies, not the framework itself. Treat its code as non-vendorable until
license terms are established. The adjacent [Mbits AXI4 AVIP
repository](https://github.com/mbits-mirafra/axi4_avip) does show an MIT license
and broader manager/slave features, but its published flow uses Questa; it is
another research option, not evidence of Icarus support.

### Generated ECC runtime proxy probe — 2026-10-04

After the configured-order compile probe passed, a separate runtime probe
compiled the same actual ECC generated packages and interfaces, instantiated
the generated `test_top`, and called `run_test` with real driver/monitor
virtual-interface registration. Under both `-g2017` and `-g2023`, the actual
`ECC_environment` and active/passive agents are created; the active input
driver and its BFM handle are non-null, and a cast to the generated
`ECC_in_driver #(32,32)` succeeds. The generated `set_bfm_proxy_handle()`
leaves `configuration.driver_bfm.proxy` null. Calling that setter again and
assigning the typed driver directly to the proxy also leave it null, followed
by `UVM_FATAL: Generated input BFM proxy was not installed`.

The same run's VVP image showed multiple internal `ECC_in_driver`
specializations with different generated parent/type-graph identities despite
the same visible address/data widths. This is a lead for compiler triage, not a
confirmed root cause. No core compiler source or pinned Caliptra source was
changed for this observation. The repeatable runtime probe and exact commands
are in [`evidence/caliptra-bfm-generated-ecc-runtime-20261004`](../../evidence/caliptra-bfm-generated-ecc-runtime-20261004/README.md).
Generated UVMF runtime and DUT qualification remain open.

### PCRVault generated UVMF boundary probe — 2026-10-04

The hash-guarded overlay successfully elaborates the pinned generated PCRVault
`hdl_top` with the clean-room AHB HDL shell under IEEE 2017 and 2023; that is
static HDL evidence only. The first full `-uvm` compile identified the QVIP
`reg2ahb_adapter` and `ahb_reg_predictor` contracts used by generated
`pv_environment.svh`. Clean-room wrappers now adapt the existing scalar AHB
RAL converter and standard `uvm_reg_predictor` to those observed types; the
UVMF-lite environment configuration also provides the two generated
register-adaptation flags. The generated environment constructs the adapter,
sets `en_n_bits`, attaches it to the AHB register map, and connects the
`burst_transfer` stream to the predictor.

The completed run compiles the actual generated PV agent packages, register
model, environment, sequences, tests, `hvl_top`, and actual PV RTL, then runs
`pv_rand_wr_rd_test`. The generated PV read driver originally omitted response
data from its sequence item, and its monitor sampled on a later rising edge;
a following reset could clear PCR storage before that monitor published the
read record. The hash-guarded overlay copies the read response fields and
samples each changed request on the intervening falling edge. Two further
exact-source overlays work around Icarus's unsupported dynamic-array slices
and field access through the generated predictor type parameter. The run ends
normally at 56.435 us with the generated pass marker, UVM_ERROR=0, and
UVM_FATAL=0; 768 warnings are retained and reported. Temporary empty package
stubs satisfy imports of `rw_txn_pkg`, `QUESTA_MVC`, and the unused
`qvip_memory_message_handler` test-base field; no source from those libraries
is copied. See the reproducible
[`evidence/caliptra-bfm-pv-generated-uvmf-20261004`](../../evidence/caliptra-bfm-pv-generated-uvmf-20261004/README.md).

The separate native PCRVault UVM agent also runs against the same pinned PV
RTL, covering all 12 dword offsets in one entry, offset-12 rejection, reset
abort, and completion records. These are PCRVault block-level results, not a
full Caliptra top-level run or a licensed UVMF/QVIP qualification. The pinned
Caliptra checkout remains unchanged at
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

### WD `axi-vip` interface review and reproduced Icarus probe

The repo checked below is the WD `axi-vip` package you asked about: Antmicro's
2024 Caliptra presentation identifies the Western Digital package as the
original AXI verification source, then describes adapting Verilator so the
package could run in an open-source flow. The source now lives at
`chipsalliance/axi-vip` under an ISC license. See the
[Caliptra/Verilator presentation](https://www.chipsalliance.org/events/presentations/2024-osseu/OSSVienna2024-New-open-source-IP-tools-and-verification-flows-for-Caliptra-2_0.pdf).

The read-only clone at `/private/tmp/wd-axi-vip-research-20261003` is clean
at `16d0f444299014b2079c941925ea8b43d85a13f7`.
Its [interface](https://github.com/chipsalliance/axi-vip/blob/16d0f444299014b2079c941925ea8b43d85a13f7/common/sim/vip_lib/axi_uvc/axi_if.sv)
has AxUSER but no LOCK pins. `BYTE_WIDTH` counts bytes (`wdata` is
`[BYTE_WIDTH-1:0][7:0]`); Caliptra's internal AXI data width is 32 bits / 4
bytes and AxUSER is 32 bits. The VIP defaults (`BYTE_WIDTH=32`, `USER_WIDTH=4`)
therefore do not describe that profile. Its
[transaction](https://github.com/chipsalliance/axi-vip/blob/16d0f444299014b2079c941925ea8b43d85a13f7/common/sim/vip_lib/axi_uvc/axi_trans.svh)
also declares `id` and `addr` as `int unsigned`, not parameter-width vectors.
For the DMA port, the pinned Caliptra sources set AW=48, DW=32, IW=5, and
UW=32 (`config_defines.svh`, `soc_ifc_pkg.sv`, and `caliptra_top_tb.sv`).

The standard repository command was rerun using the fork built from this
branch (`246c58e4`):

```sh
iverilog -uvm -g2012 -s axi_tb_top -o /private/tmp/wd_axi_vip_recheck.vvp -f axi.f
```

It exits 2 at `modules/vip/axi/tests/axi_base_test.sv:53`, on the static call
`uvm_pkg::uvm_report_server::set_server(report_server)`.

A second compile-only probe excluded that test package and used a temporary
`test_initiator` module solely to let the top elaborate. With Caliptra DMA
widths (`-DID_WIDTH=5 -DADDR_WIDTH=48 -DBYTE_WIDTH=4 -DUSER_WIDTH=32`), it
still reports `axi_trans.svh:40-41` because `get_width` is impure in a
constraint, and `axi_driver.svh:258-259,307` because run-time-selected
clocking-output drives are unsupported. This is a compile failure on this
Icarus fork, not evidence that the VIP is invalid on supported simulators.
Source SHA-256 values at this revision:

- `axi_if.sv`: `57d4706fedaa4a8b5adb01bae67ee9af56f2eab8bc288bd405d114f0318bea57`
- `axi_trans.svh`: `a0baba1fe72b6f80626ebdc060fbb5eadbc7356e89b02266af3d4def31db090f`
- `axi_driver.svh`: `36967834c20e9f0e0d20a2dad3c93849495a7d693ca1e5cc3565e9c8c4f79f54`
- `axi_base_test.sv`: `1b5a7207d94455e1b8ad364eb010ee579c866bdfa018f47a854305577b2bae1d`

No WD source was copied or modified in `BFM WORK`.

**Icarus compatibility follow-up (2026-10-05).** A disposable copy was
rechecked against the current fork. Replacing the impure constraint helper
with its equivalent `1 << size` expression, assembling variable byte lanes
locally before one whole clocking-output assignment, and adapting the bundled
testbench's legacy objection/report-server calls lets the stock filelist
compile. The bundled `axi_wrap_test` still does not qualify the VIP: with the
default-width top it reports `WRAP_SB: There were NO transactions sent to
scoreboard` and ends with one UVM error, even though the simulator process
returns zero. When the top is set to Caliptra's 19-bit address, 32-bit data,
8-bit ID, and 32-bit USER widths, the test's typed virtual-interface
config-DB lookup fails at build time. The clocking-write adaptation removes
the earlier VVP procedural-write errors, but does not repair these testbench
integration failures.

Source inspection also confirms the VIP's transaction address is only 32
bits, its interface has no LOCK pins, and its driver does not drive WUSER or
ARUSER. The probe therefore establishes that selected Icarus syntax limits can
be worked around; it does not establish usable Caliptra AXI behavior. Keep the
WD source as a reference, not as a dependency or replacement for the
Caliptra-profile BFM. No WD source or probe overlay was added to this clone.

### Generated SoC-IFC register coverage compile boundary — 2026-10-04

The first compile attempt for the actual generated SoC-IFC host packages reaches
`src/soc_ifc/rtl/soc_ifc_reg_covergroups.svh` and stops on the three
`wildcard bins <name>[16]` declarations for ROM, ICCM0, and ICCM1. Each mask
has sixteen trailing don't-care bits, matching a contiguous 64-KiB address
range split into sixteen value bins. The attempt also exposed a missing
`caliptra_axi_user.svh` search path (`src/libs/aaxi_uvm`) and an omitted
`config_defines.svh`; neither issue was part of the reported syntax failure.

The `parse.y` and `elaborate.cc` changes in this checkout add a deliberately
narrow path for unsigned integral coverpoints up to 64 bits and literal masks
whose wildcard bits are all in the low-order suffix. The parser rebuild
completed with Homebrew Bison 3.8.2 after system Bison 2.3 failed on an existing
typed-destructor declaration in the grammar. The exact 32-bit ROM/ICCM bin
boundary regression is now registered and passes in IEEE 2017 and 2023 on the
rebuilt compiler.

The actual generated SoC-IFC host-package compile was then attempted with the
open BFM compatibility packages and hash-guarded disposable source overlays.
That exposed one more missing AHB API type, `ahb_rnw_e`; the clean-room AHB
compatibility package now declares it with `AHB_READ`/`AHB_WRITE` values, and
the focused generated-name QVIP environment smoke still passes. The original
whole-filelist runs were stopped after three and two minutes, and a
selected-top compile of the generated `soc_ifc_ctrl_pkg` was stopped after 60
seconds. Bisection identified the slow construct in the pinned
`soc_ifc_ctrl_transaction_coverage.svh`: eight `generic_input_val` bins filter
`[0:$]` with `with` predicates. The compiler's `uint64_t` candidate count
wrapped for the full 64-bit range, bypassed the 4,096-value guard, and entered
an effectively unbounded enumeration loop.

The candidate-count guard in `elaborate.cc` now rejects unsupported
non-`inside` filters above 4,096 values before enumeration. A permanent
`sv_covergroup_with_full_range_limit` regression passes in both IEEE 2017 and
2023 focused legacy and JSON runners. A separate positive boundary case
confirms that exactly 4,096 candidates still work. The copied generated control
package now exits with eight explicit coverage errors in 2.59 seconds; its
full-domain `with` coverage remains unsupported. A retained bounded replay
runner and filelist template reconstruct the control-package reducer from the
pinned checkout and reproduce the eight diagnostics in 2.07 seconds. A
one-off invocation of the larger host-package filelist exited with compiler
diagnostics in 1.97 seconds. Its output included unresolved generated types
and macro-visibility errors followed by parse cascades. The copied package
tree, assembled filelist, and diagnostic log were not retained, so those
errors are not classified as independent Caliptra source defects and the
invocation is not a reproducible compile result. The generated UVMF host
packages and environment remain unqualified. See the
[host-package compile evidence](../../evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/README.md).

## Native AXI implementation slices

An independently authored passive checker now lives at
[`dv/caliptra_bfm/axi/axi4_caliptra_checker.sv`](../../dv/caliptra_bfm/axi/axi4_caliptra_checker.sv).
It is parameterized for the native Caliptra bus and checks channel stability
under backpressure, supported burst shapes and 4KB boundaries, AW/W pairing
and WLAST, one outstanding transaction per ID, and response ID/length matching.
For exclusive requests it enforces Arm's 16-transfer, power-of-two byte count,
128-byte maximum, and total-size alignment rules in [IHI0022L §A6.3.3](https://documentation-service.arm.com/static/68b03beb01ae952d9559f9eb).
The aligned-transfer requirement is an explicit Caliptra-profile restriction.
It does not claim to reproduce the full Arm Axi4PC rule set or mailbox USER
policy.

[`axi4_caliptra_master.sv`](../../dv/caliptra_bfm/axi/axi4_caliptra_master.sv)
adds serialized burst tasks with AW/W concurrency, address/data USER, LOCK,
response USER, response ID/LAST checks, and fail-stop timeout behavior. The
manager's success flag means the transaction completed with valid framing and
matching IDs with an OKAY/EXOKAY response; AXI SLVERR/DECERR makes success
false while the response code is still returned. Timeout or framing mismatch
requires reset before reuse.

`tests/run_checker.sh` passes the positive two-beat read/write with AW/W/R
stalls, legal W-before-AW and cross-ID response reordering, and a legal
exclusive read/write shape. It calls its `check_idle` drain hook and rejects
fifteen injected faults: AW payload mutation, R payload mutation, early WLAST,
missing final WLAST, early RLAST, a 4KB crossing, unmatched BID and RID,
an incomplete read at drain, a B response before write-data completion,
duplicate outstanding write or read IDs, an exclusive address misalignment,
an exclusive burst over 16 transfers, and a non-power-of-two exclusive byte
count. `tests/run_qd.sh`
continues to pass the copied QD-BFM's single-beat positive and negative
controls. All use the installed Icarus 13.0 system simulator. The checker,
manager, subordinate, and Caliptra AXI complex BFM logs are retained in the
[exclusive-checker evidence](../../evidence/caliptra-bfm-axi-exclusive-checker-20261006/README.md).
`tests/run_master.sh` checks multi-beat transfer data and strobe handling,
USER/LOCK pass-through, AW/W/AR backpressure, read/write error responses,
timeout, reset recovery, and manager fail-stop behavior after bad BID/RLAST.
`axi4_caliptra_memory_subordinate.sv` adds one bounded SRAM-style window;
`tests/run_subordinate.sh` exercises queued burst storage/readback, stalls,
response USER, injected SLVERR, unmapped DECERR, and AXI4 exclusive access.
Its per-ID monitor checks the Caliptra-visible ID/address/length/size/burst
attributes, invalidates reservations on overlapping writes, returns EXOKAY on
success, and suppresses memory updates on failed exclusive writes. The
combined SRAM/FIFO wrapper leaves exclusives unsupported on the FIFO target,
which returns OKAY. The implementation follows the exclusive-monitor and
response behavior in [Arm IHI 0022H, §A7.2](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf).
The same test validates `axi4_caliptra_monitor.sv`'s five handshake-event
counters and packed channel records. It is a passive procedural record source,
not a UVM analysis port or a complete-transaction predictor. The new
`axi4_caliptra_transaction_monitor.sv` provides bounded completed read/write
records, with pre-AW W buffering and explicit framing/overlap/ID/capacity
errors. It supports one outstanding read and write and now defaults to a
256-beat record, matching Caliptra's AXI4 `LEN` range. The UVM mailbox, proxy
payloads, and analysis records were widened to preserve all 256 beats, and
WSTRB packing is four bits per beat for Caliptra's 32-bit bus. The updated
short- and full-burst UVM smokes were rerun after the width change and pass.
It emits flattened procedural records, not a UVM analysis item. Later
work added a diagnostic full-top first AES/DMA pass; stock firmware, the full
suite, and official UVM regression remain unqualified (see the dated result at
the end of this note). The ECC unit-level AHB counterparty smoke is recorded
below, and the actual `axi_dma_top` block integration smoke is in the later
DMA section.

## Official AXI analysis consumer boundary

The pinned sources contain adapter and consumer code, but not the Avery
`aaxi_master_tr` class definition or agent implementation. The BFM now has a
clean-room lower-bound item in `aaxi_uvm_pkg` and an `aaxi_ap` projection from
its completed AXI monitor. A bounded, read-only second-model audit confirmed
that the fallback exposes every directly observed `aaxi_master_tr` field and
method used by the pinned SoC-IFC predictor, scoreboard, and coverage
subscriber. That member census does not establish behavioral compatibility.

| Consumer | Type/event connection | Visible `aaxi_master_tr` API use | What a clean-room implementation must cover |
| --- | --- | --- | --- |
| SoC predictor (`soc_ifc_predictor.svh`) | `axi_sub_0_ae` receives `aaxi_master_tr`; environment connects separate manager `ms_tx_AW_W_export` and `ms_rx_rvalid_export` sources to it. | `addr`, `kind`, `resp`, `data`, `beatQ`, `awuser`, `aruser`; `is_write()`, `is_read()`, `copy()`, `sprint()`. It changes expected `data`, `beatQ`, and `resp` for mailbox/accelerator policy effects and forwards transactions to register prediction. | The fallback class exposes each observed member/method. `ms_tx_AW_W_export` publishes the assembled write request after AW and all W beats are accepted, before B; `ms_rx_rvalid_export` publishes the assembled read on final R. Exact Avery object reuse, partial records, read granularity, and ordering remain unverified. |
| AXI scoreboard (`soc_ifc_scoreboard.svh`) | Separate expected and actual analysis imports, both typed as `aaxi_master_tr`; Avery's `write_done_export` and `read_done_export` are connected to the actual import. | `addr`, `beatQ[0]`, `kind`, `resp`; `compare(expected, diff, kind)`, `convert2string()`. It also uses factory casts and queues transaction handles. | The lower-bound agent provides direction-filtered `write_done_export`/`read_done_export` records with independent objects. Its event timing and compare policy are not a verified replica of Avery's. |
| SoC AXI coverage (`soc_ifc_env_cov_subscriber.svh`) | `axi_ae` is an analysis import of `aaxi_master_tr`. | `addr` to identify the register and sample mailbox sequences. | The lower-bound agent publishes completed addresses through the observed manager-event ports, but coverage sampling and ordering have not been run in the Caliptra environment. |
| Register predictor and adapter (`soc_ifc_environment.svh`, `caliptra_reg2axi_adapter.svh`) | `aaxi_uvm_reg_predictor #(aaxi_master_tr)` receives predictor read/write exports; Caliptra aliases the class as `axi_reg_transfer_t`. | Adapter explicitly reads `kind`, `awuser`, and `aruser`; its superclass `aaxi_uvm_mem_adapter` also maps the remaining register operation fields through `reg2bus`/`bus2reg`. The adapter sets both address USER fields from the UVM register extension. Prediction callbacks read `bus2reg_user_obj.get_addr_user()` after `bus2reg`. | The lower-bound BFM now provides `aaxi_uvm_mem_adapter`, `aaxi_uvm_reg_predictor` with the observed export names, an `aaxi_uvm_sequencer` and pin-level driver, and a Caliptra USER-aware adapter. Its end-to-end smoke performs native and AAXI-style RAL writes/reads, checks USER callbacks, and feeds actual monitor records to both predictor exports. Full Avery and generated UVMF behavior remain unverified. |

The source-level member census is complete for these three consumers, but the
configured event graph's behavior is not. In `soc_ifc_environment.svh`, both
`ms_tx_AW_W_export` and `ms_rx_rvalid_export` feed the predictor and coverage
subscriber, while `write_done_export` and `read_done_export` feed the actual
AXI scoreboard. The lower-bound BFM now exposes all four separately named,
direction-filtered analysis ports. The write request port publishes after AW
and all W beats are accepted, before B; write completion publishes after B.
Read request and done publish the assembled read on final R. The active/passive
generated-path smoke checks the write request precedes `write_done_export`.
It also consumes `ms_rx_rvalid_export`, checks the assembled read payload and
AxUSER, verifies its timestamp matches `read_done_export`, and mutates that
event's data to prove the done export received an independent copy. The
available pinned sources still do not reveal Avery's object reuse, partial
snapshots, read granularity, or exact event ordering, so equivalence remains
unverified.

The clean-room fallback now includes `aaxi_uvm_pkg::aaxi_master_tr`,
`aaxi_uvm_mem_adapter`, `aaxi_uvm_reg_predictor`, `aaxi_uvm_sequencer`, a
USER-aware register adapter, and an active pin-level AXI driver/agent. The
UVM smoke sends frontdoor reads/writes through that AAXI-style path and feeds
real monitor records into both predictor exports. It now also provides the
observed `aaxi_tb.env0.master[0]` component hierarchy, its `cfg_info` fields,
`aaxi_uvm_container`, `aaxi_protocol_version`, a Caliptra-profile
`aaxi_pkg`/`aaxi_intf`, and a pin-level `aaxi_monitor_wrapper` backed by the
open profile checker, completed-transaction publisher, and default active
task-manager bridge. The focused generated-path smoke drives actual traffic
from its sequencer through the AAXI interface into Caliptra's `axi_if` and
checks both completed records. At the time this section was first recorded,
the full generated SoC-IFC host environment had not yet compiled. Its later
2026-10-05 generated-host runtime result is summarized below. The exact Avery
event lifecycle remains open. An earlier compile-only lane elaborated the
actual generated pin-level `hdl_top` with seven generated interface/driver/monitor
BFM sets and real `soc_ifc_top` RTL. That lane uses compile-only class proxies,
reset/Avery/coverage stubs, and guarded disposable overlays; by itself it does
not compile the generated host UVMF packages or establish runtime behavior. See
[`generated SoC-IFC HDL-top evidence`](../../evidence/caliptra-bfm-soc-ifc-generated-hdl-20261004/README.md).
`aaxi_pkg_xactor`/`aaxi_pll`/`rw_txn_pkg` remain
empty import shims, and `aaxi_pkg_test` contains only the observed
constructor-only `aaxi_log`.

The open UVM layer now has
both an active sequencer/driver through the native manager proxy and a passive
analysis adapter with its own transaction type. Both pass focused simulations
with the local UVM/DPI toolchain and intentionally make no source-compatibility
claim. A separate source review confirmed the port wiring and the following
AHB boundary: the predictor input is base-typed, then casts each item to the
exact parameterized `ahb_master_burst_transfer`; the predictor reads
`RnW`, `address`, `size`, `data[0]`, and `resp[0]`. The AHB scoreboard also
configures and casts that exact specialization. The native AHB item is neither
that class nor an MVC item, so direct analysis-port connection is incompatible.
The clean-room AHB adapter now emits separate predictor, scoreboard, and
coverage items under the observed `burst_transfer`, `burst_transfer_sb`, and
`burst_transfer_cov` keys through `ahb_lite_caliptra_qvip_compat_agent.ap[...]`.
This covers the keyed port names and inspected item shape, but not QVIP's
subenvironment/configuration or MVC sequencing behavior. Its focused UVM/DPI
smoke passes read/write, wait-state, and ERROR traffic through all three keyed
streams and checks that predictor, scoreboard, and coverage items are distinct.

For AXI, passive records complete at B/RLAST and the clean-room monitor now
projects those records into the observed `aaxi_master_tr` fields. The official
predictor connects to two named manager exports whose transaction timing and
payload variants are not defined in the available source. The done exports
feed the actual scoreboard, but their item lifecycle is likewise not visible.
The UVM-item fallback passes focused UVM/DPI tests for the observed fields and
methods, UVM factory creation/cloning, independent copies, and basic plus
DMA-target traffic, including USER/LOCK values and 256-beat records. The
item-level projection is therefore not proof of xactor or UVMF integration.
The focused Icarus test also passes `item.kind` directly to the compatibility
`compare`, matching the member-expression argument form used by the pinned
scoreboard.

## Generated ECC compile probe

The original proxy declarations
`ECC_in_pkg::ECC_in_monitor #(...) proxy` and
`ECC_in_pkg::ECC_in_driver #(...) proxy` failed in Icarus 13.0 even with the
package compiled first, matching Caliptra's `config/compile.yml`. A narrow
`parse.y` module-item rule now accepts the package-scoped parameterized class
property in both editions. The new official regression
`sv_package_param_class_handle_proxy` passes in `-g2017` and `-g2023`, and the
actual generated `ECC_in_pkg` package compiles in both modes. An early grouped
package-first compile appeared to expose an interface cycle, but a later probe
using Caliptra's exact configured source order compiles the actual BFM and bus
interfaces in both modes. Slang 11.0.448 accepts the minimal declaration as
well.

The minimal
[`package_scoped_parameterized_class.sv`](../../dv/caliptra_bfm/uvmf_lite/tests/reducers/package_scoped_parameterized_class.sv)
reducer records the original failure shape. The new compiler regression is
`ivtest/ivltests/sv_package_param_class_handle_proxy_2017.v` with its 2023
wrapper and paired golden output.

The generated package probe also exposed two lower-bound UVMF APIs:
`initiator_responder` and named `REQ`/`RSP` sequence parameters. The clean-room
bases provide both. Compiler gaps found in the generated environment were
isolated and fixed with focused regressions. Type-only validation recognizes a
final no-parentheses method's declared return type (needed for generated
`convert2string` concatenations); generic member-path checking defers an
inherited property rooted at an unbound type parameter until its concrete
specialization (needed for `configuration.ECC_in_agent_config`); and a final
no-parentheses method on an indexed class handle now uses the ordinary
function-call elaborator (needed for UVM RAL's `maps[j].get_full_name`). A
compile-fail control ensures the generic member-path deferral still rejects a
concrete type that lacks the requested member.

The package-scoped parameterized proxy-handle syntax has its own paired
reducer. The repeatable ECC probe follows the exact source order in pinned
`config/compile.yml` through `ECC_tests_pkg`. It compiles actual `ECC_in_pkg`,
`ECC_out_pkg`, `ECC_env_pkg`, `ECC_parameters_pkg`, `ECC_sequences_pkg`, and
`ECC_tests_pkg`, all four generated driver/monitor BFM interfaces, and both
generated bus interfaces. Both `-g2017` and `-g2023` report zero elaboration
errors at the 384-bit coverpoints in `ECC_out_transaction_coverage.svh:17`. It
does not compile the generated `hdl_top`/`hvl_top`, instantiate `test_top`, or
run generated UVM behavior. Wide automatic
coverpoint bins are represented exactly as leading-bit prefix blocks, including
uniform partitions with non-power-of-two bin limits. The focused 2017/2023
regression covers a 65-bit three-bin partition and 130-bit, 384-bit, and
512-bit automatic coverpoints, including bin-identity checks, a prefix crossing
a 64-bit boundary, and wide crosses.
Named exports from the clean-room base package resolve the generated
`ACTIVE`/`PASSIVE`/`INITIATOR`/`RESPONDER` references; compile-progress warnings
for generated coverage stubs remain, so this is not a complete environment
qualification. It
includes UVM's `uvm_reg_mem_shared_access_seq`, which uses the
indexed inherited-method spelling `maps[j].get_full_name`. Icarus now resolves
that through the ordinary function-call path; the focused no-parentheses
regression covers an inherited method on a selected queue element and string
concatenation. A read-only scan of the pinned generated transaction coverage
also found 512-bit HMAC/SHA512 outputs using the same automatic-bin shape, plus
256/512-bit explicit range bins in status/control packages. Focused regressions
check the 512-bit explicit-range shape, including endpoint and bin identity.
The exact `wildcard bins set/clr` transition patterns in
`cptra_status_transaction_coverage.svh:129-130` now parse and match in the
focused 2012/2017/2023 regression; an X/Z sample is a negative control. A
Bison comparison with only the two wildcard transition productions removed
shows no conflict-count increase (574 shift/reduce and 1122 reduce/reduce in
both grammars).

The generated status package was first retried in Caliptra's package/interface
source order with its generated BFM interfaces. The wildcard coverage
declarations pass; pristine elaboration then reaches invalid `$psprintf` calls
with trailing empty arguments in `cptra_status_configuration.svh:143`,
`cptra_status_driver_bfm.sv:90`, and `cptra_status_monitor_bfm.sv:66`. The
hash-guarded [status overlay probe](../../evidence/caliptra-bfm-generated-status-20261004/README.md)
removes only those empty arguments in a disposable copy and elaborates the real
status package, interface, driver, and monitor in IEEE 2017 and 2023, with
seven compiler warnings per edition. This is compile/elaboration evidence;
there is no status protocol traffic, coverage, DUT, or full UVMF
qualification. A separate
[generated status agent runtime probe](../../evidence/caliptra-bfm-generated-status-runtime-20261004/README.md)
constructs the actual active agent and verifies config-DB VIF retrieval and
driver/monitor proxy identity in both editions with zero UVM warnings, errors,
or fatals. It does not start a sequence or send transactions.
The same evidence also includes a passive generated monitor probe: a testbench
pin change raises the status error and updates the NMI vector, and the generated
analysis stream reports both correctly under both editions. It checks this
field/event subset only, with no driver sequence, coverage subscriber, or DUT.
The follow-up [full-snapshot probe](../../evidence/caliptra-bfm-generated-status-full-snapshot-20261004/README.md)
checks all 17 transaction fields on the startup reset-deassertion snapshot and
two distinct event snapshots under both editions. The four packed key/entropy
arrays use per-word patterns, and the reset fields check their active-low
polarity. The generated coverage subscriber is connected to `monitored_ap` and
receives all three records through its `write()` method. It passes with zero
UVM warnings, errors, or fatals; compile still reports seven coverage-stub
warnings. Icarus leaves functional covergroups as stubs, so this qualifies
subscriber delivery and calls into generated sampling code, not bin hits or
coverage percentages. Separate generated SoC-IFC runtime evidence exercises
the status monitor and scoreboard against the real `soc_ifc_top` through reset.
The generated driver's initiator task is a timing/copy skeleton and does not
drive status output pins. The pinned SoC environment configures the agent as
`RESPONDER` on DUT-driven status signals; its response records feed the
scoreboard. Active pin driving is not required for this interface role.
The clean-room UVMF base now supplies overridable `set_key`/`get_key`
accessors used by the status monitor and keyed scoreboards; a set/get/copy
probe passes under both editions using
`dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_transaction_key.sh`. The control
package has the same trailing-empty-argument issue in
`soc_ifc_ctrl_configuration.svh:152` and is not covered by the status overlay.
The ECC probe passes both editions with generated coverage-stub warnings; it
remains a syntax/elaboration check, not generated environment runtime or DUT
qualification.
Slang's earlier virtual-interface type diagnostic on the generated BFM
interface remains unqualified. No Caliptra generated source was changed.

The expanded 2026-10-04 probe command, package hashes, and exact scope are
recorded in
[`caliptra-bfm-generated-ecc-packages-20261004`](../../evidence/caliptra-bfm-generated-ecc-packages-20261004/README.md).

An earlier direct compile grouped the generated packages before the actual
interfaces and reported invalid module instantiation at the four proxy class
declarations. That was not Caliptra's configured order. Interleaving each
interface package, driver BFM, bus interface, and monitor BFM as in
`config/compile.yml` resolves the Icarus errors. This corrects the earlier
source-order-cycle diagnosis; it does not establish behavior on VCS or Questa.
The elaboration top instantiates all four BFMs against the actual bus interfaces
using full interface handles. The pinned ECC `hdl_top` fails in both editions:
its input driver assigns `hrdata`/`hreadyout` through `initiator_port`, where
both fields are inputs. A hash-guarded temporary overlay removes three modport
selectors and adds an explicit `1ns/1ps` timescale. It elaborates actual
`ecc_top` RTL and generated packages/interfaces/environment/sequence/test
packages under IEEE 2017 and 2023, with 35 compile-progress warnings per
edition. The pinned source is unchanged. The separate reset-monitor lane uses
another guarded overlay and passes the generated reset-only top runtime; it
does not establish ECC result sampling or keygen completion. See
[`generated ECC HDL-top evidence`](../../evidence/caliptra-bfm-generated-ecc-hdl-20261004/README.md).

## Generated SoC-IFC HDL-top compile — 2026-10-04

The generated SoC-IFC `hdl_top` compiles with the actual `soc_ifc_top` RTL,
seven generated interface/driver/monitor BFM sets, the open AHB/AAXI
compatibility sources, and the open DMA target. The replay applies hash-guarded
`$psprintf` and responder-modport overlays to disposable copies, expands the
Caliptra `.vf` variables for Icarus, and exits 0 with two warnings: mixed
timescales and coercion of the generated `security_state` port to `inout`.

The compile-only filelist uses proxy class declarations for the generated HDL
BFMs' referenced class surfaces, an empty Avery include shim, and reset and
coverage stubs. It does not compile the generated SoC-IFC host UVMF packages or
environment, execute a sequence, or establish Avery/QVIP behavior or
transaction-level coverage. The overlay changes 32 dual-role responder fields
in four disposable generated interfaces; original source hashes are checked.
The pinned Caliptra checkout remained clean. Reproduce with
[`the generated SoC-IFC HDL-top runner`](../../evidence/caliptra-bfm-soc-ifc-generated-hdl-20261004/README.md).

## Generated SoC-IFC host runtime — 2026-10-05

The host packages and generated environment now compile with the actual
`soc_ifc_top` RTL through hash-guarded disposable Icarus overlays. The generated
reset/power-on sequence and status responders run, and the active AAXI path
performs a write/read of `0x30048`; the scoreboard records five matches, no
mismatches, and zero UVM errors/fatals. This confirms the generated AAXI VIF
handoff for that test, not the exact Avery event lifecycle or full generated
sequence coverage. The [runtime evidence](../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md)
contains the pass log and source/runner details.

Initial generated-environment AHB RAL/MVC attempts stalled at simulation time
zero before power-on; the failing additions were removed. Later isolated,
hash-guarded runtime lanes succeeded: generated AHB RAL read of the mailbox
lock, lock-claim plus `MBOX_DLEN` write/readback, and a four-word mailbox
payload transfer through generated AHB RAL. The payload lane also passed its
single-bit SRAM injection check. These qualify selected generated active-AHB
paths, not the remaining generated AHB sequences, full coverage, or licensed
QVIP behavior. Details are in the [runtime evidence](../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md).

## Pinned AXI complex BFM package check — 2026-10-04

The repeatable `run_caliptra_axi_complex_bfm.sh` smoke now compiles the
replacement against Caliptra's actual `caliptra_top_tb_pkg.sv`, `soc_ifc_pkg`,
`axi_pkg`, and `axi_if`; the local package stub was removed. The smoke therefore
checks the real `axi_complex_ctrl_t` declaration and address/profile constants
while exercising the existing SRAM/FIFO, delay, recovery, error-injection, and
checker cases. Icarus uses Caliptra's `VERILATOR` preprocessor branch for the
unused bit-flip randomizer helper. With that branch selected, the actual-package
pin-level test passes. Without it, the included randomizer's `pre_randomize`
callback calls `$fatal` with a one-string form that Icarus rejects at runtime;
that helper is outside this BFM test's exercised contract. This is a stronger
integration check than the prior package stub, but it remains component-level,
not a Caliptra DUT run.

The wide-range review also found and closed two edge cases: wide intervals were
missing from `option.detect_overlap`, and the wide matcher rejected X/Z samples
instead of applying the existing 2-state coverage conversion. The regression
now checks the compile-time overlap warning, both 512-bit bin hits, all-X and
all-Z samples, and a known one bit amid X values. The 2017/2023 focused wide
automatic/range regressions pass, as do the generated ECC environment package
probe and actual-package AXI complex BFM smoke after the compiler update.

## Caliptra ECC AHB counterparty smoke — 2026-10-04

`dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_bfm.sh` compiles the
read-only pinned Caliptra `ecc_top.vf` source tree with the native manager,
profile checker, and monitor. The smoke drives a
32-bit write of `1` to the ECC interrupt-enable CSR at `0x804`, reads it back,
and checks that two transfers were recorded with no checker/monitor errors.
The implementation run passed using the local Icarus fork installed under
`/private/tmp/bfm-work-install` in 2012, 2017, and 2023 modes. Stock system
Icarus 13.0 stops earlier in unchanged Caliptra RTL on unsupported constructs,
so this specific RTL run must select the fork with `IVERILOG_BIN`/`VVP_BIN`.
The pass was not archived with a simulator hash or run log, so treat it as a
reported, repeatable unit smoke rather than durable qualification evidence.
The run exercises the ECC unit counterparty only; it does not start the
generated UVMF test or top-level Caliptra.

## Native UVM AHB agent against actual Caliptra ECC RTL — 2026-10-04

`dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_uvm_bfm.sh` compiles the
same pinned `ecc_top.vf` with the native UVM AHB command driver, pin-monitor
adapter, and Caliptra-profile checker. A UVM sequence writes `1` to the
interrupt-enable CSR at `0x804` and reads it back through the 32-bit AHB-Lite
interface. A direct sequence and UVM RAL frontdoor each write and read the
register. The sequence and RAL model check response/data; a passive UVM
subscriber checks all four monitor records; the checker and monitor counters
must remain clean and report exactly four accepted/completed transfers.

This path passed in IEEE 2012, 2017, and 2023 modes using the local Icarus fork
and Accellera UVM 2020.3.1. It crosses the native UVM sequencer/driver,
32-bit-configured RAL adapter, and monitor with a real Caliptra unit, beyond
the task-manager-only smoke. The UVM
report had zero warnings, errors, or fatals; Icarus emitted its mixed-timescale
warning. This remains unit-level DUT evidence: generated ECC UVMF interfaces,
the generated environment, and the full Caliptra top are not part of the run.
The pinned input, binary/source hashes, command, and summary are in
[`evidence/caliptra-bfm-ecc-ahb-uvm-20261004`](../../evidence/caliptra-bfm-ecc-ahb-uvm-20261004/README.md);
the runner's temporary raw logs are not retained.

## Native AXI UVM agent through Caliptra axi_if — 2026-10-04

`dv/caliptra_bfm/uvm/tests/run_uvm_axi_if.sh` compiles the native UVM AXI agent
and manager proxy against the pinned Caliptra `axi_pkg.sv` and `axi_if.sv`.
The proxy drives the interface signal members directly, the DMA target binds
to its real `w_sub`/`r_sub` modports, and the transaction monitor publishes
completed records through the agent analysis port. SRAM and FIFO sequences
plus a 256-beat SRAM write/readback passed on the local Icarus fork with UVM
2020.3.1. An injected one-beat read error also returns `success == 0` with
`SLVERR` to the UVM sequence and appears as the same response in the monitor
record. The run has zero UVM warnings, errors, or fatals. This closes the
active-UVM-to-typed-interface component boundary; it does not instantiate the
Caliptra DMA RTL or qualify its generated UVMF environment. The pinned
interface and generated ECC sources were not modified. Reproducible tool and
source hashes are recorded in
[`evidence/caliptra-bfm-axi-uvm-if-20261004`](../../evidence/caliptra-bfm-axi-uvm-if-20261004/README.md).

## Native UVM AXI exclusive accesses — 2026-10-05

The basic UVM agent run exercises a matching SRAM exclusive read/write and
readback, plus a failed exclusive write after an intervening ordinary write.
The sequence observes `EXOKAY` as successful and `OKAY` for the failed store;
both native and AAXI projected monitors preserve response and LOCK metadata.
Unit checks confirm both register adapters map successful `OKAY` and
`EXOKAY` responses to `UVM_IS_OK`. The basic guarded run passed with zero UVM
errors/fatals and two expected `PREDICT_NOK` warnings from injected `SLVERR`
reads. The combined DMA-map rerun also passes, including the invalidated
exclusive store, with zero UVM errors/fatals. It used a 50% free-memory floor,
completed with at least 66% free, and had the same two expected predictor
warnings.
Standalone AXI target tests cover failed stores and multi-beat exclusives.
Evidence and hashes are in
[`evidence/caliptra-bfm-uvm-agent-20261005`](../../evidence/caliptra-bfm-uvm-agent-20261005/README.md).

## Pinned Caliptra AXI managers against the recreated target — 2026-10-04

`dv/caliptra_bfm/uvm/tests/run_caliptra_axi_mgr_uvm_bfm.sh` elaborates the
pinned `axi_mgr_rd.sv` and `axi_mgr_wr.sv` with Caliptra's `axi_if`,
`axi_dma_req_if`, and `skidbuffer.v`. The actual 48/32/5/32 Caliptra manager
outputs connect to the open `axi4_caliptra_dma_if_subordinate` target; the
completed transaction monitor feeds the native UVM passive agent. A two-beat
ordinary SRAM write and readback passed, checking address/control, WSTRB,
WLAST, USER, payload, responses, and monitor framing. The UVM summary had zero
warnings, errors, or fatals; the default Caliptra assertion macros were
compiled. This exercises actual AXI manager RTL, but omits `axi_dma_ctrl`, the
DMA registers, and `axi_dma_top`. Exact tool and source hashes are recorded in
[`evidence/caliptra-bfm-caliptra-axi-mgr-20261004`](../../evidence/caliptra-bfm-caliptra-axi-mgr-20261004/README.md).

## Pinned Caliptra `axi_dma_top` through the recreated target — 2026-10-04

`dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh` builds the
pinned DMA register block, `axi_dma_ctrl`, `axi_dma_top`, and actual AXI manager
modules with Caliptra's `axi_if`. It compiles the pinned Caliptra
`caliptra_top_tb_pkg` and `dma_transfer_randomizer` class. To accommodate
Icarus's required numeric `$fatal` finish argument, the runner makes a
temporary one-line compatibility copy of the randomizer class; it does not
modify the pinned checkout. Seed `0x00c0ffee` selects an AXI-to-AXI 65-word
transfer at source offset `0x308` and destination offset `0x6d0`, with a
randomized payload. The test programs the resulting addresses, 260-byte count,
zero block size, and legal route pair through the DMA top's CSR request
interface. Caliptra's 256-byte boundary splits reads 62+3 beats and writes
12+53 beats. A passive native UVM subscriber checks the completed burst items,
including the randomized data, and the test checks destination contents and
`STATUS0` idle/error fields. Its UVM report had zero warnings, errors, and
fatals; the default Caliptra assertion macros remained enabled.

The runner also injects AXI `SLVERR` in a separate run. The real control FSM
reaches `DMA_ERROR` after a 62-beat source read and 12-beat destination write;
the monitor checks the error response on both records, and the test verifies
that the written 12-word prefix matches the payload while the 53-word tail
remains untouched. That UVM report also had zero warnings, errors, and fatals.

This is the first run here through the real `axi_dma_top` control FSM and
register block. It uses one seeded constrained case from Caliptra's
`dma_transfer_randomizer` class. Separately, the hash-guarded DCCM replay
profile requests 29 records from the actual `dma_testcase_generator` and
selects each record through the real `axi_dma_top`. It covers all five named
routes, eight short sizes (1, 4, 5, 16, 64, 65, 255, and 256 words), a maximum
65,536-word fixed-read FIFO-to-SRAM stream, a fixed-write SRAM-to-FIFO record,
and FIFO recovery records for AXI2AXI, AXI2MBOX, and AXI2AHB. The three recovery
records sweep every legal one-hot block size for their route: 4–64 bytes on
AXI2AXI and 4–2048 bytes on AXI2MBOX and AXI2AHB. Short records retain
per-record seeds, payloads, valid offsets, and Caliptra's delay flag. For the
maximum case, the BFM supplies FIFO data and the UVM scoreboard checks the
complete destination stream. The first 25 records retain the recorded route
distribution: AHB2AXI (2), MBOX2AXI (6), AXI2AXI (5), AXI2MBOX (5), and
AXI2AHB (7); added records 25–28 cover FIFO destination and all three recovery
routes. One short record applied the generated delay flag and observed five
target-stall cycles. Other generated FIFO modes, firmware-triggered reset,
firmware, and full-top execution remain unqualified.
Separate directed AXI2MBOX and MBOX2AXI cases now
transfer 65 words through the same DUT. The mailbox endpoint applies one-cycle
backpressure and checks request addresses, metadata, and data; the SRAM target
and AXI scoreboard check the MBOX2AXI writes. AHB2AXI also transfers 65 words
through the component `WRITE_DATA` register; AXI2AHB drains through `READ_DATA`.
Both are component-register checks without an AHB bus instance. All five named
routes now have generated-route coverage plus directed 65-word DUT coverage;
other transfer sizes/flags, firmware, full SoC/top, and generated UVMF execution
remain open. The routed generated recovery sweep is recorded in
[`AXI2MBOX/AXI2AHB recovery evidence`](../../evidence/caliptra-bfm-dma-routed-recovery-sweep-20261006/README.md).
The same DUT runner now checks a 65-word SRAM-to-FIFO AXI2AXI case through five
fixed write bursts under weighted AXI-channel stalls, validating that
backpressure occurred, plus FIFO depth and each queued payload word.
Results and source hashes are in the
[`25-record DMA DUT replay evidence`](../../evidence/caliptra-bfm-dma-generator-dut-replay-20261006/README.md)
and [`all-route DUT evidence`](../../evidence/caliptra-bfm-dma-all-routes-20261006/README.md),
plus [`initial DMA DUT evidence`](../../evidence/caliptra-bfm-caliptra-dma-top-20261004/README.md).

## PCRVault client and AHB BFMs against actual RTL — 2026-10-04

`dv/caliptra_bfm/pv/pv_caliptra_master.sv` adds the missing active PV client
driver. The generated `pv_read_driver_bfm::initiate_and_get_response` task
drives the read request but fills its response struct from `pv_read_i`, which
is the request wire; it does not sample the actual `pv_rd_resp_i` response.
The new clean-room driver samples `pv_rd_resp` on the next rising edge and
keeps its read and write channels independently usable.

The [actual-RTL probe](../../evidence/caliptra-bfm-pv-actual-rtl-20261004/README.md)
instantiates Caliptra's pinned PCRVault DUT with the native client master and
64-bit AHB manager. It passes client read/write concurrency, PV client
readback, AHB readback of that same word, control-register AHB lane handling,
terminal `last`, invalid-offset rejection, and reset-abort handling under
IEEE 1800-2017/2023.

The native UVM PCRVault agent now drives the same client BFM through its
sequencer/command proxy. Its [actual-RTL run](../../evidence/caliptra-bfm-pv-uvm-actual-rtl-20261004/README.md)
checks UVM sequence write/read response and publishes matching completed
command records from the real PV response pins. PV reads have no request-valid
signal, so this monitor reports the proxy's completed command boundary rather
than claiming raw-pin-only passive request detection.

The [generated-top elaboration probe](../../evidence/caliptra-bfm-pcrvault-generated-hdl-20261004/README.md)
also compiles the real generated PCRVault `hdl_top`, its PV BFM packages, and
the clean-room AHB wrapper in both editions. It is static elaboration only:
the empty coverage-bind stub has no coverage behavior, and no generated test
sequence or full UVMF environment is run. A hash-guarded temporary source
overlay fixes three trailing empty `$psprintf` actuals and replaces two
driver modport connections with complete interfaces because the generated
generic driver has conditional output assignments that do not fit those
initiator modports in this flow. The pinned Caliptra checkout remains clean.

One RTL behavior needs separate spec reconciliation: `pv.sv` currently drives
both client response error fields to zero and does not mask crypto-client
write enable with the PCR lock. The probe confirms control-register AHB lane
access but makes no claim that the lock rejects a PV client write.

## Next implementation boundaries

1. Keep the observed `aaxi_master_tr` member census as the structural gate,
   then establish the Avery event contract and license boundary for the four
   configured manager exports. The clean-room path publishes write requests
   before B and write completion after B; read-valid/read-done publish
   independent assembled records on final R. The generated-path regression
   checks both event ordering and read snapshot isolation. Avery's partial-item
   lifecycle, read granularity, and exact ordering remain open.
   Separately verify the pinned Caliptra DMA testcase generator's output in a
   full DUT integration.
2. Add a multi-region AHB address map if the consumer inventory requires it;
   the current AHB-Lite manager/monitor/checker/memory slice passes focused
   simulation and write/readback against Caliptra's ECC and PCRVault RTL.
3. Continue connecting the native UVM driver/sequencer and passive analysis
   adapter to generated consumers. The generated PCRVault test passes against
   actual PV RTL with the clean-room base/AHB surfaces and hash-guarded
   compatibility overlays. The generated KeyVault `kv_rand_wr_rd_test` also
   passes against actual KeyVault RTL under IEEE 2017 and 2023 with its
   hash-guarded event-order overlay. These are block-level results; neither
   establishes licensed UVMF/QVIP compatibility. The generated SoC-IFC host
   packages now compile and the selected reset/power-on plus AAXI runtime
   passes; selected generated active-AHB RAL/mailbox lanes also pass through
   the open manager and actual SoC-IFC RTL. Other sequences and full coverage
   remain unqualified. Without a source overlay,
   the retained control-package replay reports eight explicit unsupported
   full-domain coverage filters. The exact hash-guarded wildcard overlay
   compiles the generated control-package reducer and its mask semantics pass
   the exhaustive byte smoke, but this does not qualify the generated coverage
   class at UVMF runtime. A one-off larger-filelist invocation emitted
   unresolved-type and macro-visibility diagnostics, but its inputs and log
   were not retained and the errors have not been root-caused. The active path drives the Caliptra
   DMA SRAM/FIFO map, including fixed-burst FIFO traffic and injected SLVERR;
   the AAXI projection, passive adapter, and AHB-Lite keyed agent pass focused
   UVM/DPI tests. WD
   `axi-vip` is ISC-licensed and remains a reference candidate. Its pinned
   source lacks Caliptra's LOCK/profile shape and fails the recorded
   compile-only probes on this Icarus fork. No VCS/Questa compatibility result
   is claimed.
4. Keep ARM Axi4PC equivalence unclaimed. The new checker covers a useful
   Caliptra subset, not every Axi4PC assertion.
5. Finish Phase 0's per-unit dependency and API inventory and reconcile the
   legacy test/group counts before treating the entire official DV matrix as a
   requirement denominator. The source manifest and focused SoC-IFC, ECC,
   PV, and KeyVault evidence do not yet establish complete coverage of every
   Caliptra unit environment.

A diagnostic full-top run now passes the first 1-dword AES/DMA case through
source write/read and destination write/readback, using a modified one-case
firmware image. Stock-firmware qualification, all 12 AES/DMA cases, and the
official UVM DV environment remain unqualified. The ECC unit-level and
`axi_dma_top` block-level counterparty smokes provide additional DUT evidence.
Pinned Caliptra/Adams Bridge sources were not modified.

## Generated HMAC environment integration probe — 2026-10-05

The actual HMAC controller RTL and generated HMAC UVMF packages, BFMs,
environment, and `HMAC_random_test` compile with the clean-room `uvmf_lite`
base. The combined simulation completes after a temporary HDL-top timescale
overlay and a temporary OpenSSL-output parser adjustment for the generated
`test_gen.py`. The pinned Caliptra checkout remains clean.

The unmodified generated output monitor emits a reset sample, then treats the
shared reset-complete flag as another output event. Its runtime reports 16
scoreboard mismatches and one leftover actual transaction (17 errors, zero
fatals), with the actual stream offset by one. A hash-guarded compatibility
overlay suppresses the reset-only sample while preserving the flag-triggered
digest capture. The same generated `HMAC_random_test` then completes with 17
predictor operations and zero UVM warnings, errors, or fatals. The pinned
Caliptra checkout remains unchanged. This qualifies only this generated HMAC
test under the overlay, not other HMAC sequences or the full Caliptra top.
Build and run details are recorded in
[`caliptra-bfm-generated-hmac-runtime-20261005`](../../evidence/caliptra-bfm-generated-hmac-runtime-20261005/README.md).

## AXI-complex replacement SRAM preload compatibility — 2026-10-06

The replacement now instantiates the combined DMA target directly as
`i_axi_sram`, exposing Caliptra firmware's
`i_axi_sram.i_sram.ram[addr][byte_idx]` preload path. Its focused test seeds
four bytes through that hierarchy and reads back `32'ha1b2_c3d4` over AXI.
The pinned Caliptra source search found this to be the only external reference
to the `tb_axi_complex_i` instance. The test also retains the synthetic error,
SRAM/FIFO, recovery, and random stall checks. The guarded
`dv/caliptra_bfm/axi/tests/run_caliptra_axi_complex_bfm.sh`,
`run_subordinate.sh`, and `run_dma_subordinate.sh` runs pass on this clone's
Icarus build; memory preflight observed 70% free for the top-complex test and
73% for the subordinate runs against a 60% floor. This proves the module
replacement and SRAM preload path, not the full Caliptra top-level testbench.
The guarded actual-`axi_dma_top` UVM regression also passes all directed cases
and 25 generated DCCM replays across all five DMA routes, including the
65,536-word case; each simulation reports zero UVM warnings, errors, or
fatals, and the guard records a 70% minimum free-memory watermark.

## AAXI read-valid event snapshot — 2026-10-06

The guarded `run_aaxi_compat.sh` generated-path smoke now connects all four
observed manager event exports. It checks that the assembled write request is
published before B completion and that `ms_rx_rvalid_export` publishes the
assembled read on the same final-R cycle as `read_done_export`. The read
observer verifies address, ID, ARUSER, data, and response, then mutates its
copy; the read-done observer still receives the original data. The run passes
with zero UVM errors/fatals, 76% free memory at preflight, and 75% minimum
against the 60% guard floor. This strengthens the clean-room event contract;
it does not establish Avery's hidden partial-item lifecycle or exact timing.

## Quiet full AES/DMA top run — 2026-10-06

The guarded 1,800-second run retained all 12 AES/DMA firmware cases and used
fast TRNG, verified `.data` preload, skipped unrelated PQ vector generation,
and suppressed low-priority firmware prints. It timed out with
`CLP: ROM Flow in progress...`; no testcase pass/fail marker or `$finish` was
observed. The minimum free-memory reading was 68% against the 60% floor. AXI
tracing was not enabled, so the timeout does not establish whether DMA traffic
occurred. The [compact run record](../../evidence/caliptra-bfm-open-top-smoke-20261006/full-aes-all-cases-pqskip-quiet-timeout.json)
preserves log hashes; temporary simulator output was removed after the run.

## Traced single AES/DMA top runs — 2026-10-06

The guarded 900-second first-case diagnostic completed the real Caliptra top
with `TESTCASE PASSED` and normal `$finish` at cycle 5230 (1,857 retired
instructions). The open AXI target completed source write/read and AES
destination write/readback: two handshakes on each AXI channel. The guard
recorded 75% minimum free memory against a 60% floor. The
[passing record](../../evidence/caliptra-bfm-open-top-smoke-20261006/first-aes-axi-trace.json)
contains per-channel cycles, addresses, and source/image hashes.

A separate 600-second retry using the new `--trace-axi` runner timed out at
cycle 4463, before the testcase marker, after one AXI write and before any AXI
read. The [short-timeout record](../../evidence/caliptra-bfm-open-top-smoke-20261006/short-aes-one-case-axi-trace-timeout.json)
preserves that attempt; it does not supersede the longer passing run. The pass
uses a diagnostic firmware copy, fast TRNG, and PQ-vector suppression. Stock
firmware, the full 12-case suite, entropy timing, and general AXI signoff
remain unqualified.
