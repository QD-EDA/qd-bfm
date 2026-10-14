> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# PCRVault UVM BFM against actual RTL — 2026-10-04

## Scope

This smoke connects the native `pv_caliptra_uvm_agent` to Caliptra's pinned
PCRVault `pv` RTL. A UVM sequence writes and reads every dword offset 0 through
11 of PCR entry 1 using distinct data patterns. It checks the driver's
responses, terminal `last` on offset 11, and the UVM monitor's 24
write/read completion records. It also checks UVM rejection of offset 12 and
that each successful write item retains its payload. The same UVM driver
reports a write interrupted by reset as an error without hanging; the aborted
operation is not counted as a successful completion.
The proxy uses the same task-based
`pv_caliptra_master` covered by the direct actual-RTL probe, so request bounds,
reset-abort behavior, and response sampling remain in that pin driver.

The monitor watches the proxy's completed command boundary and publishes the
response the BFM sampled from the DUT. PV reads have no request-valid signal,
so this is not an independent passive raw-pin request monitor. This is a
PCRVault IP-level UVM integration, not a generated UVMF run or full Caliptra
SoC simulation. The lower-level direct probe also covers concurrent read/write
tasks, invalid offsets, reset abort, `last`, and AHB readback.

## Reproduce

From the `BFM WORK` clone root, with the pinned Caliptra checkout adjacent:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-pv-uvm-actual-rtl-20261004/run.sh
```

The runner requires Caliptra commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
and checks that the compiled RTL/include inputs are clean. It uses the local
Icarus fork's `-uvm` support and passes with zero UVM warnings, errors, or
fatals. The captured run is in `verify.log`.

## Inputs

- Caliptra v2.1.2 commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus/VVP source revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`.
- UVM: Accellera 1800.2 UVM 2020.3.1 bundled with the local fork.

| Probe input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvm/pv_caliptra_master_cmd_if.sv` | `1a6e15adda0fbfbc8d8d1dd9be375c3258d338f29af7307457f158b4d5399948` |
| `dv/caliptra_bfm/uvm/pv_caliptra_uvm_pkg.sv` | `d48067022b0e583fca0cc04c16fd3dc251cc38c71b1a6f5f3971cb65f8484294` |
| `dv/caliptra_bfm/uvm/pv_caliptra_uvm_master_proxy.sv` | `b052d56137d112519113ec5f8b2d6c618019553a141611841bc55fc574019122` |
| `tb_caliptra_pv_uvm_actual.sv` | `bfd9ec8b59e31596b4dc86411642e310f1ded09101b08970b4b9f6c06fcf99d4` |
| `run.sh` | `1f969d051a3c6c84a4ba08911c1c6f56609263338db461c92f5a51e548491731` |
| `verify.log` | `cbf70dcc5788690e1846649e5cb53100020c55fae937d6a12f659289a40944ea` |
