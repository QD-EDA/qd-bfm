# Caliptra AXI BFM components

This folder contains the imported directed QD-EDA manager, a Caliptra-profile
task-based AXI manager, protocol checker, single-window memory subordinate,
and passive handshake monitor. These are the first native components of the
open BFM stack; they are not yet a complete Avery replacement.

The combined AXI and AHB-Lite source list is
[`../caliptra_bfm.f`](../caliptra_bfm.f), intended to be invoked from the
repository root with the consuming testbench appended.

## Task-based manager

[`axi4_caliptra_master.sv`](axi4_caliptra_master.sv) drives all AXI4 manager
channels, including address/data USER and LOCK, independent AW/W handshakes,
bursts up to `MAX_BEATS`, and B/R response USER. `write_burst` and `read_burst`
accept packed beat arrays with beat zero in the least-significant slice. Up to
Up to `MAX_OUTSTANDING` reads and writes may be outstanding independently
(default 4 per direction). Read and write responses are routed by RID/BID,
including out-of-order responses for different IDs and in-order responses for
repeated IDs. AW and W retain independent handshakes; write data transactions
are issued in order because AXI4 has no WID. Reads and writes can run
concurrently. A protocol mismatch or timeout poisons the manager; assert reset low and call
`reset_master` before reuse. Reset also aborts in-flight tasks, returns them
unsuccessful, and clears their channel outputs; call `reset_master` after they
exit.
The `success` output is false for SLVERR/DECERR, while `BRESP`/per-beat
`RRESP` preserve the target's response code. Invalid aligned/burst/4KB profile
requests are rejected before VALID is asserted.

Run the two-beat USER/LOCK/stall test, W-before-AW write completion, response
errors, timeout/reset recovery, read/write reset aborts, bad BID/RLAST fail-stop
tests, and five-deep read/write queue tests with out-of-order responses using:

```sh
./tests/run_master.sh
```

## Memory subordinate

[`axi4_caliptra_memory_subordinate.sv`](axi4_caliptra_memory_subordinate.sv)
provides a bounded SRAM-style target with up to `MAX_OUTSTANDING` accepted
reads and writes per direction, independent READY stalls, FIXED/INCR/WRAP
address progression, byte strobes, B/R ID and USER responses, DECERR for
unmapped addresses, and injectable SLVERR. W data is consumed in AW order and
B responses are queued; read bursts are returned in AR order without beat
interleaving. It accepts W only after AW, which is legal AXI backpressure. The
model is one mapped memory window; it does not model Caliptra's FIFO side
effects or combined SRAM/FIFO decode. Its per-ID exclusive monitor returns
EXOKAY for a valid exclusive read and a successful matching write. A write to
any monitored byte invalidates that reservation; a failed exclusive write
returns OKAY and leaves memory unchanged. LOCKed writes are serialized around
the data phase. The FIFO subordinate does not support exclusives and returns
OKAY for LOCKed accesses. Reset clears protocol queues and reservations without
clearing memory. The subordinate regression covers queued traffic and both
successful and invalidated exclusive sequences.

Run its end-to-end manager/checker test with:

```sh
./tests/run_subordinate.sh
```

## FIFO stream subordinate

[`axi4_caliptra_fifo_subordinate.sv`](axi4_caliptra_fifo_subordinate.sv)
models one bounded, word-wide stream FIFO behind the Caliptra AXI profile.
Each accepted W beat enqueues one word; each read beat moves one word into the
AXI response register when RVALID is first presented. Reads wait while the
FIFO is empty, writes backpressure while it is full, and the `fifo_clear`
input synchronously flushes queued words. FIXED bursts of up to 16 full-width
aligned beats are supported. Invalid address/shape requests return DECERR;
`inject_error` returns SLVERR without changing queue contents. The module
supports one outstanding read and one write, echoes ID and USER responses,
and exposes occupancy through `fifo_level`. A later clear drops queued words
but does not retract a response beat already presented on RVALID.

