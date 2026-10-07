# Pinned Linux AXI evidence

The CI workflow builds these immutable upstream revisions on Ubuntu 24.04:

| Input | Commit |
| --- | --- |
| Icarus 13.0 | `dfeee909ed9f20b4870dd93423156c0170c0e1ff` |
| Verilator 5.050 | `848d926ebd4addacacd294dc84e35d9d4ae8078c` |
| Caliptra v2.1.2 | `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` |

Run `bash ci/run_caliptra_pilot.sh NEW_WORK_DIRECTORY` from the repository root.
Build prerequisites are in `.github/workflows/caliptra-pilot.yml`; simulator
builds follow the upstream autoconf/configure/make instructions. The script
requires a new work directory, verifies fetched SHAs, records QD revision,
host/package versions, build logs and hashes of installed tool files, and runs
the existing standalone four-state suite. The job has a 35-minute bound;
each pilot compiler/simulator subprocess retains its 120-second bound.
System packages and the hosted runner image are recorded, not immutable.

The actual Caliptra pilot uses delays 0 and 7, with all other parameters and
coverage as documented in RESPONSE_BACKPRESSURE_EVIDENCE.md. Raw commands,
diagnostics, input hashes, timings and peak RSS are archived even on failure.
The artifact excludes generated simulator object directories; it contains no
checkout of application sources. Artifact retention is 30 days, so release
qualification must additionally preserve an immutable long-term bundle.

The runner's exit 2 is required for the present pinned configuration. The CI
checker independently requires the expected command/status sequence, correct
delay parameter, three exact width diagnostics, five exact unavailable assertion
sites, transfer/stall coverage and detected data fault. Diagnostic drift fails CI
for review, even if a future tool removes a warning. This is evidence checking,
not a waiver or a clean simulation result: status JSON remains UNKNOWN.
Eleven corruptions of copied real evidence must be rejected. The checker does
not prove compiler diagnostics complete or validate all possible artifacts.

The USER lane additionally runs `+USER` and `+USER +BAD_USER` against the real
`axi_sub` default configuration at delays 0 and 7. The evidence checker requires
18 total transfers and 36 component hold cycles in the positive run and a
component USER mismatch with no PASS in the negative run. This remains an
UNKNOWN pilot because the same width warnings and unavailable assertion-enabled
build remain.

The FIXED-burst lane runs `tb_fixed_burst.sv` in the Icarus suite, then compiles
`tb_caliptra_axi_fixed_burst.sv` through the pinned native `axi_sub.vf`. It
checks strict 16-beat and explicitly nonconforming 256-beat compatibility
write/read pairs, 544 component beats, USER pins, and W/R/B stalls. Injected
read-data and address-USER faults must fail. Reproduce locally with
`bash ci/run_fixed_burst_pilot.sh CLEAN_PINNED_CALIPTRA NEW_EVIDENCE_DIR` using
Verilator 5.050. Exit 2 is the expected **UNKNOWN** status: three exact upstream
width warnings are archived and required, and the assertion-enabled lane
remains unavailable. The compatibility observation is not AXI4 compliance or
released L0 bench execution; response USER and outbound DMA are not covered.

The original packaged-Icarus smoke job remains. No RTL/DV changes, diagnostic
suppression or assertion removal are introduced. Verilator behavior is two-state;
X/Z claims come only from the Icarus suite. Neither full-chip DV, INCR/WRAP bursts, UVM,
nor general AXI compliance are established. Two independent Linux runs and
comparison of input hashes, statuses and behavioral coverage are required before
claiming repeatability of this bounded configuration; CI alone is not production
qualification.
