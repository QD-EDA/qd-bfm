> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated KeyVault integration with open AHB replacement — 2026-10-04

## Scope

The static probe elaborates the pinned generated KeyVault `hdl_top`, its
reset/read/write interface packages and BFMs, the actual KeyVault RTL, and the
clean-room `hdl_qvip_ahb_lite_slave` replacement. IEEE 1800-2017 and 2023 both
elaborate with 43 warnings.

The runtime probe compiles the generated `kv_env_pkg`, register model,
sequences, `kv_tests_pkg`, `hvl_top`, and real KeyVault RTL under IEEE 2017 and
2023. `kv_rand_wr_rd_test` reaches normal `$finish` in both editions with zero
UVM errors and fatals. The runtime gate checks the UVM severity summary; the
generated test's unconditional `** TESTCASE PASSED` marker is not used alone.
Compilation emits
76 Icarus warnings; the runtime's 68,229 UVM warnings remain, mostly volatile
register-mirror reads, plus missing AES-write and DMA-read register maps.
Generated KeyVault block-level runtime is qualified for this pinned Icarus
overlay and test; licensed full UVMF/QVIP integration is not.

## AHB MVC follow-up (2026-10-05)

After the open AHB manager/proxy and monitor gained bounded queue bursts, the
generated `kv_rand_wr_rd_test` was rerun under IEEE 2017 with
`sh evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.sh --runtime`.
The run exited 0 at 427.915 us with zero UVM errors/fatals and the same 68,229
generated warnings. The guarded runner observed 75% minimum free memory
against its 70% floor. The current AHB source hashes are recorded in the
[AHB QVIP follow-up evidence](../caliptra-bfm-ahb-qvip-compat-20261004/README.md).
This run checks generated scalar register traffic against the updated stream;
the separate synthetic-target test covers full and partial MVC burst items.

## Mismatch diagnosis

The initial filtered `UVM_DEBUG` trace associated all seven errors with a
same-entry write event at the same reported timestamp. The pin/model trace
showed the missing timing relationship: the raw write that changes RTL state
is sampled one 10 ns edge before the generated write monitor publishes its
transaction. The generated read monitor captures the response immediately and
does not yield a delta before notifying subscribers. At each failure timestamp
the read predictor therefore consumes the prior register mirror and
`last_dword_written` value before the delayed write event updates them. For
example, the entry `0x17` write with mask `0x179` is present at `17690 ns`; at
`17700 ns` the RTL state has that mask, while the read predictor still sees
zero and runs before `MODEL_WRITE` publishes `0x179`. The entry `0x00` last-dword
failure and both entry `0x13` permission failures show the same one-cycle
alignment. See the original UVM event excerpt in
`same_entry_event_trace.log` (raw artifact omitted from this checkpoint) and the raw-edge,
model, and scoreboard excerpt in
`pin_model_event_trace.log` (raw artifact omitted from this checkpoint).

The Icarus compatibility overlay now inserts a zero-time `#0` yield in the
generated read monitor after it captures the response and before it notifies
UVM subscribers. This preserves the sampled values and simulation timestamp
while allowing same-edge write-monitor callbacks to update the predictor first.
The unchanged generated `kv_rand_wr_rd_test` then passes its zero-error runtime
gate. The historical pre-overlay failure is retained in
`diagnose-runtime-before-delta.log` (raw artifact omitted from this checkpoint). The
generated write monitor can still emit a deassertion record and the adapter
does not check `write_en`; that remains a separate cleanup risk, but it did
not cause errors in the passing replay.

## Compiler overlays and external imports

The runner reads the source order and include roots from Caliptra's pinned
`uvmf_kv.vf`, then excludes licensed MVC/UVMF/QVIP implementation sources and
host-only packages that this static top does not use. It supplies the clean-room
UVMF-lite and AHB compatibility sources from `dv/caliptra_bfm/`.

The hash-guarded
[KeyVault overlay helper](../../docs/conformance/release_overlays/caliptra/keyvault_generated_bfm_iverilog_overlay.py)
changes only disposable copies of these generated files:

- Connects the 15 generic driver BFMs to complete interface instances. Their
  conditional responder assignments are incompatible with the generated
  initiator modport under this Icarus flow.
- Removes empty trailing `$psprintf` arguments from the reset BFM and config.
- Omits the unused `kv_write_AHB_lock_set_sequence` include from this static
  compile. The generated class references an undeclared `reg_model` member;
  it is outside the HDL-top elaboration target.
- Routes the reset package's configuration include through the patched copy.
- Adds a zero-time yield after the generated read monitor captures its fields,
  so its analysis notification follows same-edge writes from the generated
  one-clock-delayed write monitor. This is the Icarus scheduling fix diagnosed
  by the pre-fix pin/model trace.

For runtime compilation, extra temporary overlays address Icarus limitations
without changing the pinned checkout: they add the missing DMA activity entry
in generated `test_top`, replace unsupported dynamic-array slice assignments
with equivalent element assignments, and use a concrete environment-config
alias for the generated nested clock-wait calls. The alias invokes the same
generated BFM clock-wait task. Temporary empty `rw_txn_pkg`, `QUESTA_MVC`, and
`qvip_utils_pkg` stubs satisfy unused imported symbols only. No proprietary
source is copied or represented by these placeholders. The pinned Caliptra
checkout is never edited.

