> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated Caliptra ECC BFM/package compile probe — 2026-10-04

## Scope

The focused probe follows the ECC source order in Caliptra's pinned
`config/compile.yml`. It compiles actual `ECC_in_pkg`, `ECC_out_pkg`,
`ECC_env_pkg`, `ECC_parameters_pkg`, `ECC_sequences_pkg`, and `ECC_tests_pkg`
sources, along with all four generated driver/monitor BFM interfaces and both
generated bus interfaces. This reaches the generated driver, monitor, agent,
predictor, environment, sequence, and test class definitions with the
clean-room UVMF-lite package.

The probe instantiates all four actual BFM interfaces and both bus interfaces
in a temporary elaboration top, using full interface handles. It stops after
the generated test package and uses `-tnull`; it does not compile Caliptra's
generated `hdl_top`/`hvl_top`, instantiate `test_top`, call `run_test`, drive
the ECC DUT, or qualify generated UVM runtime behavior. An earlier
grouped-source probe suggested a package/interface cycle; matching Caliptra's
configured source order compiles and elaborates the actual instances and
corrects that diagnosis. The temporary top does not reproduce the modport
connections used by Caliptra's generated `hdl_top`.

During this expansion, the real generated test package exposed its use of
`ACTIVE` and `PASSIVE` enum literals from `uvmf_base_pkg`. The clean-room base
package now explicitly re-exports those original HDL package items, alongside
the already required `INITIATOR` and `RESPONDER` literals.

The package probe top passes full interface handles to the BFMs. A separate
probe using the generated modport handles fails in both editions: the input
BFM writes `hrdata`/`hreadyout` through `initiator_port`, and the output driver
BFM writes `test`/`op` through `responder_port`, although those are inputs in
the respective modports. Caliptra's generated `hdl_top` instantiates the input
driver and monitor BFMs but not the output driver, so its pristine compile has
the two input-driver errors. A temporary copy with its three instantiated
modport selectors removed compiles against actual ECC RTL in both editions;
this is elaboration only, not generated ECC traffic. See
[`generated ECC HDL-top evidence`](../caliptra-bfm-generated-ecc-hdl-20261004/README.md).

## Inputs and toolchain

- Caliptra v2.1.2, commit
  `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; the pinned checkout was clean
  and unchanged.
- Icarus/VVP revision `246c58e4580f38a130ec08e5a7e6d93f110a5084`, built as
  13.0 devel with Accellera UVM 2020.3.1.
- This probe uses `-tnull`; the empty top only lets Icarus elaborate the package
  dependency set. It does not start VVP.

## Reproduction and result

From the `BFM WORK` clone root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  sh dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_env_probe.sh
```

Both editions passed with actual generated BFM and bus-interface instances:

```text
PASS: actual generated ECC BFM/interface instances and environment/parameter/sequence/test packages elaborate under IEEE 2017 (34 compiler warnings).
PASS: actual generated ECC BFM/interface instances and environment/parameter/sequence/test packages elaborate under IEEE 2023 (34 compiler warnings).
```

The warnings are Icarus compile-progress warnings for `set_inst_name` calls on
generated covergroups that are represented by coverage stubs. They are not
runtime coverage results. The runner checks for elaboration errors and enum
lookup failures; it removes its temporary top and logs when complete.

## Source hashes

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_env_probe.sh` | `1cbb3c97db77b22f791ec16dd96b2ad0e87bc920d44e9de06ccae1a2f23b470f` |
| `dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv` | `afc5c560036229a6416d788cb9b35a34de434c8fcd5e879722ed917d9a9609c8` |
| `dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv` | `380485e493bb2c1e927e59f4decd6335b0ffe0207cc64dc71cdc0470dbdf7b8d` |
| Caliptra `config/compile.yml` | `445a40e30f5e97fe912b11f07be5c2a4ca99fe07b2389c004ccd0286745d2a47` |
| Caliptra `ECC_in_pkg.sv` | `f529f9b4671579ce2f10f6016817e4acf2814af15fe35bf7ee868e3c192e0420` |
| Caliptra `ECC_in_driver_bfm.sv` | `ac6594e2ff7bac5a30c2b3def59067099e3e9749e559b23251b99c52e8ecf9dc` |
| Caliptra `ECC_in_if.sv` | `776cade8f014eba1f7414b0ea4a86290924fd72ebdfc377176119b39d438b1aa` |
| Caliptra `ECC_in_monitor_bfm.sv` | `4bdd8631566d578514affb2c7e34ab4706fe45f3f53352bfda26d447297cfaf2` |
| Caliptra `ECC_out_pkg.sv` | `ae489321a7e6f6da9112f9aa2a9a03ec794aca20fb31933ed4074c7f48a81cf0` |
| Caliptra `ECC_out_driver_bfm.sv` | `5eaea71fbdedc74794a36400427a9d6732ae48bcb83e7e2ea86603639a5083eb` |
| Caliptra `ECC_out_if.sv` | `59bc1d708a75c741c0f6cc10e9126bd2f9527b0708a5e623e28beb42aef840fa` |
| Caliptra `ECC_out_monitor_bfm.sv` | `360f641ca3f51f1a3c26fb7c47217d7cf80f72a1cb1405e3633540a453e78393` |
| Caliptra `ECC_env_pkg.sv` | `cc2a782cfa5297ce3ca58fe797b90a5c578bc188a43d8edb5954447d724d9069` |
| Caliptra `ECC_parameters_pkg.sv` | `0a2e404edf0cbb3b1aa7d3cce329be9ff02097f2b0959142e0dc4d3dde49257b` |
| Caliptra `ECC_sequences_pkg.sv` | `50efbf38e6c4f33259a1cdbcbc0dbe62363aab714a7e98ac5c877854c498d976` |
| Caliptra `ECC_tests_pkg.sv` | `23aa2efa0c6927a52d9300307c4bba4fcd4cf461e24e7c01e06d06a412784747` |
| `iverilog` | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| `vvp` | `b7e9e2d0b994bdd5e17a2e8033dfe76ca9fafb9ec9fdca35f16a9d1b63c9cba9` |

The repeatable runner is
[`run_generated_ecc_env_probe.sh`](../../dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_env_probe.sh).
The separate runtime result is recorded in
[`generated ECC runtime evidence`](../caliptra-bfm-generated-ecc-runtime-20261004/README.md).
