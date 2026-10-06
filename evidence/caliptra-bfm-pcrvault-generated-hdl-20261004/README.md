> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated PCRVault HDL-top elaboration with open AHB replacement — 2026-10-04

## Scope

The runner elaborates Caliptra's actual generated PCRVault `hdl_top.sv`, all
three generated reset/write/read packages and BFM interfaces, the real `pv`
RTL, and the repository's clean-room `hdl_qvip_ahb_lite_slave` replacement.
The custom AHB replacement retains the hierarchy and pin names consumed by
the generated top. The compile passes with `-tnull` under IEEE 1800-2017 and
2023.

The compile needs an empty `pcrvault_cov_bind` module because this probe does
not compile coverage properties. Icarus also rejects three trailing empty
`$psprintf` arguments and rejects the generated initiator-modport connection
for drivers that retain conditional responder assignments. The run uses the
hash-guarded, temporary
[PCRVault overlay helper](../../docs/conformance/release_overlays/caliptra/pcrvault_generated_bfm_iverilog_overlay.py)
to remove only those empty arguments and connect the generic driver BFMs to
the complete interfaces. The pinned Caliptra checkout remains unchanged. The
clean-room `uvmf_base_pkg_hdl` exports the generated HDL-top config-db key
`UVMF_VIRTUAL_INTERFACES`.

The runner requires Caliptra commit
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and a clean worktree for every
compiled Caliptra source/include subtree. It rejects a different revision or
local edits before applying the overlay, so the recorded PASS cannot silently
come from changed PV RTL or generated environment sources.

Both editions elaborate with 45 warnings, mainly from Icarus's generated
coverage stubs and generated code that is outside this compile probe. The
probe does not run `hvl_top`, sequences, or functional coverage;
`-tnull` is static compile/elaboration evidence. The separate
[generated PCRVault UVMF runtime](../caliptra-bfm-pv-generated-uvmf-20261004/README.md)
runs the generated test with the clean-room UVMF/QVIP layer. The independent
[actual RTL runtime](../caliptra-bfm-pv-actual-rtl-20261004/README.md) drives
the native PV client and AHB paths against the actual DUT.

## Reproduce

From the `BFM WORK` clone root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  sh evidence/caliptra-bfm-pcrvault-generated-hdl-20261004/run.sh
```

## Source pins

- Caliptra v2.1.2 commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`.
- Original-source SHA-256 checks and exact replacement anchors are in the
  overlay helper; it exits if any source differs.

| Probe input | SHA-256 |
| --- | --- |
| `run.sh` | `0255e45a24fa91d1255068f316e7f526f55065b8e874cc1f884b9ef337bdd976` |
| `verify.log` | `9012ab0a27a82f870f8061baacf43c448c53f14f60ede2c701f4f72df3a4647b` |
| overlay helper | `eafff8df6a3aa78d89832c7b901ba7158cecf56b6d12e826251519d05e38658d` |
| clean-room `uvmf_base_pkg_hdl.sv` | `ba86f1323cfc88298665154a4176f7d094c8f12af1971089ece859adcefc98bc` |
| clean-room `uvmf_base_pkg.sv` | `e7a5e50cce0eefcd44162ed1747388f478af04d66d0dc08cd5b990682672d9d9` |