## Reproduce

From the `BFM WORK` clone root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  sh evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.sh
```

The runtime attempt is reproducible with:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.sh --runtime
```

Run the same generated test under IEEE 2023 with:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.sh --runtime-2023
```

The checked-in `verify-runtime.log` and `verify-runtime-2023.log` record both
edition-specific commands passing with zero UVM errors/fatals. Before the
read-monitor delta shim was added, the same gate
failed with seven scoreboard errors; that baseline is retained in
`diagnose-runtime-before-delta.log` and `pin_model_event_trace.log`.

For a bounded diagnostic replay, use `run.sh --diagnose`; it enables the
edge/model trace and writes selected events to `diagnose-runtime.log`. To retain
full simulator stdout, set `CALIPTRA_UVM_TRACE_LOG` to a chosen raw-log path.
`CALIPTRA_UVM_VERBOSITY` selects UVM verbosity and
`CALIPTRA_UVM_PLUSARGS` accepts additional space-separated VVP/UVM arguments.
The runtime invocation has a 180-second process timeout. The checked-in
pin/model excerpt is from the failing pre-shim replay; its full raw stdout
SHA-256 is recorded in `pin_model_event_trace.log`.

The runner requires a clean Caliptra source/include tree at v2.1.2 commit
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. It rejects changed relevant
sources before creating the overlay.

## Source pins

- Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`.
- Caliptra `uvmf_kv.vf` SHA-256:
  `8b6954a0995ee6752c019af82c144b4223a175ac3d4333f067f7097dfac6824c`.

| Probe input | SHA-256 |
| --- | --- |
| `run.sh` | `f13cf25e8eb98d4df8ea50c4b215132344fbdd7b3ea86f2a1510992be3fd934d` |
| `run.py` | `6fc1436045f73c3a0b2035982c4e320d1d8036101d319c96198afa0fd971bdd3` |
| `verify.log` | `7e013d9f725f46abfee4df2ccdf798919b4991f82bd1b9671bfd64cb6346859d` |
| `verify-runtime.log` | `49451247128b3d66bacf625cd0516b98a2aee915ddade562b10cc1d2d2d810f9` |
| `verify-runtime-2023.log` | `3a1bdca4bdf3c11449d187b4c2152559d529ba17289a53ae67648466efeb30d6` |
| `diagnose-runtime-before-delta.log` | `21bc72850d59b5c80bc89a37d8a384950f3aa9b7c5799a39f4d92e4cb351b27f` |
| `mismatch-debug.log` | `937461ce589b44e565fb492f2411205fc4dca79661a2f228f4209a20188c07e5` |
| `same_entry_event_trace.log` | `95392abda8f15a58d02070b9ff90bfe67a745f825c0d40cd35e5df7e104f1650` |
| `pin_model_event_trace.log` | `4dc90ad517a80d965617b116ab0507a36968cef6cf70a9ca8d2c86012f72dba0` |
| KeyVault overlay helper | `86b8e6b70479bcd7411b5ee97fefd597811a6daf2b7af9c158beb264be2fd72b` |
| `kv_read_monitor_bfm.sv` Caliptra source | `bd85776012a7e35affdb0842824b57d8ca0fd86690cbc8afa4439e3f349143bf` |
| `uvmf_base_pkg_hdl.sv` | `ba86f1323cfc88298665154a4176f7d094c8f12af1971089ece859adcefc98bc` |
| `uvmf_base_pkg.sv` | `d02d446bad86e8ac8515df9b975bd0d0c98023de6a7c9e32d1eedabfd4f7e0b5` |
| `caliptra_ahb_mvc_compat_pkg.sv` | `08ef7a3160afb379e48b114cc0e074eb33a032a4c024099b1b8c739d782fd59c` |
| `ahb_lite_caliptra_uvm_pkg.sv` | `b928bf29277747371fda9e499575be3808f1edc7b93c566b27c290ea7add236b` |
| `caliptra_ahb_qvip_compat_pkg.sv` | `9bb98c47df47242dbe52b6fbbb6cca30bacf58488de3d0c429e9bd581218bba2` |
| AHB record interface | `052cdc33275f846c1b6916e5fd00ca78cef8eeb25954fe80d8af2b37d14976a2` |
| AHB command interface | `7e2dd67252117bc7deb4ef1210dd25365f2004b6669cf7a60116bbd1008adb1f` |
| AHB manager | `ac140ad952bb14c04c9679b9f2c0a915d2d5ad8f52596f08d14369a89dcfce20` |
| AHB monitor | `ea35cdc4efc1acc54f0118368b3875e56c8010e6715ebc101472ce85d194cb76` |
| QVIP HDL shell | `53a0661f6e0d76349ab93ebe2806f93e45da9ac111a881333e0326b3b601d50e` |
| AHB pin adapter | `49d32573326b8b978f1935c7c2a0d7fd33f70e00f3ebe04c1e4e55fbaf28733f` |
| AHB UVM manager proxy | `a93c0ec83e912a88fbaf276b3440eb6e87599d35eae02312d356e071db2febca` |
