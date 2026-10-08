> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated SoC-IFC runtime probe

This lane runs the generated SoC-IFC reset/power-on sequence, generated status
responders, the real `soc_ifc_top`, and an AAXI write/read to `0x30048` using
the open Caliptra AXI BFM.

## Result

The captured guarded run completed with **0 UVM errors and 0 fatals**. The
write and read scoreboards match, and the CPTRA status scoreboard matches
through reset. The key trace confirms the randomized 256-bit key reaches the
DUT register. Full log:
`generated-env-runtime-cptra-key-pass-20261005.log` (raw artifact omitted from this checkpoint).

This run also exercises the generated AAXI VIF handoff: generated `hdl_top`
publishes `intf_uc`, generated `soc_ifc_environment` retrieves its `ports`
VIF and registers it on `aaxi_tb.env0.master[0].driver`, and the generated
bench sequence performs the host write/read. The final SoC-IFC scoreboard
reports five matches, zero mismatches, and no UVM errors or fatals. This
qualifies the clean-room binding under this Icarus setup, not Avery's exact
driver lifecycle or event timing.

## Caliptra top environment reset

The opt-in `--caliptra-top-env-probe` compiles Caliptra's generated
`caliptra_top_env_pkg` around the generated SoC-IFC environment, verifies its
`caliptra_top_environment.detect_reset()` path, and drives an initial power-on
release followed by a hard reset through the generated control sequencer. The
child reset handler and control-analysis predictor connection remain active.
The guarded run reports three SoC-IFC status matches, zero mismatches,
no-comparison or missed transactions, zero UVM errors/fatals, and 58% minimum
free memory against a 40% floor.

This checks the generated environment wrapper and the reset/predictor path for
the real `soc_ifc_top`; it does not compile the full Caliptra core/top. Because
the harness has no Caliptra-core status outputs, its disposable environment
copy retains CPTRA expected-reset events for reset synchronization, but omits
CPTRA status queue matching and the unavailable CPTRA actual-status path. The
probe also adds the falling edge needed to initialize the generated control
BFM, detects reset assertion asynchronously for Icarus, and defers SoC-IFC
status analysis by one delta cycle. Full Caliptra-core status/reset behavior
remains unqualified.

Replay:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=/path/to/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --caliptra-root /path/to/caliptra-rtl --caliptra-top-env-probe
```

The latest guarded run also starts Caliptra's stock
`soc_ifc_env_axi_user_init_sequence` through the generated virtual sequencer
and AXI RAL map. It checks the 12 completed AAXI writes against each mapped
register address, expected data, full-word strobe, and the reset-derived
AWUSER observed by the completed-transaction monitor. The SoC-IFC scoreboard
reports 18 matches and zero mismatches; UVM errors and fatals are both zero.
Full log: `generated-env-runtime-axi-user-init-pass-20261005.log` (raw artifact omitted from this checkpoint).
This qualifies the exercised stock RAL sequence and USER extension path, not
all generated SoC-IFC sequences.

The opt-in `--generated-axi-user-reject-probe` requires both the stock AXI USER
initialization and the generated AHB mailbox payload. It reads `MBOX_LOCK`
with an unlisted AXI USER, requires the actual AXI response to be SLVERR, then
lets the following AHB mailbox claim read verify that the rejected request did
not claim the mailbox.

The combined guarded run passed this probe with `ARUSER=0xbad0bad0`; the
subsequent AHB mailbox claim still read the initial unlocked value. The full
AXI USER plus four-word AHB/AAXI mailbox handshake reported 39/39 scoreboard
matches, zero mismatches/no-comparison/missed transactions, and zero UVM
errors/fatals. The run emitted three existing warnings: one QVIP coverage shim
notice and two whole-register RAL field-access fallbacks. Minimum free memory
was 74% against the 60% floor. The raw log was kept outside this checkpoint.

Replay from the BFM worktree:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=/path/to/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --generated-environment-runtime --trace-predictor-reset \
  --generated-axi-user-init --generated-ahb-mbox-payload \
  --generated-axi-user-reject-probe
```

