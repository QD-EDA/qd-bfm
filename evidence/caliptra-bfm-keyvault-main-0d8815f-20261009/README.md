# Generated KeyVault four-beat AHB check on latest published Icarus — 2026-10-09

The current remote `iverilog-uvm` `main` head was confirmed with
`git ls-remote` as `0d8815febc260928e62d5c2ce82b14afd2e38dc3`. The test used
the existing clean build for that published revision, with Accellera UVM
submodule `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. Caliptra was clean at
v2.1.2 commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; the QD BFM source
was at commit `756ef099be1889dc915b804e73cc29c7d579f795`.

The guarded `--runtime-ahb-burst-smoke` probe stopped during IEEE 2017
compilation, before VVP started. The remaining parse errors are in the
generated package-qualified proxy declarations:

- `kv_read_driver_bfm.sv:136` and `:138`;
- temporary overlay `kv_read_monitor_bfm.sv:98` and `:101`;
- `kv_write_driver_bfm.sv:134` and `:137`;
- `kv_write_monitor_bfm.sv:109` and `:112`.

No QD workaround was added for this Icarus parser failure. Earlier dirty-build
burst evidence remains diagnostic; this published-main compile result does not
establish KeyVault runtime behavior or qualification.

Command from the QD repository root:

```sh
CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
CALIPTRA_BFM_RUNTIME_TIMEOUT_SECONDS=300 \
CALIPTRA_BFM_SUMMARY_LOG=/private/tmp/keyvault-main-0d8815f-summary.log \
sh evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.sh \
  --runtime-ahb-burst-smoke
```

The memory guard observed 7.24 GiB minimum available and 0.08 GiB maximum
process-group RSS. The test runner is
`evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.py` (SHA-256
`63d409a1a831c55c9f8469d0acb357bd061634f292baa05758cc588e36715494`); the
temporary-source overlay helper is
`docs/conformance/release_overlays/caliptra/keyvault_generated_bfm_iverilog_overlay.py`
(SHA-256 `9694ef56fc337dad992c34697c603da82af12cfb83a9e888e05dc8006820d29e`).
The simulator binaries were fingerprinted as `iverilog`
`603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a` and
`vvp` `07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c`.
