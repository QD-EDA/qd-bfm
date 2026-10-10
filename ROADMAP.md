# QD-BFM: reusable protocol verification IP

## Full product destination

QD-BFM is intended to become a reusable library of many BFMs and protocol
verification components, with plain SystemVerilog and UVM integration. The
single-beat AXI helper and Caliptra adapter are the first delivery slices, not
the permanent scope. Expand AXI4 functionality and add independent manager and
subordinate agents, monitors, scoreboards, assertions and coverage. Add further
protocol families as named integration flows require them: Caliptra AHB-Lite
and OpenTitan TL-UL are concrete candidates; reuse existing open verification
components before writing replacements. Publish per-protocol role/version/
feature/width/simulator matrices. A qualified AXI slice does not complete the
multi-BFM library goal. Do not add unsupported protocol names as empty stubs.

## Starting baseline

Baseline `d761ee8cc6594656e95582a28f471c473ebd1afc`: standalone single-beat
AXI4 manager tasks; CI installs Icarus and runs `./run.sh`. Local memory target
checks read/write, stalls, response errors, address timeout, wrong RID and missing
RLAST. There is no real Caliptra hookup, UVM adapter, burst handling or coverage.
Reset during a transfer, concurrent task calls and four-state controls need
explicit qualification; initial pin values alone are not reset behavior.

## Current status — 2026-10-09

The open stack now includes AXI and AHB-Lite managers, subordinates, monitors,
checkers, active/passive UVM agents, Caliptra DMA SRAM/FIFO integration, and
focused mailbox and PV client BFMs. Selected generated UVMF environments and
actual Caliptra unit/top probes also run; the full generated UVMF integration
and stock-firmware suite are not qualified. See the
[`Caliptra BFM source summary`](dv/caliptra_bfm/README.md) for implemented
components and their test evidence.

Remaining release work includes the full width/ID/configuration matrix,
independent cross-simulator and four-state qualification, remaining generated
UVMF integration gates, and complete firmware coverage. The phase list below
defines those gates; it is not a claim that the initial baseline is still the
current implementation.

## Stages and interfaces

1. **Next useful slice:** define/reset abort semantics for every channel and
   reject unknown decisive VALID/READY/response controls. Add an independent
   passive monitor and negative reset/X/Z tests before bursts. Inputs: clock,
   reset, configured widths/timeouts, transaction requests and response pins.
   Outputs: response/status, transaction log and protocol violations; a failed
   monitor must prevent PASS. Check width/alignment/strobe/ID boundaries.
2. **Pinned pilot:** read-only adapter for Caliptra `caliptra_top.sv`
   `s_axi_w_if`/`s_axi_r_if` using the pinned `axi_if.sv`, with reviewed legal
   register read/write sequences. Keep the harness in QD-BFM. Compile against the
   real interface first, then run a named reset/register smoke on unmodified RTL
   if firmware and simulator dependencies permit. This does not replace licensed
   Avery/QVIP API compatibility. Preserve unavailable-checker status explicitly.
3. **AXI4 verification IP:** after the bounded FIXED mailbox slice, add
   full-width INCR, then WRAP and narrow/unaligned transfers with protocol-specific constraints. Add IDs,
   multiple outstanding requests, per-ID ordering, independent AW/W scheduling,
   request/response backpressure and mid-burst reset. Provide monitors, assertions,
   byte-enable scoreboards, reproducible seeds and functional coverage. Use
   plain SV transaction tasks first and a thin UVM sequence/driver/monitor adapter
   over the same checked core, with no proprietary class-name stubs.
4. **Production qualification:** exact AXI4 feature/width/ID/outstanding matrix,
   named Caliptra register configuration and simulator/UVM releases. Independent
   VIP or separately developed monitor must check both manager and target. Add
   AHB-Lite only for the concrete Caliptra QVIP-backed unit interface; add TL-UL
   only for a named OpenTitan DV adapter need. OpenTitan already has a TL agent:
   reuse it before creating another protocol implementation.

## Evidence and release criteria

- Corpus: retain existing runs; add AW-before-W/W-before-AW, long backpressure,
  reset at every transaction phase, timeout edges, zero/partial strobes, response
  errors, wrong IDs, X/Z controls/data policy, burst/4-KiB/length boundaries,
  out-of-order responses and deterministic randomized sequences.
