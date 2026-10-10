# UVMF transaction field recording — 2026-10-10

The focused transaction test exercises both the base's explicit derived
`do_record()` hook and generated-style `uvm_field_int` automation. It verifies
transaction-key copying, automatic copying of the derived field, and text
transaction records containing `start_time`, `end_time`, `payload`, and
`generated_payload`. The test also confirms that `convert2string()` output is
not serialized.

| IEEE edition | Result |
| ---: | --- |
| 2017 | PASS |
| 2023 | PASS |

Reproduce from the QD-BFM root:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
  dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_transaction_key.sh
```

The run exited zero and emitted the two pass lines in
[`runner-summary.txt`](logs/runner-summary.txt). The clean published Icarus
source revision is `127b887dfdc09283ab0187a2e618421dee3d5dcc`, with Accellera
UVM 2020.3.1. The installed executable fingerprints match the prior
[published UVMF-lite evidence](../caliptra-bfm-uvmf-lite-published-20261009/README.md).
This revision is published and clean; this check does not claim it is the
latest cached `origin/main` revision (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`).

QD source commit: `5e81c79dd19fe1dfe0ed196701770ec3ac0d1226`.

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv` | `1b2050125dc7012e381df6b80f0e4d10f38407c4691be9caffbb77eaa0d14939` |
| `dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_transaction_key.sv` | `026735361b9bf78ea2313b8ecc57044d026ce2ba0c442af6e8e6fda506c3095a` |
| `dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_transaction_key.sh` | `b5432c23f96146a3c32380ef65cbdb74dd8013b9411ab34bc9ff8dc1e52ff8e0` |
| Icarus `iverilog` | `a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602` |
| Icarus `vvp` | `29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca` |

This validates the generic recorder for one integer field and the base
timestamp fields. Caliptra-generated transaction layouts and other field types
remain unverified; this is not full UVMF qualification.