### Replay status on 2026-10-07

The documented combined replay compiled with Icarus 13.0 dev
(`246c58e4-dirty`) but did not reproduce the captured pass: simulation stayed
at time zero for the 180-second guard and produced no heartbeat. The guard
terminated it with status 124. Minimum free memory was 59% against a 40%
floor. Temporary sequence tracing localized the stall to the generated
`reg_model.reset()` call; bypassing that call for diagnosis reached the first
clock edge, then stalled in predictor reset. Diagnostic edits and generated
run files were removed. The 2026-10-05 passing log remains historical evidence
and is not reproduced on this installed toolchain. Two other host toolchains
could not reach simulation: Homebrew Icarus 13.0 and the local Icarus 14.0-dev
build both fail while parsing unchanged Caliptra AXI/primitive sources
(`axi_sub_rd.sv`, `axi_sub_wr.sv`, and `caliptra_prim_alert_pkg.sv`); 14.0-dev
also reports unsupported default lifetime overrides in `axi_if.sv`. Those
compile failures are separate from the time-zero stall.

### Replay status on 2026-10-08 (diagnostic)

Replayed the combined command above with `--trace-predictor-reset`,
`--generated-axi-user-init`, `--generated-ahb-mbox-payload`, and
`--generated-axi-user-reject-probe`. The paired Icarus/VVP 13.0-dev build
identifies as `ac4532fa-dirty`; the pinned Caliptra checkout was clean at
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The run completed: the invalid
AXI USER read returned SLVERR, and the scoreboard reported 38/38 matches,
zero mismatches/no-comparison/missed transactions, zero UVM errors/fatals,
and three warnings (one QVIP coverage notice and two whole-register RAL field
fallbacks). A focused trace found four direct RAL child blocks and the normal
base reset walk returned. The 2026-10-07 stall recorded on
`246c58e4-dirty` did not reproduce; this does not isolate which toolchain
change removed it. Diagnostic only: this run used a dirty, unpublished
simulator build and does not qualify the lane.

## Generated AHB RAL read

The optional `--generated-ahb-ral-read` lane starts after generated power-on
and performs a RAL frontdoor read of the mailbox lock through the generated
AHB map and active AHB manager. The real `soc_ifc_top` returns the initial
unlocked value, zero; this CSR sets its lock bit as a read side effect. The
probe runs after mailbox traffic, so that side effect does not change the
traffic being checked. The generated predictor and scoreboard consume the
completed transfer, with zero UVM errors and fatals. The combined run also checks the stock 12-write
AXI USER sequence and reports 18 AXI scoreboard matches. Full log:
`generated-env-runtime-ahb-ral-read-pass-20261005.log` (raw artifact omitted from this checkpoint).

The temporary runtime overlay maps generated AHB parameterized transfer types
to the clean-room BFM typedef, constructs the predictor output directly, copies
its protocol fields explicitly, and compares AHB protocol fields in the
generated scoreboard. These work around Icarus type-factory and queue-copy
limitations without changing the pinned Caliptra checkout. The previous
time-zero logs used a compiler/VVP pair from different builds and do not show
an AHB protocol failure. Other generated AHB sequences, coverage, and the
complete Caliptra top remain unqualified. The separate actual-RTL SoC-IFC
harness also runs active AHB sequences for mailbox lock, four-word
request/response, and DMA programming.

## Generated AHB mailbox claim and write/readback

The optional `--generated-ahb-ral-dlen-write-readback` lane uses the generated
AHB RAL map to read `MBOX_LOCK`, verify the initial value is zero, then write
`MBOX_DLEN=0x10` and read it back. The lock-register read claims the mailbox;
a negative run showed that writing the length before that read leaves the
register at zero (negative log (raw artifact omitted from this checkpoint)).
The runtime runner now requires a scoreboard summary with predicted count
equal to matches, at least one match, and zero mismatches, no-comparison items,
or missed items. The positive generated-runtime run reports 21 matches and
zero UVM errors/fatals:
`generated-env-runtime-ahb-mailbox-claim-dlen-scoreboard-pass-20261005.log` (raw artifact omitted from this checkpoint).
The 18 AXI transactions include the stock 12-write AXI USER RAL sequence; the
three AHB transactions are the mailbox claim read and MBOX_DLEN write/read.