The default data width is 32 bits, and `FIFO_CAPACITY_BYTES` defaults to
64 KiB. `fifo_level` reports queued words and excludes an R beat already
presented on the response channel. Address selection uses a high-bit prefix
with `DECODE_LOW_BITS=18`, matching the pinned testbench's
`AXI_FIFO_ADDR_WIDTH`; its actual decoder block is 256 KiB and the declared
FIFO base lies inside that block. The combined-map wrapper performs the same
prefix decode before routing requests. `fifo_push_event` and
`fifo_pop_event` report queue insertion and word consumption, including
autonomous traffic, and are exposed by the DMA map.

The DMA wrapper's optional `auto_fifo_push` and `auto_fifo_pop` inputs model
the pinned testbench's autonomous producer/consumer traffic. The producer
inserts a random 32-bit word after a weighted 0..255-cycle gap, holds the word
while the FIFO is full, and takes priority over AXI WDATA when both request a
write in the same cycle. The consumer discards one queued word after the same
weighted delay; it shares a FIFO read with AXI response capture when both are
active. The weighted delay matches the pinned constrained-random weights, but
the generated random sequence is not cycle-for-cycle identical. All optional
clear, stall, error, and auto-traffic controls are inactive when left
unconnected. Block-size and threshold inputs can be supplied manually through
`recovery_block_words` and `recovery_threshold_words`, or selected by the
companion recovery sequencer described below.

The FIFO treats each accepted AXI beat as a complete word and ignores WSTRB,
WUSER, AWLOCK, and ARLOCK, matching the pinned wrapper where those component
signals are unconnected. `tests/run_dma_subordinate.sh` simulates the combined
SRAM/FIFO map, read/write paths, unknown optional controls, autonomous FIFO
push and pop, and recovery sequence integration. This remains a standalone
BFM test; no Caliptra DUT integration run has been done.

## Recovery data availability

[`axi4_caliptra_recovery_avail.sv`](axi4_caliptra_recovery_avail.sv) models
Caliptra's not-empty, threshold, and block-pulse `recovery_data_avail` modes.
Select a fixed mode with `MODE=1` (not-empty), `MODE=2` (threshold), or
`MODE=3` (pulse); `MODE=0` uses the pinned mode plusargs and otherwise chooses
one mode randomly. Threshold mode uses `threshold_words`; pulse mode uses
`block_words`. The combined DMA subordinate instantiates this model, connects
its `fifo_level`, `fifo_push_event`, and `fifo_pop_event`, and exposes
`recovery_data_avail`; callers provide `en_recovery_emulation`,
`recovery_threshold_words`, and `recovery_block_words`. The model checks that
recovery emulation starts with an empty FIFO and counts queue events while
emulation is enabled.

[`axi4_caliptra_recovery_sequence.sv`](axi4_caliptra_recovery_sequence.sv)
consumes the pinned 100-entry, 12-bit DMA block-size array and selects a
threshold from 1 through each block's word count. It loads after
`dma_gen_done`, skips zero-sized entries, advances after
`en_recovery_emulation` falls, and retries the current entry after reset. The
pinned Caliptra generator is Apache-2.0 source at
`src/integration/tb/dma_testcase_generator.sv`; its packed
`logic [99:0][11:0]` output can connect directly to the flattened BFM input of
the same width. In the DMA wrapper, set `use_dma_gen_sequence=1` and connect
`dma_gen_done` plus `dma_gen_block_size_bytes`. With that control low, the
wrapper uses the manual block and threshold inputs.
`tests/run_recovery_sequence.sh` checks the 100-entry packed interface,
zero-entry skipping, random threshold bounds, reset retry, and end-of-list;
`tests/run_dma_subordinate.sh` checks sequencer use through the wrapper.

## Caliptra DMA map wrapper