- Oracles: ARM AMBA AXI specification edition pinned with clause references;
  independent byte-addressable scoreboard, separate monitor/VIP and cross-
  simulator traces. The BFM's own assertions cannot be its only oracle.
- Version matrix: current local Icarus 14.0 devel `b5fdf0647-dirty` is smoke
  evidence only; pin clean Icarus and Verilator builds for plain SV (two-state
  runs cannot establish X/Z behavior). Qualify a named four-state simulator and
  UVM 1.2 first; IEEE 1800.2 compatibility requires a separate lane. Record all
  protocol parameters and compiled assertion options.
- Targets: directed suite <30 s; 10k transfers with deterministic stalls <60 s
  and 1 GiB, excluding compilation; nightly seed matrix <30 min on reference host.
- Release: all mandatory protocol coverage bins hit or independently reviewed as
  excluded; each seeded violation rejected; zero scoreboard mismatch; reset and
  timeout recovery evidence; named pilot repeats. Publish coverage denominators,
  simulator limitations and unsupported features. Never label a single-beat
  memory smoke as full Caliptra DV or full AXI qualification.

## Qualification contract

This is a staged plan, not a production qualification claim. No stage is earned
by a green unit suite alone. Keep existing passing behavior and raw diagnostics.
Do not change application RTL/DV, disable assertions, or introduce dummy VIP to
make a pilot pass. A failed pilot is an artifact to retain, not a test to remove.

