# UVMF-lite published-Icarus check — 2026-10-09

Focused UVMF-lite scoreboard and generated-style active/passive agent smokes
passed using a clean source archive of published Icarus main
`127b887dfdc09283ab0187a2e618421dee3d5dcc`. The installed UVM reports
Accellera UVM 2020.3.1 (pinned UVM Core `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`).
The `iverilog` and `vvp` binaries were built from that archive; source fetch
to confirm whether upstream has a newer main revision failed because the
host could not resolve `github.com`. Therefore this records the latest
locally available published source, not a claim about upstream's present head.

Commands, run sequentially with the binary paths above:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_scoreboard.sh

IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_agent.sh
```

Both runners passed in IEEE 2017 and 2023. The scoreboard smoke intentionally
reports four UVM errors: one in-order mismatch, one out-of-order mismatch, and
one leftover in each direction; it reports zero fatals. The agent smoke's
normal run reports zero errors/fatals, and its injected mismatch control
reports exactly one error and zero fatals in each edition. These are isolated
UVMF-lite checks; they do not run a Caliptra generated environment or qualify
Caliptra traffic.

SHA-256 fingerprints:

```text
a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602  iverilog
29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca  vvp
1b2050125dc7012e381df6b80f0e4d10f38407c4691be9caffbb77eaa0d14939  dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv
ba86f1323cfc88298665154a4176f7d094c8f12af1971089ece859adcefc98bc  dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv
16e2a7a3c23b0cd7d84872716fc21f7d5436c5ed9b38c4cb082412223bd08c49  dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_scoreboard.sv
831f2e48dbd8f60347feb11bfdab254e9004279b7dc7ea5cabc74601ad8cb584  dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_scoreboard.sh
721d4b8c197a8ec7562c25cb1cb0a2e28aa0cde63b74880d3c61061790f0110b  dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_agent.sv
efa7e131492d694d36e4a0e0195070dffdd4550564b3fc081837b85789446f0d  dv/caliptra_bfm/uvmf_lite/tests/run_uvmf_agent.sh
```