[`axi4_caliptra_dma_subordinate.sv`](axi4_caliptra_dma_subordinate.sv)
routes the 48-bit DMA bus to the 256 KiB SRAM model or the FIFO endpoint using
the pinned top's 18-bit low-address prefix decode. Non-FIFO traffic is passed
to the bounded queued SRAM target, which returns DECERR for addresses outside
its range. The wrapper tracks up to `MAX_OUTSTANDING` accepted requests per
direction, routes W beats in AW order, and records each request's backing
target through response completion. B and R responses are released in accepted
AW/AR order across SRAM and FIFO, preserving AXI same-ID ordering even when a
later target becomes ready first. This intentionally serializes responses
across different IDs; per-ID reordering is unnecessary for Caliptra's current
one-outstanding-per-direction manager profile. The FIFO endpoint itself remains
single-outstanding per direction. The wrapper supports simultaneous read and
write traffic and includes the recovery availability policy plus optional
autonomous FIFO traffic. Its optional
recovery sequencer consumes the packed block-size list from Caliptra's existing
Apache-2.0 DMA testcase generator. `tests/run_dma_subordinate.sh` now covers
mixed SRAM/FIFO request routing and response arbitration. It also asserts
reset with a partial write, a pending B response, and a pending R response,
then checks that the map accepts fresh traffic after each reset. The UVM
`run_caliptra_axi_dma_top_uvm_bfm.sh` also connects this target to the pinned
DMA DUT and checks a 65-word FIFO-to-SRAM recovery transfer using one
64-byte generated-block entry. The actual-DUT runner now replays all 27
ECC-checked records from generator DCCM staging through the DMA DUT under a
hash-guarded profile spanning all five named DMA routes, eight short sizes, and
a maximum 65,536-word fixed-read FIFO-to-SRAM stream. Short records retain
per-record randomized payloads, route-valid offsets, and Caliptra's delay flag;
the maximum stream checks every destination word and drains the source FIFO.
The added 65-word generated SRAM-to-FIFO record checks the FIFO destination
using fixed writes and randomized target delays. Another generated 65-word
FIFO-source record exercises the recovery sequencer with a 64-byte block.
The same DUT bench also checks directed
65-word AXI2MBOX and MBOX2AXI transfers with one-cycle mailbox backpressure and
per-request address, metadata, and payload checks. AHB2AXI transfers 65 words
through the component `WRITE_DATA` register; AXI2AHB drains 65 words through
`READ_DATA`. Neither lane instantiates an AHB bus. One generated 65-word
SRAM-to-FIFO record also checks five fixed write bursts with randomized target
stalls; other generated sizes, FIFO modes, firmware-triggered reset injection,
and block-size values remain unqualified. The separate directed SRAM-to-FIFO
test continues to check 65 payload words across five fixed write bursts while
the target applies weighted random channel stalls.
The standalone
generator-to-recovery-sequencer test is recorded in
[`evidence/caliptra-bfm-dma-generator-20261006`](../../../evidence/caliptra-bfm-dma-generator-20261006/README.md),
and the DUT replay in
[`evidence/caliptra-bfm-dma-generator-dut-replay-20261006`](../../../evidence/caliptra-bfm-dma-generator-dut-replay-20261006/README.md).
All five directed routes are recorded in
[`evidence/caliptra-bfm-dma-all-routes-20261006`](../../../evidence/caliptra-bfm-dma-all-routes-20261006/README.md).
The generated FIFO-destination replay is recorded in
[`evidence/caliptra-bfm-dma-generated-fifo-destination-20261006`](../../../evidence/caliptra-bfm-dma-generated-fifo-destination-20261006/README.md).
The generated recovery block-size replay is recorded in
[`evidence/caliptra-bfm-dma-generated-recovery-block-20261006`](../../../evidence/caliptra-bfm-dma-generated-recovery-block-20261006/README.md).

## Caliptra top-testbench replacement