Named pilot pins (full SHAs, never floating branches):
- Caliptra RTL v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, generic simulation primitives;
  Adams Bridge v2.0.3: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` when needed.
- OpenTitan: `7a3ad34b6d483f4d1d69ac670ddb1c45f1172e19`; select the named IP fileset, generic technology,
  and record all FuseSoC flags, parameters, generated files, and their digests.
  The later configuration-blocker evidence at `a78922f14a8cc20c7ee569f322a04626f2ac6127`
  is a separate revision, not interchangeable qualification evidence.

Every release candidate needs an immutable evidence bundle: tool Git SHA and
binary hashes; OS/architecture, Python/compiler/simulator/solver versions;
design and submodule SHAs; top, parameters, defines, ordered files/includes,
constraints, libraries, seeds; input/output hashes; exact argv, raw stdout/stderr,
exit codes, wall time and peak RSS. Repeat twice in clean independent workspaces;
compare canonical findings and explain any nondeterminism. Archive the bundle
with the release and publish a supported/unsupported configuration table.

Review every expected finding and every oracle disagreement. Seed known defects
in separate test fixtures and require their detection; never mutate pilot RTL.
Unknowns and exclusions remain counted and visible. Waivers require a stable
finding/configuration identity, owner, independent reviewer, rationale, evidence
hash/link, expiry, and revalidation on any relevant input change. A waiver is a
review disposition, not a proof. No unreviewed waiver or unexplained oracle
mismatch is allowed in the qualified scope. Outside that scope report UNKNOWN
or a clear unsupported error. A version or dependency change reopens qualification.

Performance numbers below are acceptance targets, not measurements. Measure on
a named Linux x86-64 runner with 8 cores and 16 GiB RAM; record hardware and
median of five runs. No automatic threshold relaxation. macOS arm64 is a second
portability lane, not a substitute for the qualification runner.

## Portfolio priority and real-flow blockers

1. **QD-Lint first:** source/configuration fidelity is prerequisite evidence for
   every downstream analysis. OpenTitan pinmux's conditional `fileset_ip` versus
   `fileset_top` selects different register packages. A local pinned matrix probe
   at `a78922f...` reproduced an omitted-package failure from wrong setup flags;
   it was not an RTL defect. Caliptra's generic/technology primitive roots also
   select different sources. Audit these choices before caching or baselining.
2. **QD-BFM second:** Caliptra's README requires licensed Avery AXI and QVIP AHB
   dependencies in full UVMF flows. A bounded independent AXI adapter is useful,
   but cannot cure simulator/UVM/firmware dependencies or replace their APIs.
3. **QD-CDC, then QD-DFD:** real reset/synchronizer and lifecycle/debug cones are
   available; getting complete elaboration and constraints is the next blocker.
   VCD observations and cell annotations cannot establish safety on their own.
4. **QD-UPF and QD-DFT:** do standards/library/topology inventory now; owner-approved
   power intent and scan-mapped collateral are unverified. Do not invent these
   inputs or mistake lack of collateral for a demonstrated design failure.

Primary source anchors (review pinned source, not just current web documentation):
- [Caliptra dependency and configuration README](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/README.md).
- [OpenTitan pinmux fileset selection](https://github.com/lowRISC/opentitan/blob/a78922f14a8cc20c7ee569f322a04626f2ac6127/hw/ip/pinmux/pinmux_reg.core).
- [OpenTitan lifecycle architecture](https://github.com/lowRISC/opentitan/tree/7a3ad34b6d483f4d1d69ac670ddb1c45f1172e19/hw/ip/lc_ctrl/doc).
- [OpenTitan TL DV agent](https://github.com/lowRISC/opentitan/tree/7a3ad34b6d483f4d1d69ac670ddb1c45f1172e19/hw/dv/sv/tl_agent).

## Delivered response-backpressure increment

The single-beat manager and Caliptra adapter now support fixed response READY
delay, reset cancellation and stalled response stability checks. See
[the reproducible evidence](RESPONSE_BACKPRESSURE_EVIDENCE.md). Actual axi_sub
has been exercised with response stalls; the assertion-enabled configuration
remains UNKNOWN. This does not complete the burst/ordering/VIP/UVM stages above.

## Delivered FIXED mailbox increment

The directed manager has one-outstanding, full-width FIXED write/read tasks
with request USER metadata and per-beat response checks. Strict mode accepts
1–16 beats. An explicit compatibility flag permits the released Caliptra L0
256-beat FIXED firmware request while marking it nonconforming; the Arm AXI4
FIXED limit is 16 beats. This is not a full L0 replacement: response USER,
the internal/outbound DMA interfaces, broader AXI traffic and production
qualification remain outside the slice.

## Delivered AXI WRAP and narrow manager coverage — 2026-10-09

The manager regression now round-trips legal WRAP bursts of 2, 4, 8, and 16
beats, and an aligned two-byte INCR write/read that preserves adjacent byte
lanes. It rejects a three-beat WRAP and a misaligned narrow request before
asserting VALID. The complete manager/outstanding regression passes on clean
published Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; see the
[evidence bundle](evidence/caliptra-bfm-axi-wrap-narrow-20261009/README.md).
Unaligned transfers, the broader width/ID matrix, four-state cross-simulator
qualification, and full Caliptra/UVMF qualification remain open.

## Delivered unaligned AXI transfers — 2026-10-09

The manager, protocol checker, and SRAM subordinate now support unaligned
INCR and FIXED starts. INCR advances to the next AxSIZE-aligned address after
its partial first transfer; FIXED retains the same unaligned address and byte
lanes for each beat. WRAP starts remain AxSIZE-aligned. Directed coverage
checks byte-lane preservation, both burst types, and a one-byte transfer at the
end of the mapped memory. Address and lane progression follows Arm
[IHI0022H A3.4](https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/IHI0022H_amba_axi_protocol_spec.pdf).
The full manager and subordinate evidence is in the
[unaligned-transfer bundle](evidence/caliptra-bfm-axi-unaligned-20261009/README.md).
This does not complete the broader width/ID, independent cross-simulator,
four-state, or full Caliptra/UVMF qualification gates.

## Delivered representative AXI width/ID matrix — 2026-10-09

The parameter regression passes a 3×3 matrix of 32/64/128-bit data widths and
1/4/8-bit IDs with 48-bit addresses. Every configuration checks unaligned INCR
and four-beat WRAP read/write traffic through the manager, checker, and SRAM
subordinate. The Slurm run used clean published Icarus
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; details are in the
[parameter-matrix evidence bundle](evidence/caliptra-bfm-axi-parameter-matrix-20261009/README.md).
The full supported-width/ID/outstanding matrix and independent
cross-simulator/four-state qualification remain open.

## Delivered AXI read outstanding-depth matrix — 2026-10-09

The queued-read manager test now runs at outstanding depths 1, 2, and 4,
including capacity checks and out-of-order response routing. See the
[outstanding-depth evidence bundle](evidence/caliptra-bfm-axi-outstanding-depth-20261009/README.md).
Concurrent write coverage at each depth and the width/ID/outstanding
cross-product remain open.

## Delivered AXI monitor width/ID matrix — 2026-10-09

The same nine configurations now instantiate the passive channel monitor and
assert accepted beat, INCR/WRAP, partial-strobe, and last-beat counts. The
clean published Icarus run is recorded in the
[monitor-matrix evidence bundle](evidence/caliptra-bfm-axi-monitor-matrix-20261009/README.md).
The full supported-width/ID/outstanding matrix and independent
cross-simulator/four-state qualification remain open.

## Current AXI outstanding parameter status — 2026-10-09

The read side now passes the representative 3×3×3 matrix of data width,
ID width, and outstanding depth. The current run and provenance are in the
[outstanding-parameter evidence bundle](evidence/caliptra-bfm-axi-outstanding-parameter-matrix-20261009/README.md).
Concurrent writes across those parameters and full Caliptra/UVMF qualification
remain open.

## Current AXI write outstanding status — 2026-10-09

The write manager now also passes depths 1, 2, and 4 at the 32-bit data / 8-bit
ID profile, including W-channel stalls and response routing. See the
[write-depth evidence bundle](evidence/caliptra-bfm-axi-write-outstanding-depth-20261009/README.md).
The concurrent write width/ID cross-product and full Caliptra/UVMF qualification
remain open.

## Current AXI outstanding read/write parameter status — 2026-10-09

Both read and write paths now pass the representative 3×3×3 matrix of data
width, ID width, and outstanding depth. Separate run records are in the
[read evidence bundle](evidence/caliptra-bfm-axi-outstanding-parameter-matrix-20261009/README.md)
and [write evidence bundle](evidence/caliptra-bfm-axi-write-outstanding-parameter-matrix-20261009/README.md).
Full Caliptra/UVMF qualification and other supported-profile combinations
remain open.

## Current AXI checker X/Z control status — 2026-10-09

The guarded Icarus checker regression now injects X and Z independently on
every VALID/READY control across all five channels, and rejects all 20 cases.
The full run passed on clean published Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; see the
[checker X/Z evidence bundle](evidence/caliptra-bfm-axi-checker-xz-controls-20261009/README.md).
Cross-simulator parity remains open.

## Current AXI transaction-monitor parameter status — 2026-10-09

The transaction monitor now passes the representative 3×3 width/ID matrix,
checking completed reads and writes plus the captured four-beat WRAP records.
The run used clean published Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; results are in the
[transaction-monitor evidence bundle](evidence/caliptra-bfm-axi-transaction-monitor-parameter-matrix-20261009/README.md).
Error, malformed-transaction, and capacity cases are not crossed through this
matrix. Full Caliptra/UVMF qualification remains open.

## Current Caliptra AXI complex maximum-burst status — 2026-10-09

The guarded AXI complex regression passes the full 256-beat INCR write/read
case on clean QD-BFM `c8ce915` and current published Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. The run details and resource
measurement are in the
[maximum-burst evidence bundle](evidence/caliptra-bfm-axi-complex-256b-20261009/README.md).
This does not qualify Caliptra firmware or UVM integration.

## Current Verilator parity status — 2026-10-09

Full-complex and standalone-checker Slurm pilots were stopped by the memory
guard during compilation before simulation. Their requested memory, observed
guard thresholds, and raw logs are recorded in the
[Verilator pilot evidence bundle](evidence/caliptra-bfm-verilator-pilot-20261009/README.md).
Verilator runtime parity remains open; these pilots are not compile or
behavioral passes.

## Current AXI request-stall reset status — 2026-10-09

The guarded Icarus manager regression now aborts requests during stalled AR,
stalled AW, and stalled W-after-AW phases, in addition to the existing read
data and write response waits. Each task exits unsuccessful, clears its
outputs, and recovers after reset. See the
[reset-stall evidence bundle](evidence/caliptra-bfm-axi-master-reset-stalls-20261009/README.md).
The standalone AXI manager now asserts reset just after AR, R, AW, W, and B
handshakes, checks abort cleanup, and recovers with a locked read/write pair.
The integrated AXI memory subordinate regression now also resets after each
of those five handshakes, checks that pending responses are cleared, and
verifies post-reset read/write recovery. See the
[manager handshake-reset evidence](evidence/caliptra-bfm-axi-master-reset-handshakes-20261009/README.md)
and [subordinate handshake-reset evidence](evidence/caliptra-bfm-axi-subordinate-reset-handshakes-20261009/README.md).
The integrated DMA-map FIFO route now also tests reset after each of those
five handshakes while the generated recovery-block sequence is active. It
checks FIFO and route cleanup, generated-block re-arming, and post-reset FIFO
read/write recovery; see the
[DMA-map reset evidence](evidence/caliptra-bfm-dma-map-reset-handshakes-20261010/README.md).
Caliptra's generated DMA master and full-top/UVM reset-edge coverage remain
open.

## Current full-top AES cases 8–12 trace status — 2026-10-10

Published-Icarus full-top AES cases 8 through 12 pass with the native AXI
checker and VPI trace enabled. The trace plugin had passed a pointer to a
stack-local callback value that it did not use; the active tracer now leaves
that optional callback value unset, and the runner builds it from
`dv/caliptra_bfm/uvm/tests/sim-axi-trace-vpi.c`. See the
[trace-fix evidence](evidence/caliptra-bfm-fulltop-aes-trace-fix-20261010/README.md).
This is one narrowed firmware diagnostic using fast TRNG and fast data/BSS
preload, not stock-firmware or UVMF qualification; the full firmware suite
remains open.

## AXI memory target 16-beat FIXED and WRAP round trips — 2026-10-10

The memory-subordinate regression writes 16 distinct full-width beats to one
FIXED address, checks the final stored word, then reads the 16-beat FIXED burst
and checks every returned word, response, and USER field. It also writes a
16-beat WRAP burst from the last word in its 64-byte window, checks each
wrapped memory location, and verifies the complete readback. Slurm job 168
passed the FIXED case; job 171 passed the expanded subordinate, reset, and
queue suite on clean published Icarus
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. Job 171 used one CPU, requested
256 MiB, measured 17,840 KiB maximum RSS, and exited 0. See the [FIXED evidence](evidence/caliptra-bfm-axi-fixed16-20261010/README.md)
and [WRAP evidence](evidence/caliptra-bfm-axi-wrap16-20261010/README.md).
This is module-level memory-target coverage; full-top random-DMA remains
separate.

## AXI target burst monitor accounting — 2026-10-10

The 16-beat FIXED and WRAP cases now execute before the memory monitor
snapshot. Assertions check totals of 18 AW/B transactions, 15 AR/R
transactions, and 315 W beats, including burst-type, response, strobe, and
LAST bins. Slurm job 172 passed the full subordinate, reset, and queue
regression on clean published Icarus
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; the run used one CPU, requested
256 MiB, measured 17,456 KiB maximum RSS, and exited 0. See the
[monitor-coverage evidence](evidence/caliptra-bfm-axi-burst-monitor-coverage-20261010/README.md).
This remains module-level target evidence, not full-top DMA qualification.

## Current full-top random-DMA status — 2026-10-10

Slurm job 164 passed one `rand_test_dma` iteration through the actual pinned
Caliptra top with the native AXI BFM checker enabled. Firmware, elaboration,
and simulation exited 0; one testcase pass marker and normal `$finish` were
recorded at `minstret=7898`, `mcycle=27467`, with zero bad diagnostics and no
JTAG errors. The run used clean published Icarus
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, pinned Caliptra RTL, fast TRNG,
and diagnostic fast boot-data preload. The single iteration ran for 59:25.73
with 1 CPU and a 4 GiB Slurm request; measured MaxRSS was 1,860,208 KiB and
the process-group peak was 1.80 GiB. See the
[full-top random-DMA evidence](evidence/caliptra-bfm-fulltop-rand-dma-one-20261010/README.md).
This is one diagnostic iteration without AXI trace, not stock-firmware or
full-suite qualification.

## Current actual-DUT mixed DMA replay status — 2026-10-10

The existing actual-DUT UVM runner passed all 25 seeded default mixed-DCCM
records through Caliptra's `axi_dma_top` on clean, published Icarus
`4b3f3424c440aca6af92153b6860a7253b925234`. The runner verifies all five DMA
routes and the required FIFO, FIXED, delay-injection, and recovery-block
profiles; every report summary has zero UVM errors and fatals. The local
memory-guarded process-group peak was 0.38 GiB. This is DMA-block evidence; the
full-top firmware suite and four-state/cross-simulator qualification remain
open. Details and logs are in the
[mixed-DMA replay evidence bundle](evidence/caliptra-bfm-axi-dma-mixed-replay-20261010/README.md).

## AXI memory-subordinate simulator portability — 2026-10-10

The memory-target regression passes under Verilator 5.032 after removing a
nested memory-read helper from the RDATA assignment and making the exclusive
success slot a single per-handshake assignment. Slurm job 181 also passed the
main target, reset-handshake, and bounded multi-ID queue tests under clean
published Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. It requested 1 CPU
and 1 GiB, measured 339,288 KiB MaxRSS and a 0.39 GiB process-group peak, and
exited 0 in 13.09 seconds. This remains standalone module-level evidence, not
full-top or UVMF qualification. See the
[portability evidence](evidence/caliptra-bfm-axi-verilator-readback-20261010/README.md).

## Current-source full-top random-DMA rerun — 2026-10-10

Slurm job 184 passed one `rand_test_dma` iteration from current QD commit
`5945efeae78580cc8a5bd7a4050ee4dfec39d7be` through the pinned Caliptra top
with the native BFM checker enabled. It recorded one testcase pass, zero
failures or bad diagnostics, zero JTAG errors, and normal finish at
`minstret=7898`, `mcycle=27467`. Clean published Icarus main
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` was used. Runtime and source
provenance are in the
[current-source full-top evidence](evidence/caliptra-bfm-fulltop-rand-dma-current-20261010/README.md).
This remains a single diagnostic iteration with fast TRNG and diagnostic fast
boot-data preload, not stock-firmware, full-suite, UVMF, or qualification
coverage.