## Generated AHB mailbox payload

The optional `--generated-ahb-mbox-payload` lane routes the mailbox claim,
command, length, four `MBOX_DATAIN` words, and execute through generated AHB
RAL. It attaches the open mailbox SRAM target and checks all four stored words.
The scoreboard reports 15/15 predicted transactions matched, with zero
mismatches, no-comparison items, missed items, UVM errors, or fatals. The
single-bit injection variant also passes and verifies the corrupted first
word. See the no-injection log (raw artifact omitted from this checkpoint)
and single-bit log (raw artifact omitted from this checkpoint).
Both guarded runs had 70% free memory at preflight and minimum against a 60% floor.
Each log retains six UVM warnings, including the mailbox SRAM sequencer's
`Dropping response for sequence 2` report, also present in the earlier AAXI
open-target run. The scoreboard reports no missed items. These retained logs
do not explicitly shut down the responders; the later roundtrip reruns below
check that lifecycle.

A lifecycle follow-up keeps the generated responder sequences alive through the
mailbox transfer by removing `disable fork` calls that cancelled sibling
`run_phase` work. The follow-up runtime log (raw artifact omitted from this checkpoint)
checks all four SRAM words and reports 16/16 scoreboard matches, no dropped
responses, and zero errors/fatals. These retained logs predate explicit
responder shutdown and include four `SEQPRTZMB` warnings at test teardown. The
full request/status reruns below now stop these sequences explicitly. The same
lifecycle change also passes the
single-bit ECC injection rerun (raw artifact omitted from this checkpoint)
with the injected first word, the other three words, and the same 16/16 clean
scoreboard result. The double-bit injection rerun (raw artifact omitted from this checkpoint)
checks the same words and reports 17/17 matches, with zero errors/fatals and no
dropped responses. The combined stock AXI USER plus double-bit AHB mailbox
run (raw artifact omitted from this checkpoint)
passes all 12 stock USER writes and the four-word AHB mailbox payload with
29/29 matches, zero mismatches/no-comparison/missed items, and zero UVM
errors/fatals. Its memory guard observed 70% free memory against the 60% floor.

### Generated AHB/AAXI mailbox response handshake

The generated AHB sequence sends command, length, and four input words, then
executes the request. After `mailbox_data_avail`, the generated-name AAXI
sequence reads command, length, and four DATAOUT words, writes
`MBOX_STATUS=CMD_COMPLETE`, and the AHB sequence reads status and clears
`MBOX_EXECUTE`. No-ECC and single-bit ECC runs each pass 26/26 predictor
scoreboard matches with zero mismatches, missed/no-comparison transactions,
UVM errors, or fatals. Minimum observed free memory was 71% against the 60%
floor. See the no-ECC log (raw artifact omitted from this checkpoint)
and single-bit log (raw artifact omitted from this checkpoint).

The double-bit ECC run completes the four DATAOUT reads, status write/read,
execute clear, and open-SRAM checks. The pinned predictor reports a double-bit
ECC interrupt on two corrupt reads while the interrupt is already high. Its
disposable runtime overlay emits the expected status transaction only on the
low-to-high transition; the run then reports 27/27 scoreboard matches, zero
mismatches or missed transactions, and zero UVM errors/fatals. The earlier
unmatched-expectation reproduction remains available as a
diagnostic log (raw artifact omitted from this checkpoint).
The passing run is here (raw artifact omitted from this checkpoint).