`caliptra_top_tb_axi_complex_bfm.sv` instantiates the combined target as
`i_axi_sram`, preserving the firmware preload hierarchy
`tb_axi_complex_i.i_axi_sram.i_sram.ram[addr][byte_idx]`. The SRAM exposes
byte lanes at that path. `tests/run_caliptra_axi_complex_bfm.sh` writes a word
through that backdoor and checks it through an AXI read, then exercises the
one-shot error range, FIFO controls, recovery signal, and random stalls. This
module smoke also checks the production non-DMA case: the recovery sequence is
armed only when `+CPTRA_RAND_TEST_DMA` is present, because the pinned generator
leaves its block-size array unknown otherwise. The test fails on that X array
without the gate and passes with it. Full-top runs using the replacement are
recorded in
[`open-top smoke evidence`](../../../evidence/caliptra-bfm-open-top-smoke-20261006/README.md).
The 2026-10-07 wrapper smoke also writes 208 deterministic SRAM words through
AXI and reads them back in thirteen 16-beat INCR bursts, checking every data
word, response, ID, USER, and LAST field. The guarded run passes with Icarus
`ac4532fa-dirty`; treat it as diagnostic only until repeated with a clean,
published simulator revision. This isolates the open target's full-payload
burst path, not the actual DUT DMA FIFO readback that remains open.
The guarded 900-second first-case AES/DMA diagnostic passes through the
real top and records source write/read plus AES destination write/readback.
The [passing record](../../../evidence/caliptra-bfm-open-top-smoke-20261006/first-aes-axi-trace.json)
contains the channel events and hashes. A separate 600-second retry with the
new `--trace-axi` runner stopped at cycle 4463 before a testcase marker; its
[timeout record](../../../evidence/caliptra-bfm-open-top-smoke-20261006/short-aes-one-case-axi-trace-timeout.json)
is a shorter-bound attempt and does not supersede that pass. The earlier boot
case had no DMA traffic. The passing run uses a diagnostic firmware copy, fast
TRNG, and PQ-vector suppression, so it does not qualify stock firmware or the
full suite.
On 2026-10-08, twelve isolated runs of the short AES/DMA firmware vectors passed
through this full-top target with `CALIPTRA_BFM_CHECKER` enabled. They exercised
one- through twelve-beat source buffers; vectors five through twelve also
exercised split destination writes. The logs show no W-channel stalls or checker
errors.
See the
[`one-to-twelve-beat trace evidence`](../../../evidence/caliptra-bfm-open-top-wstate-20261008/README.md).
These are diagnostic runs on a dirty, unpublished simulator source revision,
not stock firmware or full-suite qualification.

## Passive handshake monitor

[`axi4_caliptra_monitor.sv`](axi4_caliptra_monitor.sv) emits a one-cycle pulse
for every accepted AW, W, B, AR, and R beat. Each pulse accompanies a packed
channel record holding ID, address/control, data/strobes, USER, response, and
LAST fields where present. Cumulative accepted counts are the denominators for
burst and LOCK bins on AW/AR, response bins on B/R, and WSTRB bins on W; LAST
counts are accepted asserted-LAST beats. `*_valid_cycles` counts rising-edge
samples with VALID high, and `*_stall_cycles` is the subset with READY low.
Accepted transfer cycles plus stall cycles equal valid cycles.
Unknown-value bins are included for burst, LOCK, response, and strobe fields.
`tests/run_subordinate.sh` checks these denominators and bins, including full,
partial, and zero WSTRB, and prints a compact coverage summary. The UVM pin
wrappers publish one `axi4_caliptra_channel_transaction` on `channel_ap` for
each accepted channel beat. The separate completed-transaction adapter groups
the same handshakes into read and write transactions. The recorded run is in
[`AXI coverage evidence`](../../../evidence/caliptra-bfm-axi-coverage-20261007/README.md).
UVM monitor reports carry the native accepted/valid/stall counts and print
burst, lock, response, strobe, and LAST bins with their accepted-beat
denominators.

## Completed transaction monitor