## AXI memory-subordinate Verilator parity — 2026-10-10

Slurm job 189 passed the main target, reset-handshake, and bounded multi-ID
queue tests under Verilator 5.032 at QD commit
`bdc69ea2f7ae0de3f15f038928abff0bedecf77c`. The job requested 1 CPU and 1 GiB,
measured 339,016 KiB maximum RSS and a 0.39 GiB process-group peak, and exited
0 in 17.65 seconds. Verilator emitted non-fatal width and incomplete-case
warnings and does not establish four-state behavior. See the
[Verilator parity evidence](evidence/caliptra-bfm-axi-verilator-parity-20261010/README.md).

## AXI master Icarus/Verilator parameter matrix — 2026-10-10

The 32/64/128-bit data by 1/4/8-bit ID matrix passes under both clean,
published Icarus main `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` and Verilator
5.032. Slurm job 196 also passed the Verilator memory-target, handshake-reset,
and bounded multi-ID queue regressions. A Verilator-only 32-bit/1-bit-ID
failure exposed dependence on a separately latched success vector; write task
success is now derived from its latched response, and the returned response ID
comes from the matched slot. The run requested 1 CPU and 1 GiB, measured
354,072 KiB MaxRSS and a 0.40 GiB process-group peak, and exited 0. Verilator
warnings were non-fatal and its evidence is two-state only. See the
[cross-simulator matrix evidence](evidence/caliptra-bfm-axi-crosssim-parameter-matrix-20261010/README.md).

