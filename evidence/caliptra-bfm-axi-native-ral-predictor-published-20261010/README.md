# Native AXI RAL prediction — 2026-10-10

The AXI UVM agent runner passed with monitor-based prediction enabled for its
default CSR map. The UVM adapter handles the driver's frontdoor transfer and
the monitor's completed, single-beat 32-bit transaction. The test checks that
successful write and read observations update/preserve the CSR mirror, while
an injected SLVERR returns `UVM_NOT_OK` and leaves the prior mirror value
unchanged.

| Check | Result |
| --- | --- |
| Native AXI RAL write mirror update | PASS |
| Native AXI RAL read mirror update | PASS |
| Injected SLVERR preserves mirror | PASS |
| Runner exit | 0 |
| UVM errors / fatals | 0 / 0 |
| UVM warnings | 4 expected `PREDICT_NOK` skips from the two predictors observing failed reads |

Reproduce from the QD-BFM repository root:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
  dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh
```

The run used published, clean Icarus source revision
`127b887dfdc09283ab0187a2e618421dee3d5dcc` and Accellera UVM 2020.3.1. The
installed executable fingerprints match the published-Icarus evidence linked
below. This records that revision; it does not claim the later cached
`origin/main` revision `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` was installed
or tested.

The QD checkout was based on commit `01f9d77b51ae8faad28e2643c519ab9e7cc6f223`
and had unrelated dirty files. The directly modified inputs are fingerprinted
here rather than representing the whole checkout as clean. Full guarded-runner
output is in [`logs/runner-summary.txt`](logs/runner-summary.txt).

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvm/axi4_caliptra_uvm_pkg.sv` | `e27788ea0315583be5fc140cc3f87831cf3b60341cdf49f001b216f7f4158cd8` |
| `dv/caliptra_bfm/uvm/tests/tb_axi4_caliptra_uvm_agent.sv` | `1c04b7ce6bcbfa9050342d5c55883ff180c38b8bb2ea8cec7f3b240c7de52684` |
| `dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh` | `f3fed3f65ec424ef03d25526d673a3ab599eab2698d1fa6671e947fbbe02f404` |
| `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f` | `afa63b20041ebef82ff585b449c06cfd208ddc95e8ba2bfd18396fc6ddd931c4` |
| Icarus `iverilog` | `a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602` |
| Icarus `vvp` | `29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca` |

This is synthetic AXI-agent evidence for the mapped CSR path. It is not a
Caliptra DUT regression or UVMF qualification.

## Adapter decode follow-up — 2026-10-10

The same guarded runner now includes direct self-checks of monitor-record
conversion: write data and partial WSTRB with AWUSER, read data with ARUSER,
EXOKAY acceptance, SLVERR and protocol-error rejection, and fail-closed
rejection of multi-beat items by the scalar RAL adapter. The full agent smoke
still exits zero with zero UVM errors/fatals and four expected predictor skips.
The appended log is [`adapter-probes-runner.log`](logs/adapter-probes-runner.log).

This follow-up ran from a working tree based on QD commit
`81b0c150d4f740eecca8b23d4f984909ae440d37`; the directly edited testbench was
fingerprinted below. The prior run's hashes above remain unchanged.

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvm/tests/tb_axi4_caliptra_uvm_agent.sv` | `351dc9fbb3c8149cb7c827803b6e462d76374bacb8769e4cb4716d1f8ed09e32` |
| Icarus `iverilog` | `a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602` |
| Icarus `vvp` | `29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca` |