[`axi4_caliptra_transaction_monitor.sv`](axi4_caliptra_transaction_monitor.sv)
assembles completed transactions from channel handshakes. The write path
buffers W beats that arrive before AW, then checks the captured beat count and
WLAST positions against AWLEN. It tracks up to `MAX_OUTSTANDING` accepted AW
and AR requests. Since W has no ID, accepted W beats are assigned to AW
requests in address order; B responses are matched by BID, with same-ID
responses retired in request order. The read path associates each R beat by
RID, allows beats from different IDs to interleave, and retires same-ID
responses in request order. `write_complete` pulses when B is accepted;
`read_complete` pulses when an R beat with RLAST is accepted. Records include
address and control, all captured data/strobes/beat USER values, response
code/ID/USER, and AW/AR USER and LOCK. In the packed data, strobe, response,
USER, and LAST vectors, beat zero occupies the least-significant slice.
`*_cycle` records the monitor cycle on which the completed event was observed.

The monitor also exposes a write-request snapshot when AW and every W beat
have been accepted, before B arrives. The UVM compatibility monitor routes
that snapshot to `ms_tx_AW_W_export`; write completion still goes to
`write_done_export` after B. `ms_rx_rvalid_export` and `read_done_export`
publish the assembled read on final R. The focused AAXI smoke checks request
before completion; Avery's exact event and object lifecycle is still unknown.

The interface is deliberately bounded: `MAX_BEATS` defaults to 256 and must be
between 1 and 256; `MAX_OUTSTANDING` defaults to 8 and must be between 1 and
256 for reads and writes. One complete W-before-AW frame can be buffered until
its AW arrives. The monitor flags write overlap, orphan responses, capacity
overflow, malformed LAST/count framing, and response ID mismatch through
`*_error`, `*_error_code`, and the completed record's `*_status`.
Status/error codes are 0=OK, 1=shape/framing,
2=capacity, 3=response ID, 4=overlap, and 5=orphan. This is a procedural
transaction-record interface. The separate
[`../uvm/`](../uvm/README.md) layer publishes both its native UVM item and a
clean-room lower-bound `aaxi_master_tr` projection on `aaxi_ap`. This projects
the fields and methods observed in Caliptra consumers; it does not recreate
Avery's xactor/configuration/sequence implementation or establish identical
comparison and event-order semantics. The focused UVM/DPI tests exercise
factory creation/cloning, the observed copy/compare/print methods, USER/LOCK
projection, basic and DMA traffic, and 256-beat records.
`tests/run_transaction_monitor.sh` verifies packed completed records,
W-before-AW buffering, USER/response retention, framing and ID errors,
interleaved/out-of-order reads and writes across IDs, same-ID ordering, and
context capacity. The current direct-monitor result is recorded in
[`concurrency evidence`](../../../evidence/caliptra-bfm-axi-concurrency-20261005/README.md).

## Caliptra-profile checker

[`axi4_caliptra_checker.sv`](axi4_caliptra_checker.sv) is a passive flattened
pin checker for Caliptra's native AXI interface. It checks all five channel
payloads remain stable while VALID is held against READY backpressure, rejects
unknown VALID/READY controls and active-channel payloads, validates
FIXED/INCR/WRAP burst shape and the 4KB rule, tracks AW/W beat pairing across
independent channel timing, checks WLAST against AWLEN, validates WSTRB against
the active lanes for narrow FIXED/INCR/WRAP transfers, and matches B/R
responses to active IDs and lengths. For exclusive reads and writes it enforces
Arm's 16-transfer limit, power-of-two byte count up to 128 bytes, and address
alignment to the total transfer size. It tracks up to `QUEUE_DEPTH` outstanding
requests per ID in address order, for both read and write responses, and permits
interleaving across IDs. The same depth bounds the global AW/W pairing queues.

