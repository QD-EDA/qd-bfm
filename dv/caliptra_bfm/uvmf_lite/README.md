# Clean-room UVMF base layer

This directory starts the clean-room base layer required by Caliptra's
generated UVMF environments. It is an incremental implementation, not a full
UVMF replacement.

`uvmf_base_pkg_hdl.sv` provides the shared active/passive and
initiator/responder enums used by generated HDL-side BFM interfaces;
`uvmf_base_pkg.sv` imports and re-exports the same enum types for HVL classes,
including named re-exports of the generator-facing `INITIATOR` and `RESPONDER`
enum literals.

`default_reset_gen.sv` supplies the generated HDL-top module interface
`default_reset_gen(CLK_IN, RESET)`. It asserts active-low reset at startup and
releases it after two rising clock edges, matching the local AHB QVIP shim's
startup reset. The timing of the licensed UVMF implementation has not been
verified. Define `CALIPTRA_BFM_EXTERNAL_UVMF` when a provider supplies this
module. Run `tests/run_default_reset_gen.sh` for the bounded reset check.

It currently provides a transaction base with the generated
`start_time`, `end_time`, and `transaction_view_h` fields plus copy/compare/
print hooks; the `uvmf_sim_level_t` enum; typed
environment and parameterized-agent configuration bases, including the
generated `initiator_responder` setting; `set_config`-based environment and
agent bases; virtual sequencer, typed sequence (`REQ`/`RSP`), virtual-sequence,
and test bases; generic driver and monitor bases matching the generated
`configure`, proxy, `access`, and `analyze` hooks; and
`uvmf_parameterized_agent`, which creates the monitor and, when active, the
sequencer and driver, publishes the sequencer, connects analysis/sequence
ports, and can add coverage. It also provides
`uvmf_in_order_scoreboard #(T)`, the scoreboard instantiated by Caliptra ECC,
HMAC, and SHA-512 generated environments. The scoreboard accepts expected and
actual analysis streams, clones each item on arrival, compares in FIFO order,
reports mismatches, reports unmatched items during `check_phase`, and
publishes a count summary. The separate
`uvmf_out_of_order_scoreboard #(T)` pairs exact transaction matches regardless
of arrival order; remaining pairs are reported as mismatches and unpaired items
as leftovers in `check_phase`. Its focused smoke tests reordered matches and an
end-of-test mismatch, but Caliptra traffic is not yet qualified. `uvmf_lite.f` is the package filelist to use from
the repository root. Both package source files are guarded by
`CALIPTRA_BFM_EXTERNAL_UVMF` so a provider-specific filelist can supply the
licensed or separately pinned UVMF packages instead.

Run `tests/run_uvmf_scoreboard.sh` and `tests/run_uvmf_agent.sh` with the local
Icarus `-uvm` fork selected through `IVERILOG_BIN` and `VVP_BIN`. Both runners
compile and execute with `-g2017` and `-g2023`, using bundled Accellera UVM
2020.3.1. Set `UVMF_IEEE_EDITION=2017` or `2023` to run one agent-smoke
edition, including its negative control. The scoreboard smoke includes a
normal match with a publisher-side mutation after write, one compare mismatch,
one expected-only leftover, and one actual-only leftover.
The runner requires exactly four UVM_ERROR reports and zero UVM_FATAL reports:
one in-order mismatch, one out-of-order mismatch, and two leftover controls.
It also checks that the out-of-order scoreboard matches reordered items. The
negative controls are part of the pass condition. The agent smoke
follows a generated-style test → environment → active/passive agent hierarchy,
initializes typed virtual BFMs, exercises the active sequencer/driver path,
verifies the type override creates both agents, checks driver and monitor
proxy installation, starts a virtual sequence on a configured virtual sequencer,
and carries monitor data
through `monitored_ap` to an observer and coverage sink. A second passive agent
reuses a parent-created monitor provided under its `monitor` config-db key to
observe the response from a one-cycle combinational toy DUT. A predictor
receives the active agent's request, predicts the response, and feeds the
in-order scoreboard. The matching run records one match; a second run injects
an incorrect prediction and requires exactly one scoreboard mismatch, while
both runs terminate with no UVM_FATAL. Both sinks use explicit
`uvm_analysis_imp` connections. The smoke
transaction implements copy, compare, and print hooks so cloned values are
preserved and checked.
The passive output agent is initialized with only its monitor BFM registered;
the configuration base requires and fetches a driver BFM only for `ACTIVE`
agents. This matches generated ECC's passive output agent, whose HDL top
instantiates a monitor but no output driver.
The smoke item derives from `uvmf_transaction_base`: it checks that timestamps
and the transaction-view handle copy, that differing timestamps do not cause a
compare mismatch, and that changing the item's value does. Generated ECC
predictors leave expected timestamps unset while monitors stamp observed items,
so those base timestamps are recording metadata rather than equality fields.

