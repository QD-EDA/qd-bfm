> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated Caliptra status BFM compile probe — 2026-10-04

## Scope

The pinned `cptra_status_pkg` has three generated `$psprintf` calls with an
empty trailing argument. Slang reports the empty argument as an extra format
argument, and Icarus rejects the call. The named overlay removes only those
three empty arguments from disposable copies of the generated configuration,
driver BFM, and monitor BFM sources. It checks both pinned input hashes and
expected patched-output hashes. The Caliptra checkout remains unchanged.

The probe compiles the real status package and instantiates its real status
interface, driver BFM, and monitor BFM under IEEE 2017 and 2023. It uses
`-tnull`; it does not call `run_test`, drive the status protocol, instantiate
the Caliptra DUT, or qualify runtime behavior or coverage.

## Reproduce

From the `BFM WORK` clone root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  sh evidence/caliptra-bfm-generated-status-20261004/run_probe.sh
```

Expected result:

```text
PASS: generated status package, interface, and BFMs elaborate under IEEE 2017 (7 compiler warnings).
PASS: generated status package, interface, and BFMs elaborate under IEEE 2023 (7 compiler warnings).
```

The warnings are generated coverage-stub compile-progress notices. This result
qualifies the package/interface elaboration slice with the source overlay; the
unmodified package still fails on the empty arguments. The control package has
separate instances of the same generator output and is not covered by this
overlay.

The separate [active-agent construction/runtime probe](../caliptra-bfm-generated-status-runtime-20261004/README.md)
uses this same overlay to confirm generated driver and monitor proxy setup.

## Pinned and overlaid file hashes

| Source | Pinned SHA-256 | Overlay SHA-256 |
| --- | --- | --- |
| `src/cptra_status_configuration.svh` | `f0a0f16c52be3b799afa0b5252e833420d3a64a8ebeba759b40541afdda8bd2b` | `8cf93c07590f8984ba312e05cb817e574a689b78cc14dd537bb69bd7066f50f4` |
| `src/cptra_status_driver_bfm.sv` | `70c47e2737dacda24a56c99076be75f919b9d75d95a2174710c39007d6f16311` | `25979b890c6f488077961593006545ce668fc3ce46994e994ff8c28b9c1b0600` |
| `src/cptra_status_monitor_bfm.sv` | `be1b334b043906de3f8b5747ca83cda470498b7aba85397330db9987f59d240a` | `54e50da3b305106085844dab33eb1a114e077595d030df57fa0495a98d98484a` |

The compile-only image was built with Icarus 13.0 devel from revision
`246c58e4580f38a130ec08e5a7e6d93f110a5084`, Accellera UVM 2020.3.1, and the
clean-room `uvmf_base_pkg.sv` SHA-256
`afc5c560036229a6416d788cb9b35a34de434c8fcd5e879722ed917d9a9609c8`.