## AXI master full regression after response fix — 2026-10-10

Slurm job 198 passed the guarded `run_master.sh` suite on QD commit
`75ceb4b2f66b7140aabd3cab6d02df05e99be69e` with clean published Icarus main
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. All ten directed scenarios passed,
including reset recovery, bad-response poisoning, W-before-AW ordering,
overlapping read/write tasks, and queued/outstanding writes. The job requested
1 CPU and 256 MiB and measured 17,680 KiB MaxRSS. See the
[post-fix master evidence](evidence/caliptra-bfm-axi-master-post-fix-20261010/README.md).

## AXI master unknown-control fail-stop — 2026-10-10

The AXI master now poisons itself on X/Z AWREADY, WREADY, or ARREADY while
requesting, X/Z BVALID/RVALID while response-ready, and unknown BRESP/RRESP on
an accepted response. Seven standalone probes confirm prompt failure and
channel/state cleanup with the protocol checker disabled. Slurm job 201 passed
those cases and the existing full master suite, plus 18 Icarus/Verilator
parameter runs and three Verilator target regressions. It measured 353,816 KiB
MaxRSS for the matrix phase and a 0.39 GiB process-group peak. This is selected
Icarus four-state coverage and Verilator two-state parity, not exhaustive
four-state or full-top/UVMF qualification. See the
[manager X/Z evidence](evidence/caliptra-bfm-axi-master-xz-controls-20261010/README.md).

