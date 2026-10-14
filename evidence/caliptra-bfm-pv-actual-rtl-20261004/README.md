> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra PCRVault client BFM against actual RTL — 2026-10-04

## Scope

`dv/caliptra_bfm/pv/pv_caliptra_master.sv` is a clean-room, task-based driver
for the actual PCRVault crypto-client pins. It models the RTL contract from
`pv_defines_pkg`: reads are combinational address lookups sampled on the next
clock edge; writes pulse `write_en` through one rising edge; read and write
channels can run concurrently. It rejects unknown and out-of-range requests,
reports response errors, and aborts an in-flight transfer on reset.

The test instantiates the pinned `pv` RTL and the repository's native
32-bit-address/64-bit-data AHB-Lite manager. It checks independent concurrent
PV read/write operations, a client write and read, AHB readback of the same
PCR word, 64-bit lane placement for the PCR control register, the `last` bit on
the terminal dword, out-of-range rejection, and reset-abort reporting. It
passes under IEEE 1800-2017 and 2023 on the local Icarus fork.

The generated PV `read` active task in Caliptra's UVMF output samples the
request fields back into its response struct instead of sampling
`pv_rd_resp`; this driver provides the missing response behavior without
changing those pinned generated sources.

The RTL currently returns zero for both PV client error fields and does not
gate the client write enable with the PCR lock. This test checks the AHB
control-register access and readback but does not claim that a locked PCR
rejects crypto-client writes. That behavior needs separate RTL/spec
reconciliation.

## Reproduce

From the `BFM WORK` clone root:

```sh
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  sh evidence/caliptra-bfm-pv-actual-rtl-20261004/run.sh
```

Expected summary, twice (one per language edition):

```text
PASS: concurrent PV channels, bounds/reset handling, AHB readback, and terminal last
```

This is an IP-level runtime integration with the real PV and generated-register
RTL. It does not compile the generated UVMF environment or run the full
Caliptra SoC.

The runner requires the pinned Caliptra commit and a clean compiled RTL/include
tree before it starts; this prevents the recorded provenance from silently
drifting when `CALIPTRA_ROOT` is overridden.

## Inputs

- Caliptra v2.1.2 commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus/VVP source revision: `246c58e4580f38a130ec08e5a7e6d93f110a5084`.
- The run uses no UVM or external VIP.

| Probe input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/pv/pv_caliptra_master.sv` | `1eed90ac92754dc9f0e1bca6966c95aaf6feb6806fc089a1a0ec734e494bbe07` |
| `tb_caliptra_pv_actual.sv` | `b1dcfbf6a46ad6f8cf122160a6202ea04c6549494392ad84059db3f3c88c3aba` |
| `run.sh` | `9f1de96dc051a9b54f85c50a695f5d5801f13e0c4194b77b5c438d2b872fb38a` |
| `verify.log` | `d9684a66b7d30938f13a575d73c4ba2dcdf4cc7e78e0cec5deb3c70cc98e4469` |
