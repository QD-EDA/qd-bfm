# Caliptra UVM agent reruns on Icarus main — 2026-10-09

These guarded synthetic agent tests were rerun with a clean build of the
locally recorded `iverilog-uvm` `origin/main` revision
`0d8815febc260928e62d5c2ce82b14afd2e38dc3` and Accellera UVM submodule
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. GitHub DNS prevented refreshing
the remote head, so this is the newest locally available published ref, not a
live-verified remote head. The testbenches use synthetic targets; this evidence
does not cover generated UVMF or actual Caliptra RTL.

## Build and binary fingerprints

Built on macOS arm64 from a clean source archive, using Bison 3.8.2, Homebrew
libffi/Z3, `--enable-libveriuser`, and the pinned UVM submodule. The clean
checkout at `/Users/danielellerbrock/projects/iverilog_uvm/iverilog-uvm` was
read only. Icarus reports version `13.0 (devel)` and bundled UVM
`Accellera:1800.2:UVM:2020.3.1`.

- `iverilog`: `603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a`
- `vvp`: `07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c`
- `iverilog-vpi`: `1e393171c4272f92db03541c9c483afb4b9211e01a1476ab01d4890f0e949d83`

## Runs

Commands from the QD repository root:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
sh dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh

IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
sh dv/caliptra_bfm/uvm/tests/run_ahb_lite_uvm_agent.sh
```

| Runner | Result | Coverage / guard |
| --- | --- | --- |
| `run_uvm_agent.sh` | AXI and AAXI compatibility stream passed burst read/write and SLVERR checks; 0 UVM errors, 0 fatals, 2 expected predictor warnings for injected error responses; normal finish at 750000. | Accepted AW/W/B/AR/R = `6/7/6/10/11`; min available memory 7.57 GiB; max process group 0.35 GiB. |
| `run_ahb_lite_uvm_agent.sh` | Transfer clone/compare and keyed stream checks passed scalar, full/partial bursts, and ERROR responses; 0 UVM errors, 0 fatals, 2 expected predictor warnings; normal finish at 690000. | 9 reads and 8 writes of 17 transfers; 30/67 pending wait cycles; min available memory 7.29 GiB; max process group 0.36 GiB. |

Complete guarded logs and SHA-256 values:

- [`axi-agent.log.gz`](axi-agent.log.gz) — compressed artifact SHA-256
  `0263d529c31d5f6b4652a9503c24319761c4f39e99d57330f80ca2cb2e620ac3`;
  uncompressed log SHA-256 `873d124b60da9f706cb9161eb0c392ab26b1f89c079dcf8d3936711c8ef6afb6`.
- [`ahb-agent.log.gz`](ahb-agent.log.gz) — compressed artifact SHA-256
  `de51d3a04cbfb7372a6d8c8cab046a55f4f299965969f4c8cd05e83742a85baa`;
  uncompressed log SHA-256 `5ad616172380d160996d4df56b73efea5968af70613c902052713043bb4c6d8f`.

This confirms these synthetic AXI/AHB agents still run on the newest locally
available Icarus main build. It does not qualify the protocol agents against
Caliptra RTL or close the Phase 3 violation-injection and integration gates.