## Caliptra `axi_if` complex-BFM integration after manager X/Z fix — 2026-10-10

Slurm job 203 passed the guarded complex-BFM smoke using Caliptra's actual
`axi_if` and top-testbench package types on QD commit
`b965acf0437236971a482a46e3d0499ce7988e16`, clean published Icarus main
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, and clean Caliptra RTL
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. It covered Caliptra AXI delay
weights, error ranges, SRAM/FIFO traffic, FIFO controls, recovery availability,
randomized stalls, segmented readback, and 256-beat bursts. The job requested
1 CPU and 256 MiB, measured 17,684 KiB MaxRSS and a 0.02 GiB guarded process
peak, and exited 0. This is component integration evidence, not full-top
firmware, UVMF, or qualification coverage. See the
[Caliptra `axi_if` integration evidence](evidence/caliptra-bfm-axi-caliptra-if-post-xz-20261010/README.md).

## Generated ECC UVMF check on current clean published Icarus — 2026-10-10

Slurm job 206 reran the generated ECC reset/IRQ path on clean published
Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. It still stops during
compile at the package-qualified parameterized proxy class declarations in
Caliptra's generated BFM interfaces; no UVM simulation starts. This confirms
the current generated ECC integration blocker without introducing a QD-side
syntax adaptation. Peak RSS was 75,944 KiB. See the
[current ECC compile evidence](evidence/caliptra-bfm-generated-ecc-c339-pilot-20261010/README.md).

