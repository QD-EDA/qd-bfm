> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra ECC AHB UVM smoke — 2026-10-04

## Scope

This run drives the pinned Caliptra `ecc_top` unit through the open native UVM
AHB sequencer, RAL adapter, pin manager, passive monitor, and profile checker.
The UVM sequence writes `1` to the ECC interrupt-enable CSR at `0x804`, reads
it back, and checks the result. The monitor checks the direct sequence and RAL
traffic; the checker and monitor must report zero protocol errors and exactly
four completed transfers. This is unit-level DUT evidence, not a generated
UVMF environment or full Caliptra top-level run.

## Inputs and toolchain

- Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; checkout was clean.
- Icarus/VVP source revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`.
- Installed tools: Icarus Verilog 13.0 (devel), reported build `246c58e4-dirty`.
- Bundled UVM: Accellera 1800.2 UVM 2020.3.1.
- Binary SHA-256:
  - `iverilog`: `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392`
  - `vvp`: `b7e9e2d0b994bdd5e17a2e8033dfe76ca9fafb9ec9fdca35f16a9d1b63c9cba9`

## Reproduction and result

Run from the repository root:

```sh
for edition in 2012 2017 2023; do
  SV_EDITION="$edition" \
    IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
    VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
    dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_uvm_bfm.sh
done
```

All three runs exited 0 and printed:

```text
PASS: Caliptra ECC RTL AHB write/readback through native UVM agent
```

Each UVM report had 0 warnings, 0 errors, and 0 fatals. Icarus emitted a
mixed-timescale warning because the pinned RTL and BFM sources use different
timescale declarations. The runner removes its temporary compile and log files
on exit; this record preserves the command, tool hashes, source hashes, and
observed result rather than a raw transcript.

## Recheck after AHB MVC update (2026-10-05)

The 32-bit ECC profile was rerun after updating the shared AHB command proxy
and monitor. `SV_EDITION=2012` exited 0 and printed the same pass marker, with
zero UVM warnings/errors/fatals. The runner's memory guard observed 75% free
memory against the 70% floor. Current shared AHB source hashes are recorded in
the [AHB MVC follow-up evidence](../caliptra-bfm-ahb-qvip-compat-20261004/README.md).

## Source hashes

| Input | SHA-256 |
| --- | --- |
| `src/ecc/config/ecc_top.vf` | `a1b22f20543ebdc0b732981c96554bd287e98d11236fa5d1860c8819aae95ef2` |
| `dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_uvm_bfm.sh` | `dbd35fd8f4ab08eb79ca3426abf83f5783711804879beb32ed315e678582ce87` |
| `dv/caliptra_bfm/ahb_lite/tests/tb_caliptra_ecc_ahb_uvm_bfm.sv` | `6ca5e1706d48edc046b5eb2b3fbb18881e053624cda16c5d56c1f6ae920fd812` |
| `dv/caliptra_bfm/uvm/ahb_lite_caliptra_uvm_pkg.sv` | `9322009a3aaaffad0f4695cb49ab3753ea98a64865abb27e550f08d73533cab4` |
| `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f` | `3692ba45254bf856a87a8f6ac33c0517e97c7cd17a965f9fc36931f7b209a9e8` |
| `dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_checker.sv` | `4b6db75f620864f1bf28f64a7a945545229220fe7ee89c2df954cbf53cb962d8` |
| `dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_monitor.sv` | `ea35cdc4efc1acc54f0118368b3875e56c8010e6715ebc101472ce85d194cb76` |
| `dv/caliptra_bfm/uvm/ahb_lite_caliptra_pin_monitor_adapter.sv` | `49d32573326b8b978f1935c7c2a0d7fd33f70e00f3ebe04c1e4e55fbaf28733f` |
## Published Icarus replay after runner source-list fix (2026-10-09)

The runner previously listed `ahb_lite_caliptra_checker.sv` explicitly even
though `caliptra_bfm_uvm.f` already includes it, causing a duplicate module
compile error. Commit `8bfcd7e7edace2a905e17b1c6cd6f1ff076da668` removes the
redundant source argument. With that committed runner, the actual ECC RTL AHB
UVM smoke passed in IEEE 2017 and 2023 using clean published Icarus main
`127b887dfdc09283ab0187a2e618421dee3d5dcc`, Caliptra
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and Accellera UVM 2020.3.1.
Each run checked four CSR transfers (two reads and two writes), 12 wait cycles,
and zero AHB protocol errors; UVM reported zero warnings, errors, and fatals.
Icarus emitted only the existing mixed-timescale compile warning.

Reproduce from the QD-BFM repository root:

```sh
for edition in 2017 2023; do
  CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
  SV_EDITION="$edition" \
    sh dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_uvm_bfm.sh
done
```

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/ahb_lite/tests/run_caliptra_ecc_ahb_uvm_bfm.sh` | `a988d54e388ae9fc9b5c5fbafa16d7d1da7f9474ce2f38cda94bf81a0d61c617` |
| Icarus `iverilog` binary | `a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602` |
| Icarus `vvp` binary | `29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca` |

### Coverage counter clarification (2026-10-09)

The reported `pending_wait=0/12 cycles` means zero pending wait-state cycles
out of 12 observed clock cycles. The run had no wait-state cycles; the earlier
summary phrase “12 wait cycles” was a misreading. The transaction and UVM
counts above are unchanged.