The typed config/VIF handoff and component bases are exercised with a
self-authored active/passive environment. Generated Caliptra ECC `test_top`
and agent construction reach the actual ECC DUT for an interrupt-enable
register write/read through the generated driver's BFM tasks. The generated
reset scoreboard matches in both IEEE editions, and the generated keygen
sequence matches its predicted result in both editions. Key signing,
verification, ECDH shared-key operations, broader generated-environment
traffic, and full generated `hdl_top`/`hvl_top` qualification remain open; see
the [generated ECC runtime evidence](../../../evidence/caliptra-bfm-generated-ecc-hdl-20261004/README.md).
Generated status-agent monitoring also has a focused runtime probe.
The generated SHA-512 `SHA512_random_test` also runs against actual
`sha512_ctrl` RTL through the clean-room base. The stock generated output
monitor publishes a reset-only zero sample that shifts the expected/actual
streams; a hash-guarded disposable overlay removes that sample without
changing digest sampling. The scoreboard matched 13 expected and 13 observed
items with zero pending transactions. This is one test path, not full UVMF or
top-level qualification. See
[`generated SHA-512 runtime evidence`](../../../evidence/caliptra-bfm-generated-sha512-runtime-20261005/README.md).
An earlier `uvm_subscriber #(agent_item)` probe received a null handle, but
that result was probe-specific: the actual generated Caliptra
`cptra_status_transaction_coverage` subscriber now receives and samples all
three expected records in the [full-snapshot probe](../../../evidence/caliptra-bfm-generated-status-full-snapshot-20261004/README.md),
including on the merged Icarus build. This verifies subscriber delivery and
sampling calls only; Icarus still compiles covergroups as stubs, so bin hits
and coverage percentages are not measured. Other generated coverage paths
still need qualification. The agent smoke now registers typed BFM handles
after environment/agent configuration initialization and resolves them during
agent build. Its isolated IEEE 2017 positive and mismatch-control cases passed;
the 2023 run and registration after agent build remain unverified. See the
[late-registration evidence](../../../evidence/caliptra-bfm-uvmf-late-vif-20261007/README.md).
Generated derived configuration publication is covered by the smoke's
config-DB identity checks. The
clean-room base does not provide generic reset/clock wait helpers; the
inspected generated Caliptra configuration classes implement
`wait_for_reset` and `wait_for_num_clocks` by delegating to their monitor BFMs. Generated BFM macros
and utility packages, transaction recording, HDL/HVL proxy startup, and
remaining top scaffolding are still open.
Do not treat it as a drop-in UVMF package yet.

The focused compile probe follows the ECC entries in Caliptra's pinned
`config/compile.yml` order. It compiles the actual generated input/output
packages, all four driver/monitor BFMs, both bus interfaces, the environment,
parameter, sequence, and test packages under `-g2017` and `-g2023`. Both modes
have zero elaboration errors and 34 Icarus coverage-stub warnings for generated
`set_inst_name` calls. This clears the earlier source-order diagnosis: the
package/interface declarations compile when ordered as Caliptra configures
them.