## AHB unknown-input matrix and standalone regression — 2026-10-10

The 26-case checker matrix and full standalone AHB regression pass under
IEEE 2012, 2017, and 2023 on clean published Icarus
`4b3f3424c440aca6af92153b6860a7253b925234`. The new negative cases inject X
and Z on HREADY, HRESP, HSEL, HTRANS, HWRITE, HSIZE, HADDR, and write-phase
HWDATA. The reset-abort test waits for reset-gated HSEL to settle before
sampling it. This local result is not the pending current-`c339b9f2` Slurm
run; see the [published-main AHB evidence](evidence/caliptra-bfm-ahb-xz-published-20261010/README.md).

## UVMF-lite base layer on clean published Icarus — 2026-10-10

The UVMF-lite scoreboard, active/passive agent, transaction-recording, and
default reset-generator runners pass on clean published Icarus
`4b3f3424c440aca6af92153b6860a7253b925234` with bundled Accellera UVM
2020.3.1. Both IEEE 2017 and 2023 agent/scoreboard paths pass with their
intentional mismatch controls; reset generation passes in IEEE 2012. This is
base-layer evidence only; generated ECC interface compilation remains blocked
on current `c339b9f2`. See the
[published UVMF-lite evidence](evidence/caliptra-bfm-uvmf-lite-published-20261010/README.md).

## Native AXI UVM RAL monitor prediction — 2026-10-10

The native AXI agent now feeds its completed transaction monitor stream to the
stock UVM register predictor with frontdoor auto-prediction disabled. Its
adapter preserves the existing driver-item path and decodes single-beat,
32-bit monitor records for the mapped CSR. The guarded agent smoke verifies
successful write/read mirror updates and that injected SLVERR leaves the
mirror unchanged; it passes with zero UVM errors or fatals on published Icarus
`127b887dfdc09283ab0187a2e618421dee3d5dcc`. The four expected predictor skips
come from the two predictors observing failed reads. This is synthetic agent
evidence, not full Caliptra/UVMF qualification; see the
[dated evidence](evidence/caliptra-bfm-axi-native-ral-predictor-published-20261010/README.md).