The same full request/status handshake also passes with the stock AXI USER RAL
initialization enabled. That sequence programs MBOX valid-user slot 0 to
`0xc0de0000`; the generated SoC AXI response sequence now uses that value on
`ARUSER` and `AWUSER` rather than issuing as an invalid receiver. No-ECC and
single-bit ECC each report 38/38 matches, and double-bit ECC reports 39/39;
all three have zero mismatches, missed/no-comparison transactions, UVM errors,
or fatals. The memory guard retained 83% free memory against its 60% floor.
The earlier probe version used `0xffffffff` for those post-init requests and
is kept as a failure diagnostic (raw artifact omitted from this checkpoint).
Passing logs with explicit responder shutdown: no ECC (raw artifact omitted from this checkpoint),
single-bit ECC (raw artifact omitted from this checkpoint),
and double-bit ECC (raw artifact omitted from this checkpoint).
Each reports three existing coverage/RAL warnings and no `SEQPRTZMB` warnings.
The no-init branch was rerun after parameterizing the response USER field; it
retains the reset-derived `0xffffffff` and reports 26/26 matches with zero
errors or fatals (log (raw artifact omitted from this checkpoint)).

The AAXI comparison shim ignores its legacy scalar `data` field on reads and
compares completed read payloads through `beatQ`. The scalar is still checked
for writes. This avoids treating a request-phase read field as completed
response data.

A later predictor-reset trace rerun reached its 300-second limit during
power-on, before the sequence and scoreboard completed. Its partial
`generated-env-runtime-vvp.log` and heartbeat do not change the completed
run's result and provide no AXI regression result.

The runner uses disposable Icarus compatibility copies to:

- Connect the generated default reset pulse to all seven BFM interfaces.
- Present `security_state` as an input net at the `soc_ifc_top` port. Icarus
  left the generated `input var security_state_t` connection unknown even
  when the control BFM drove `3'b111`; the net form propagates the same value.
- Set this probe's reset sequence to debug-locked production state, since its
  randomized packed state reached the BFM as unknown bits.
- Synchronize predictor and monitor startup around the reset scoreboard edge.
- Preserve the reset-event latch and boot-event release accommodations for
  Icarus.
- In the default lane, the generated mailbox SRAM responder remains the one
  supplied by the generated Caliptra testbench.

These changes are confined to the temporary generated-environment copies and
the probe. The pinned Caliptra checkout is not modified. This result qualifies
the generated SoC-IFC environment for the exercised reset/power-on path and
single AXI write/read; it does not qualify all generated sequences, coverage,
or the complete Caliptra top. The runner suppresses only the repeated volatile
register mirror warning. Other warnings remain visible.

## Replay

From the BFM worktree, pair the Icarus compiler with this worktree's freshly
built `vvp/vvp`; a VVP from a different/stale build can remain at simulation
time zero:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=vvp/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --generated-environment-runtime --trace-predictor-reset
```

Add `--generated-axi-user-init` to run the stock 12-write generated RAL
sequence and its pin-level checks:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=vvp/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --generated-environment-runtime --trace-predictor-reset --generated-axi-user-init \
  --generated-ahb-ral-read
```

This combined replay is retained as
`generated-env-runtime-ahb-ral-read-pass-20261005.log` (raw artifact omitted from this checkpoint).

To exercise the generated AHB mailbox claim and write/readback path with the
stock AXI USER sequence:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=vvp/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --generated-environment-runtime --trace-predictor-reset --generated-axi-user-init \
  --generated-ahb-ral-dlen-write-readback