The probe instantiates all four actual BFM interfaces with both actual bus
interfaces in a temporary elaboration top. That top connects full interface
handles directly. It does not compile Caliptra's generated `hdl_top`/`hvl_top`,
instantiate `test_top`, call `run_test`, or drive the ECC DUT. It establishes
compile and module-instance compatibility for the actual ECC BFM and class
sources, not generated UVMF runtime or DUT qualification. The clean-room base
package named-exports the generated `ACTIVE`/`PASSIVE` and
`INITIATOR`/`RESPONDER` enum literals.

A separate saved runtime probe builds the actual generated ECC `test_top`,
environment, and agents through `run_test` in both editions. It checks exact
identity for the generated input-driver proxy and both input/output monitor
proxies; the generated setter path now passes after the local DD-105 compiler
fix. A structural VVP check verifies the proxy uses an object-typed property
and object-property store. See
[`generated ECC runtime evidence`](../../../evidence/caliptra-bfm-generated-ecc-runtime-20261004/README.md)
and discovery DD-105 in `docs/conformance/DISCOVERED_DEBT.md`.

The stock generated `hdl_top.sv` has two Icarus direction errors: its input
BFM writes `hrdata` and `hreadyout` through inputs of
`ECC_in_if.initiator_port`. The hash-checked
`tests/run_generated_ecc_hdl_top.sh` confirms those errors on the untouched
source, then elaborates the actual ECC RTL and generated UVMF packages from a
temporary copy with the three generated modport selectors removed and an
explicit `1ns/1ps` timescale. Both IEEE editions pass; the pinned checkout is
unchanged. This makes the generated top compile path repeatable without
claiming that the generated source compiles unchanged. The companion
`tests/run_generated_ecc_reset_monitor.sh` runs the actual generated ECC
environment against `ecc_top` under both IEEE editions. It checks a matched
reset transaction and an `ECC_IRQ_EN` AHB write/readback with zero UVM errors
or fatals. It runs both editions by default; set `ECC_IEEE_EDITION=2017` or
`ECC_IEEE_EDITION=2023` to run one edition independently. Set
`ECC_RESET_MONITOR_LOG_DIR` to retain the run logs.

The 384-bit ECC automatic bins are represented as exact leading-bit prefixes;
the focused regression also covers 512-bit explicit ranges, a 65-bit
non-power-of-two partition, and prefixes that cross a 64-bit word boundary.
All four enum literals resolve through the named base-package exports; generated
coverage-stub warnings remain, so this is not runtime qualification. The
wide-range regression checks endpoints, overlapping bins, and X/Z-to-zero
sample conversion. The generated status wildcard transition bins pass in
2012/2017/2023. The cptra-status package/interface/agent compiles and its
passive monitor publishes all 17 transaction fields in a startup sample and
two event samples under 2017/2023, using the named hash-guarded overlay for
three trailing-empty `$psprintf` arguments. Selected generated SoC-IFC runtime
paths now pass with actual RTL: reset/power-on, stock 12-write AAXI USER-init,
and mailbox/AHB RAL traffic. Broader status coverage, other generated
sequences, and complete environment qualification remain open; see the
[`generated SoC-IFC runtime evidence`](../../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md).
The separate `soc_ifc_ctrl_pkg` trailing-empty-argument issue is not overlaid.
The repeatable
ECC probe is `tests/run_generated_ecc_env_probe.sh`; set
`CALIPTRA_ROOT` and `IVERILOG_BIN` to select the pinned Caliptra source tree and
local Icarus fork. The
`maps[j].get_full_name` shape is covered by the no-parentheses regression,
including an inherited method on a selected queue element. Slang's separate
virtual-interface type diagnostic on a generated BFM interface remains
unqualified. See
[`caliptra_bfm_research_2026-10-03.md`](../../../docs/conformance/caliptra_bfm_research_2026-10-03.md#generated-ecc-compile-probe).

The full status-field sampling result and its reproducible runner are in
[`generated status full-snapshot evidence`](../../../evidence/caliptra-bfm-generated-status-full-snapshot-20261004/README.md).
