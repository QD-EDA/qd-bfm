# Generated SoC-IFC on published Icarus — 2026-10-09

The combined generated SoC-IFC/AAXI/AHB runtime command was checked against a
clean source archive of published Icarus main
`127b887dfdc09283ab0187a2e618421dee3d5dcc` and clean Caliptra
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Compilation stopped before VVP
started. Icarus reported syntax errors and unsupported-bin diagnostics while
parsing generated mailbox and SoC-IFC coverage declarations. The memory-guarded
command returned status 47; no bus transactions or scoreboard result were
produced. No simulator, Caliptra, or QD compatibility source was changed to
work around this failure.

The 2026-10-08 dirty-Icarus pass remains historical diagnostic evidence; this
published-source compile failure does not rewrite that result. It also means
the generated SoC-IFC combined runtime has not been demonstrated on this
published Icarus revision.

Command:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
CALIPTRA_BFM_RUNTIME_LOG=/private/tmp/qd-bfm-soc-ifc-published-127b887.log \
CALIPTRA_BFM_RUNTIME_HEARTBEAT_LOG=/private/tmp/qd-bfm-soc-ifc-published-127b887-heartbeat.log \
python3 evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py \
  --caliptra-root /Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  --generated-environment-runtime --generated-axi-user-init \
  --generated-ahb-mbox-payload --generated-axi-user-reject-probe
```

SHA-256 fingerprints:

```text
a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602  iverilog
25feffc3052d79be329b6d84355d1ceac73c3031c29643242a8398151023f5c0  evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py
afa63b20041ebef82ff585b449c06cfd208ddc95e8ba2bfd18396fc6ddd931c4  dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f
974af3660d68930f4cd83704f38ffcc560eeffcefedd25ba0a55e437331dc6b3  Caliptra src/soc_ifc/rtl/mbox_csr_covergroups.svh
dd755ccfb21f8188ce4903dabd170808d1156ad0dd314867beb45f2f7d064d65  Caliptra src/soc_ifc/rtl/soc_ifc_reg_covergroups.svh
```