```

The current runner applies a 4 GB process-group cap and 6 GB
system-available reserve with a 300-second bound by default. Set
`CALIPTRA_BFM_MAX_PROCESS_BYTES` and `CALIPTRA_BFM_MIN_AVAILABLE_BYTES` to
adjust the limits. Set
`CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS` to bound a diagnostic retry. Set
`CALIPTRA_BFM_RUNTIME_LOG` to retain a new run without replacing the default
runtime log.

## Opt-in open mailbox target attachment

The runtime runner accepts `--open-mbox-target`. This adds the local
[`caliptra_mbox_sram_subordinate.sv`](../../dv/caliptra_bfm/mailbox/caliptra_mbox_sram_subordinate.sv)
to the disposable generated `hdl_top`, connects it to the actual mailbox SRAM
request/response interface, enables deterministic single-/double-bit ECC
injection from the generated BFM's live configuration, and releases the
generated responder BFM's output data drive. Its UVM monitor and responder
sequence remain active. The injected bit locations are deterministic and may
differ from the generated sequence's randomized locations.

The `--open-mbox-target` probe reads the unlocked mailbox state, writes the
mailbox command and 16-byte length, sends four known words through `MBOX_DATAIN`,
and issues execute. The generated SoC-IFC AAXI monitor checks the CSR records;
the open SRAM target is peeked afterward to check every stored word. The
access-error guard remains enabled. The no-injection run ends with zero UVM
errors and fatals. Its retained log is
`generated-env-runtime-open-mbox-payload-probe-20261005.log` (raw artifact omitted from this checkpoint).

Add `--open-mbox-ecc-injection single` or `--open-mbox-ecc-injection double`
to set the generated mailbox agent's live configuration for the first SRAM
write. Both runs verify that the mode reaches the target while that request is
active, that the generated BFM clears its one-shot setting afterward, and that
the address-derived corruption appears in SRAM word zero while the other three
words remain unchanged. Both end with zero UVM errors and fatals: single-bit
log (raw artifact omitted from this checkpoint), double-bit
log (raw artifact omitted from this checkpoint).
The target's deterministic mask verifies live injection propagation and stored
data corruption; it does not reproduce the generated sequence's randomized
mask or qualify the generated responder's randomized ECC mask. The generated
AHB/AAXI command/status handshake passes without ECC and with single-bit and
deterministic double-bit ECC; double-bit status scoring uses the runtime
predictor overlay described above. The separate
actual-RTL SoC-IFC harness also covers a four-word request/response round trip.

Use `--generated-ahb-mbox-payload` to send the same four-word request through
the generated AHB RAL map instead. This option attaches the open target and
performs the lock claim and MBOX_DLEN readback itself. It supports the same
`--open-mbox-ecc-injection single|double` option.

Earlier guarded attempts timed out before producing mailbox transaction
evidence. The response-ID comparison fix from the earlier open-target run
remains in place: response IDs are checked in completed object comparisons,
while that field is omitted only from request-phase predictor comparisons.
The earlier run is retained at
`generated-env-runtime-open-mbox-response-id-fix-retry-20261005.log` (raw artifact omitted from this checkpoint).

The target uses a packed initialized-word bitmap to lazily return zero for
unwritten words. The focused component regression and generated payload runs
pass with this version.

Retry the opt-in attachment with:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=vvp/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --generated-environment-runtime --open-mbox-target
```

Exercise the generated agent's one-shot ECC setting with:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=vvp/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --generated-environment-runtime --open-mbox-target --open-mbox-ecc-injection single
```

Replace `single` with `double` to check the double-bit mode.

Replay the generated AHB RAL path with:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=vvp/vvp \
  python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --generated-environment-runtime --generated-ahb-mbox-payload
```

The overlay never writes to the pinned Caliptra checkout. Its source hashes are:

The open-mailbox attachment generator connects `access_error` to a reset-gated
`$fatal` in the disposable top. The passing payload and ECC runs confirm no
invalid mailbox target access occurred; the fatal branch for an invalid
request was not deliberately triggered.

