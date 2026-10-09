> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated PCRVault UVMF runtime with clean-room adapters — 2026-10-04

## Result

The pinned generated `hdl_top` and `hvl_top` compile together under IEEE
1800-2017 and run the actual generated `pv_rand_wr_rd_test` against Caliptra's
PCRVault RTL. The runner requires normal test termination, the generated
`** TESTCASE PASSED` marker, and zero UVM errors/fatals. UVM warnings are
reported because the generated model marks PCR fields volatile and emits its
standard coverage-review warning; they are not suppressed.

Captured run: IEEE 1800-2017; UVM_INFO=417, UVM_WARNING=768, UVM_ERROR=0,
UVM_FATAL=0; `$finish` at 56.435 us.

This is a generated PCRVault block test using Caliptra's checked-in PV agent
BFMs, the repository's clean-room UVMF-lite and QVIP AHB compatibility layer,
and temporary placeholder packages for imported but unused external symbols.
It is not a full Caliptra top-level or licensed UVMF/QVIP qualification. The
test does exercise the recreated AHB RAL adapter/predictor in the generated
environment and the generated PV write/read sequences plus scoreboard.

## Why the source overlays are present

The runner invokes the hash-guarded
[`PCRVault overlay helper`](../../docs/conformance/release_overlays/caliptra/pcrvault_generated_bfm_iverilog_overlay.py)
for only the pinned Caliptra v2.1.2 files. In addition to Icarus syntax and
modport workarounds, the overlay makes two PV BFM repairs visible at the
consumer boundary:

- The generated PV read driver copied request fields but left `read_data`,
  `last`, and `error` unset in its response item.
- The generated PV read monitor sampled only on rising edges and treated
  response-only changes as new transactions. A reset immediately after the
  final read could clear PCR storage before that late monitor sample.

The overlay copies the read response fields and samples each changed request
at the intervening falling edge, before a following reset edge. The pinned
Caliptra checkout is never edited. All overlay source hashes and exact
replacement anchors are checked by the helper.

The helper also uses exact-source workarounds for generated empty `$psprintf`
arguments, three PV modport connections, two dynamic-array slices in the PV
configuration, and a type-parameter field access in the generated AHB
predictor. These overlays are compatibility workarounds, not changes to the
Caliptra checkout.

## Reproduce

From the `BFM WORK` clone root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-pv-generated-uvmf-20261004/run.sh
```

The temporary empty stubs for `rw_txn_pkg`, `QUESTA_MVC`, and
`qvip_memory_message_handler` satisfy unused package imports only; no code is
copied from or represented as those licensed libraries. The test's actual
AHB adapter, predictor, UVMF environment, scoreboard, and PV RTL remain
compiled and exercised.

## Rerun after AHB MVC burst integration (2026-10-05)

The same guarded command was rerun after extending the open AHB MVC driver and
monitor. The generated `pv_rand_wr_rd_test` again terminated normally with
`** TESTCASE PASSED`, UVM_INFO=417, UVM_WARNING=768, UVM_ERROR=0, and
UVM_FATAL=0 at 56.435 us. This confirms the updated AHB command/proxy and
grouped monitor remain compatible with the generated PV scalar RAL traffic; the
separate synthetic-target UVM test covers full and partial MVC bursts. The RAM guard
reported 74% minimum free memory against its 70% floor.
The guarded runner's SHA-256 after its `sh` re-exec fix is
`40396f39d33c19b49ca6b764caa87d4f9f4962911d0803185f404b977ec461d4`.

## Source pins

- Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`.

| Probe input | SHA-256 |
| --- | --- |
| `run.sh` at the 2026-10-04 capture | `25f858df82425d23a33405d87452f733c364db81b0950bf3a56d4dac0162b3c7` |
| `verify.log` | `1d91489f1eb19e5f96797b4572a9d3fcec62f517158afd18c9e3d9a99c020b94` |
| overlay helper | `eafff8df6a3aa78d89832c7b901ba7158cecf56b6d12e826251519d05e38658d` |

## Latest published Icarus check — 2026-10-09

The guarded [`run.sh`](run.sh) and Python runner were restored as a reproducible
entry point. The runner uses the pinned Caliptra v2.1.2 source, applies the
existing exact-hash overlay in a temporary directory, and requires nonzero PV
read and write scoreboard comparisons, the test pass marker, normal finish,
and zero UVM errors/fatals. It runs under the repository memory guard.

The simulator remote-head check returned published Icarus `main`
`0d8815febc260928e62d5c2ce82b14afd2e38dc3`; the run used the existing build
of that clean published revision. Compilation stops before VVP at four
package-qualified proxy declarations in the generated PV driver/monitor BFMs
(`pv_read_driver_bfm.sv:136`, `pv_read_monitor_bfm.sv:98`,
`pv_write_driver_bfm.sv:135`, and `pv_write_monitor_bfm.sv:111`). No current-main
runtime or scoreboard result was produced. The 2026-10-04/05 passing runs above
remain historical results on their recorded Icarus revision; they do not show
that this generated bench passes on current `main`.

The current-main probe command was:

```sh
CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
sh evidence/caliptra-bfm-pv-generated-uvmf-20261004/run.sh
```
