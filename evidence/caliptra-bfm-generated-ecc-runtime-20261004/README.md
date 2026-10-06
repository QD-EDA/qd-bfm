> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated Caliptra ECC runtime proxy regression — 2026-10-04

## Scope

This probe builds the actual generated ECC `test_top`, invokes `run_test`, and
checks the generated environment and agents after UVM build/connect. It
registers generated driver and monitor BFM interface instances in
`uvm_config_db`. It does not instantiate the ECC DUT or run a sequence.

The test checks that the generated driver BFM proxy is exactly the generated
driver object and that both monitor BFM proxies are exactly their generated
monitor objects. It never assigns a proxy from the test, so only the generated
`set_bfm_proxy_handle()` path can satisfy these checks.

The original probe exposed DD-105: generated `bfm.proxy = this` assignments
left the proxy null under both IEEE editions. A minimal regression now
reproduces the parameterized config/base/interface/class cycle in
`ivtest/ivltests/sv_package_param_class_handle_proxy_chain.v`. Before the
compiler fix, the interface property was emitted as a 32-bit logic value and
the setter lowered to a scalar store of zero.

The compiler now revisits class-handle properties on completed interface
layouts after class/package signatures are visible and before package method
bodies are elaborated. The fixed VVP image uses an object-typed proxy property
and `%store/prop/obj`. The actual generated ECC runtime probe passes under
IEEE 2017 and 2023: all three generated proxy handles match their driver or
monitor components, and the UVM summary reports zero errors and fatals.

## Verify the fix

Run from the `BFM WORK` clone root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  evidence/caliptra-bfm-generated-ecc-runtime-20261004/verify_fixed.sh
```

The script recompiles the pinned generated source order and runs both IEEE
editions. It requires exact driver/monitor proxy identity, the explicit probe
PASS message, and zero UVM errors/fatals. Before running VVP, it also checks the
emitted image for an object-typed `ECC_in_driver_bfm.proxy` and an
object-property store in the generated setter. The captured result is in
`verify_fixed.log` (raw artifact omitted from this checkpoint).

`reproduce.sh` is retained as the pre-fix negative check. It expects an
identity mismatch from the generated proxy hook and exits nonzero if the
blocker does not reproduce; use `verify_fixed.sh` for the current
expected-pass check.

The focused interface/class VVP list passes all 14 cases, including the new
proxy-chain test under both editions. That test checks two distinct
driver/interface specializations (32/32 and 13/7), guarding against default
specialization collapse.

Observed fixed output:

```text
UVM_INFO ... [ECC_PROBE] PASS: generated ECC driver and monitor proxy identities match their components
UVM_ERROR :    0
UVM_FATAL :    0
PASS: generated ECC environment proxies installed under IEEE 2017.
PASS: generated ECC environment proxies installed under IEEE 2023.
```

DD-105's runtime proxy blocker is fixed locally; full ECC DUT traffic and
broader Caliptra/UVMF qualification remain open. The separate
package/interface elaboration result is recorded in
[`caliptra-bfm-generated-ecc-packages-20261004`](../caliptra-bfm-generated-ecc-packages-20261004/README.md).

## Reduction control (follow-up)

A self-authored control using a parameterized interface property, UVM config-db
VIF retrieval, a parameterized UVM component created through the factory, and
`bfm.proxy = this` passes in both IEEE editions. Its logs remain a useful
baseline alongside the proxy-chain regression that reproduces the circular
parameterized type graph.

Re-run it with:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  evidence/caliptra-bfm-generated-ecc-runtime-20261004/run_proxy_assignment_control.sh
```

The two output logs are `proxy_assignment_control_2017.log` and
`proxy_assignment_control_2023.log`.

## Inputs and hashes

- Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; pinned checkout
  was clean and unchanged.
- Icarus/VVP revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`, built as
  13.0 devel with Accellera UVM 2020.3.1.
- The actual generated package/source hashes are listed in the package probe
  evidence README.

| Probe input/tool | SHA-256 |
| --- | --- |
| `reproduce.sh` | `117d6ea8573420d1eaab31f05e6def2b04916f6175f73ec82045d8bcbb28788b` |
| `runtime_probe.sv` | `0a508a3d7336738b3aa5fcf676e47ddc71b8961243912a056f956ad664d10750` |
| `dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv` | `afc5c560036229a6416d788cb9b35a34de434c8fcd5e879722ed917d9a9609c8` |
| `iverilog` | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| `vvp` | `b7e9e2d0b994bdd5e17a2e8033dfe76ca9fafb9ec9fdca35f16a9d1b63c9cba9` |
| `proxy_assignment_control.sv` | `8e927e1d25cb88edf72d41ffebd9df7e379fb711bbaa45326dd251b534af508e` |
| `run_proxy_assignment_control.sh` | `df8dfb21882ab889204d579666bd1da7f80cee61cc2052c462fb409879e0fe70` |
| `verify_fixed.sh` | `d3fe8b5254ab2adfc8bdfc6d6df002e23f7e29987a78a926b79245451662f1fb` |
| `verify_fixed.log` | `7a7a20994eff7f1278eb55e883800fb7a7ddca18796ecc60323c9959e8e61398` |
| `ivtest/ivltests/sv_package_param_class_handle_proxy_chain.v` | `c11ed3ea631058028d61b16981d5033e480694ab2666a66393be6666a91b1517` |

Generated `hdl_top`/`hvl_top` modport wiring, ECC DUT traffic, and broader
Caliptra qualification remain open.
