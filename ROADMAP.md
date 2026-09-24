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

## Current capability

Baseline `d761ee8cc6594656e95582a28f471c473ebd1afc`: standalone single-beat
AXI4 manager tasks; CI installs Icarus and runs `./run.sh`. Local memory target
checks read/write, stalls, response errors, address timeout, wrong RID and missing
RLAST. There is no real Caliptra hookup, UVM adapter, burst handling or coverage.
Reset during a transfer, concurrent task calls and four-state controls need
explicit qualification; initial pin values alone are not reset behavior.

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