Caliptra's interface does not expose CACHE, PROT, QOS, or REGION; the checker
cannot observe or validate those signals. It applies the Caliptra profile's
aligned-transfer requirement and requires an exclusive write to follow a
completed exclusive read with matching ID, address, length, size, and burst.
The checker tracks that per-ID monitor through the strobed W bytes: an
overlapping write before the exclusive AW invalidates it. It permits the
resulting failed exclusive write to return OKAY and rejects EXOKAY after
invalidation. This byte-level tracking matches the open memory subordinate and
follows [Arm IHI0022L A7.3.4](https://documentation-service.arm.com/static/68b03beb01ae952d9559f9eb).
The checker also rejects EXOKAY on ordinary reads/writes and mixed
EXOKAY/non-EXOKAY beats within one exclusive read; a failed exclusive read may
consistently return a non-EXOKAY status, after which a matching exclusive write
can only return OKAY.
The WSTRB lane check follows
[Arm IHI0022L A4.2.1/A4.2.2](https://documentation-service.arm.com/static/68b03beb01ae952d9559f9eb).
Mailbox USER policy and ARM Axi4PC's complete assertion set are also outside
the checker. It is a real protocol-checking component, not an Axi4PC drop-in.
Exclusive-size and pair rules follow
[Arm IHI0022L A6.3.3/A7.3](https://documentation-service.arm.com/static/68b03beb01ae952d9559f9eb).

Call `check_idle` from the testbench's drain/end-of-test check so outstanding
responses or incomplete write data cannot be left behind silently. The checker
does not impose a wall-clock response timeout; that policy belongs to the
testbench or active BFM.

Run the stalled multi-beat case, legal W-before-AW and cross-ID response
reordering, exclusive-monitor invalidation, narrow transfers, and forty
negative controls—including payload stability on all five channels—with:

```sh
./tests/run_checker.sh
```

## Directed single-beat manager seed

This folder also carries the Apache-2.0 QD-BFM single-beat AXI manager as a
small, usable helper for directed access to Caliptra v2.1.2's inbound SoC AXI
subordinate (`s_axi_w_if` / `s_axi_r_if`). The source is copied unchanged from
[QD-EDA/qd-bfm](https://github.com/QD-EDA/qd-bfm), commit
`d761ee8cc6594656e95582a28f471c473ebd1afc`; its SHA-256 is
`b93b03e7e7605749a9fb233fce1c9dd4105f9fd39714f4887144ad81029ea1a7`.
The Apache-2.0 license is included beside the source.

## Caliptra configuration

For the v2.1.2 SoC interface, the checked-in integration parameters resolve to
AW=19, DW=32, and IW=8. Override the module's default AW=32 when instantiating
it. The interface also has 32-bit USER fields, but this BFM has no USER or LOCK
pins; use it only for directed accesses whose behavior does not depend on those
sidebands. A testbench can wire the scalar AXI pins to `axi_if` fields, tie
unused request USER/LOCK signals low, and leave response USER fields unchecked.

The public tasks are:

```systemverilog
bfm.write_one(addr, data, strb, id, ok, resp);
bfm.read_one(addr, id, ok, data, resp);
```

Addresses must be aligned to `DW/8`. Each operation is one native-width,
`LEN=0`, FIXED transfer.
The implementation checks request-payload stability through ready stalls,
response IDs, and `RLAST`; AXI error responses set `ok` low.

## Deliberate limits

This is a bounded directed helper, not an Avery AXI VIP or UVM agent. It does
not implement multi-beat bursts, USER/LOCK, outstanding-transaction queues,
coverage, monitors, scoreboards, or UVMF sequence/configuration APIs. Use task
calls sequentially; the module does not track concurrent calls or reordered
responses. It also does not replace Caliptra's separate QVIP AHB-Lite agent or
ARM Axi4PC protocol checker.

Treat any timeout as terminal for this BFM instance. Request timeout leaves
VALID asserted to preserve the AXI handshake rule; response timeout can leave
a late response pending at the target. This source has no reset/abort method
that makes reuse safe. Run timeout and other fatal negative cases in disposable
simulations, and do not launch another transaction on the same instance after
a timeout.

The upstream QD-BFM repository includes an independent memory-target testbench
and `run.sh`. The copied baseline is exercised in `tests/run_qd.sh`, including
the Caliptra v2.1.2 AW=19/DW=32/IW=8 sizing. Set `IVERILOG_BIN` and `VVP_BIN`
to select another simulator installation. This directed test does not wire the
helper to the Caliptra DUT or validate USER/LOCK mailbox traffic. Treat the
code as an initial reuse slice, not qualified Caliptra DV evidence.
