# Generated ECC BFM compile on published Icarus — 2026-10-09

**Status: blocked before simulation; not qualified.** The existing generated
ECC reset/IRQ probe does not compile under the newest locally cached published
Icarus `main`. No VVP process or UVM test was started.

## Reproduction

From the QD-BFM repository root:

```sh
CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
ECC_RUNTIME_PROBE=reset ECC_IEEE_EDITION=2017 \
ECC_RESET_MONITOR_LOG_DIR=/private/tmp/qd-bfm-checkpoint.H2Ij8x/repo/evidence/caliptra-bfm-generated-ecc-published-20261009 \
ECC_RESET_MONITOR_LOG_PREFIX=published_main_4b3f342_reset \
sh dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh
```

The runner exited 1 during compilation. Icarus reported `syntax error` at the
generated package-qualified, parameterized class proxy declarations in the
input driver and monitor, and the corresponding output driver and monitor;
each was followed by `Invalid module item`. These are declarations such as
`ECC_in_pkg::ECC_in_driver #(...) proxy;` inside the generated interface.
This locates the failure in the simulator's acceptance of generated interface
class handles; it does not indicate an AHB transaction failure. The exact
simulator root cause remains for the Icarus-side workstream. No compatibility
rewrite of those declarations was added to QD-BFM.

The probe used Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and a clean
source archive of published Icarus `main`
`4b3f3424c440aca6af92153b6860a7253b925234`, merged 2026-10-09 at 09:25 UTC.
This was the newest revision in the local `origin/main` cache; GitHub DNS
failed during a live-head lookup, so a newer remote head could not be ruled
out. The Icarus source archive was built separately without changing its
working checkout or branches.

## SHA-256 inputs

| Input | SHA-256 |
| --- | --- |
| Icarus `iverilog` | `00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385` |
| Icarus `vvp` | `f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a` |
| Generated ECC runner | `4d0db7367428907a43e07bc139f2cafc8ddb74847cd62607ba064b9ad272888e` |
| Monitor overlay generator | `6070550509aabf541b3da7947f976e265a27eaefdf84c8079edf9b41d6a9a6f6` |
| Caliptra `ECC_in_driver_bfm.sv` | `ac6594e2ff7bac5a30c2b3def59067099e3e9749e559b23251b99c52e8ecf9dc` |
| Caliptra `ECC_in_monitor_bfm.sv` | `4bdd8631566d578514affb2c7e34ab4706fe45f3f53352bfda26d447297cfaf2` |
| Caliptra `ECC_out_driver_bfm.sv` | `5eaea71fbdedc74794a36400427a9d6732ae48bcb83e7e2ea86603639a5083eb` |
| Caliptra `ECC_out_monitor_bfm.sv` | `360f641ca3f51f1a3c26fb7c47217d7cf80f72a1cb1405e3633540a453e78393` |