| Artifact | SHA-256 |
| --- | --- |
| Original generated `mbox_sram_driver_bfm.sv` | `8e8e3973fe64221557c3df6fd32af9892e5d1443a5c662a3285d265db5eb6948` |
| `hdl_top` from the captured guarded attempt (pre-ECC hookup) | `534175531da2f05e65b6a219beb47492185563eba89867ed7c2820f54d9e24bd` |
| Mailbox target in the captured guarded attempt (pre-ECC support) | `cb0c7704b92c4ff6d1a330549c03d0a389d98ea4976a59cf252bd50f597c43e9` |
| Mailbox-target `hdl_top` output before access-error guard | `6958679a74b4f1b786c9083fc358c301d102386cbd4c8beb38743db0c9d41ab2` |
| Current local mailbox target | `f1d4be8a09fc37f08f575def715c8591942369bb98bcf50350cee7ab2d1f4d40` |
| Mailbox driver release overlay output | `c5cd5a20b9acc64eb53587e03c53d181f09644fd952806e210e9f890658b6417` |
| Hash-guarded mailbox driver release script | `a91e1785e1152a5355aef489454dd660e2239a33499686e0767724d81a88223c` |
| Attachment generator used for captured attempt | `95d9bb046548a139bed75b55dd22c0d0f5b3a10ca32d3b2c7fe9d43aedc73640` |
| Current attachment generator with access-error fatal | `84770bef7d169396393fcc9af67cb6b06f2abda76e3437b20e3b583b0e400de7` |
| Runtime runner with open-target ECC injection and repeated-status coalescing | `fc035de606b9df086afa49d7cda0f7ff3fd0899df6f0fb0bcf1e99c1a101e86b` |
| Current generated runtime probe package with lifecycle, ECC, response handshake, AXI USER, and shutdown checks | `68d4bfba62c2fce81cd49ef181d5198e356435799a8f1f2aaee41dbe16fa6ffa` |
| Current generated runtime probe top with target request and mailbox availability checks | `8d2983b34f79a4121a6fcf6deb0e626d622e865e32cd1dda993630a920f0253c` |
| Successful four-word open-mailbox runtime log | `e1097cb60640c33f6c64e3c1e15bf852bf0bb0b94d07fa7b94e61a77bf52daa6` |
| Successful current no-injection runtime log | `5c2155b4dab061deabe2009323c409a9acbfffef5f8556cdfa3229294958d2e0` |
| Successful generated single-bit injection log | `f455b041a4554d8cabed274bef7776a9d57ec418fffc35e98002924f6ef1c2e6` |
| Successful generated double-bit injection log | `6dcfb3d032f49b2512cd076e3763cb9fec7a5ea2e797f4603571cf9ada9a091e` |
| Successful AHB mailbox no-injection lifecycle log | `5f252f6babf6893c4b78f2f29860a9cc615685e9b549823738fe32b6647380f5` |
| Successful AHB mailbox single-bit lifecycle log | `5fc7a6537b7e39799daf1f8218c5be050b605ea2eb5cd9d28e5f48ed9bf2d7a1` |
| Successful AHB mailbox double-bit lifecycle log | `50a19759de96be80448c397e139bc769da3def7caa98821acbac2dfb360bdc19` |
| Successful stock AXI USER plus AHB double-bit mailbox log | `d262b2364e85b9e3c6f7c61c6d5faeeab87e2632572bcc481b892feb581e8e0d` |
| AAXI comparator with read-response `beatQ` comparison | `4866ecf3615f574dca28f406e31f7241351a93764a9e9ee808f625996a7de540` |
| Successful generated AHB/AAXI no-ECC mailbox roundtrip log | `746f8a2945e44f8075e767226524e042ac0f263f7b838b9317eccab794f8b323` |
| Successful generated AHB/AAXI single-bit ECC mailbox roundtrip log | `b66236febf3cadf4a770424b7d1fc16c7ed3a0f112c01ab4abc01ef93f2df771` |
| Diagnostic generated AHB/AAXI double-bit ECC mailbox roundtrip log | `43070832f1424ad4d45f8f9228ffe732ba4dc7685a8ab35aa20d83c40c2b09ac` |
| Successful generated AHB/AAXI double-bit ECC mailbox roundtrip log | `0ec0abb710cd7a61d7806d79714cc263d8cf8edb30752655f69cc3ec35ed7fb1` |
| Diagnostic generated AHB/AAXI no-ECC roundtrip with invalid AXI USER | `5bb4227f4ee5f5d14febb3c7185d99a828cb4c20f04131cb4a2b5b86f99c1b7e` |
| Successful generated AHB/AAXI no-ECC roundtrip with AXI USER init and explicit shutdown | `22e5692dcd9454fcc738b46acb62dd8a821a6614170ea6d141412ffb72379f0f` |
| Successful generated AHB/AAXI single-bit ECC roundtrip with AXI USER init and explicit shutdown | `271923851badedecd6b656ba84b3d9f4913851716ec88fe739b9d0272a695498` |
| Successful generated AHB/AAXI double-bit ECC roundtrip with AXI USER init and explicit shutdown | `f543ca3f6bf0e58dacc9895e8efe11d4102db8679574a659a4d8dc4fbde0702b` |
| Successful generated AHB/AAXI no-ECC roundtrip using default AXI USER | `f3a03c5d483cf9b23d8e02c53cdbbb5ab647bfa4078c6c17ecf823e15119db6c` |
| Captured guarded attempt log | `71515e623c552f7620ada01b57e0d34a6ef56ed730c8a2fccefb62a7da24a945` |