## AXI data-width matrix extension — 2026-10-10

The guarded manager/checker/SRAM/monitor matrix now passes 18 cases across
32/64/128/256/512/1024-bit data and 1/4/8-bit IDs. The SRAM subordinate
explicitly caps ID width at 8 bits. This extends only the data-width sample;
outstanding-depth cross-products, independent simulator parity, and full
Caliptra/UVMF qualification remain open. See the
[dated matrix follow-up](evidence/caliptra-bfm-axi-parameter-matrix-20261009/README.md).

## AXI outstanding width/ID/depth cross-product — 2026-10-10

The queued read and concurrent write matrices each pass 54 configurations:
32/64/128/256/512/1024-bit data, 1/4/8-bit IDs, and outstanding depths 1/2/4.
Both matrices pass on clean published Icarus
`127b887dfdc09283ab0187a2e618421dee3d5dcc` and the newer locally available
published `origin/main` revision `4b3f3424c440aca6af92153b6860a7253b925234`.
See the [read](evidence/caliptra-bfm-axi-outstanding-parameter-matrix-20261009/README.md)
and [write](evidence/caliptra-bfm-axi-write-outstanding-parameter-matrix-20261009/README.md)
evidence follow-ups. Cross-simulator/four-state qualification and complete
Caliptra/UVMF integration remain open.

## AXI response-ready handshake fix and cross-simulator width matrix — 2026-10-10

Verilator exposed a final-beat race: the manager deasserted READY in the same
active edge that marked a response slot complete, allowing the subordinate to
miss the handshake. The manager now leaves `RREADY`/`BREADY` asserted until its
task releases the completed slot on the following negedge. The 18-case
width/ID manager-checker-subordinate-monitor matrix passes under clean published
Icarus `4b3f3424c440aca6af92153b6860a7253b925234` and Verilator 5.050. Verilator
warnings remain non-fatal and it does not establish four-state behavior. See
the [cross-simulator evidence](evidence/caliptra-bfm-axi-crosssim-width-matrix-20261010/README.md)
and the dated [read](evidence/caliptra-bfm-axi-outstanding-parameter-matrix-20261009/README.md)
and [write](evidence/caliptra-bfm-axi-write-outstanding-parameter-matrix-20261009/README.md)
post-fix reruns.

## Caliptra full-top in-flight reset smoke — 2026-10-10

A no-reset control and a forced warm reset during the first full-top AXI write
now pass on clean published Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
The reset asserted at cycle 3080 with one AXI write outstanding; simulation
finished with the testcase pass marker. This remains diagnostic because it uses
fast-TRNG and fast-boot overlays. The later write-response window and full
firmware/qualification gates remain open; see the
[reset-window evidence](evidence/caliptra-bfm-fulltop-rand-dma-reset-c339-20261010/README.md).

## 2026-10-10 Slurm interruption

The WSL-hosted Slurm machine was stopped during late-window follow-up. QD job
`238_1` (delay 2822; 1 CPU, 3 GB) was last observed `RUNNING` at 00:43, before
the watcher lost SSH; no terminal result was collected. Treat as lost
infrastructure, not a test failure, and rerun when the server is restored.
Job 229 was separately last noted running under the Icarus agent; its purpose
and final progress were not captured, so it is excluded from QD conclusions.

## 2026-10-10 Slurm restart reconciliation

Job `238_1` was requeued into its existing output directory and its retry
exited 1 before simulation because that directory already existed. The prior
simulator log shows the intended reset at cycle 5335 with AW6 outstanding and
trace output through cycle 18994, but has no structured result or completion
record; classify the late-window outcome as incomplete, not a BFM failure.
The queue had no matching live job. Fresh job `240_1` is running from a new
output root with 1 CPU and 3 GB requested, based on prior MaxRSS near 1.77 GiB
plus about 1.23 GiB headroom. See the [reset-window evidence](evidence/caliptra-bfm-fulltop-rand-dma-reset-c339-20261010/README.md).