### Caliptra top-environment probe on 2026-10-08 (diagnostic)

The `--caliptra-top-env-probe` run completed against the generated top
wrapper and actual `soc_ifc_top`, using clean Caliptra commit
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and paired Icarus/VVP 13.0-dev
`ac4532fa-dirty`. It reached the generated top-environment reset pass marker;
the scoreboard reported 3/3 matches with zero mismatches, no-comparison or
missed transactions, zero UVM errors/fatals, and one QVIP coverage notice.
This covers the wrapper reset/predictor path, not the full Caliptra core/top.
Diagnostic only: the simulator build is dirty and unpublished, so this does
not qualify the lane.

### Top-environment AXI USER run on 2026-10-08 (diagnostic)

`--caliptra-top-env-probe --generated-axi-user-init` now starts Caliptra's
stock AXI USER sequence through the generated top wrapper's SoC-IFC virtual
sequencer. All 12 single-beat writes completed; the five mailbox USER values,
five locks, and TRNG USER/lock RAL mirrors matched. The scoreboard reported
15/15 matches with zero mismatches/no-comparison/missed transactions, zero
UVM errors/fatals, and one QVIP coverage notice. This used clean Caliptra
commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and paired Icarus/VVP
13.0-dev `ac4532fa-dirty`. Diagnostic only: the simulator build is dirty and
unpublished, so this does not qualify the lane.

### Top-environment AXI USER readback on 2026-10-08 (diagnostic)

The generated top wrapper now also performs an AXI RAL readback of the first
mailbox valid-USER register after the stock 12-write initialization. The read
uses the same allowed USER extension and verifies the returned value. Monitors
recorded 12 AW/W/B handshakes and one AR/R handshake; the scoreboard reported
16/16 matches, zero mismatches/no-comparison/missed transactions, zero UVM
errors/fatals, and one QVIP coverage notice. This remains diagnostic on paired
Icarus/VVP 13.0-dev `ac4532fa-dirty`; it does not qualify the lane.


### Top-environment AXI USER pin check on 2026-10-08 (diagnostic)

The data-only readback follow-up did not verify the address USER sideband. A
new monitor assertion checks the completed pin record for address `0x30048`,
`ARUSER=0xc0de0000`, `OKAY`, and read data `0xc0de0000`. Its first run exposed
that the stock initialization sequence's `axi_user_obj` still held the reset
USER after initialization; the probe now sets that object to mailbox slot 0
before issuing the read. The replay passed with 12 writes plus one read and
16/16 scoreboard matches, zero mismatches/no-comparison/missed transactions,
zero UVM errors/fatals, and one QVIP coverage notice. The raw VVP log is
retained locally at `/private/tmp/qd-bfm-top-axi-user-aruser-vvp-20261008.log`,
SHA-256 `b89922171bee602c4df3b249144b0398c16605147e0a52de15b8074b573b82e5`.
It used
clean Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and paired Icarus/VVP
13.0-dev `ac4532fa-dirty`; diagnostic only, not qualification.
