> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra mailbox SRAM subordinate evidence

## Scope

This run exercises the open mailbox SRAM target against the actual pinned
Caliptra `soc_ifc_pkg` request/response structs, using a 16-word test instance
to cover both address boundaries and an out-of-range access.

## Result

Passed under the BFM WORK Icarus build:

```text
PASS: Caliptra mailbox SRAM model covers sync read/write, XOR fault mask, ECC injection, reset retention, and bounds
```

The current implementation verifies zero initialization, registered reads,
full data/ECC writes, deterministic XOR-mask injection, single- and double-bit
ECC injection, reset retention, and read/write bounds checks. This is
component-level evidence; it does not establish full Caliptra-top or generated
UVMF responder qualification.

Replay with:

```sh
IVERILOG_BIN=/path/to/iverilog VVP_BIN=/path/to/vvp \
  sh dv/caliptra_bfm/mailbox/tests/run_caliptra_mbox_sram.sh
```

## Source hashes

| File | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/mailbox/caliptra_mbox_sram_subordinate.sv` | `f1d4be8a09fc37f08f575def715c8591942369bb98bcf50350cee7ab2d1f4d40` |
| `dv/caliptra_bfm/mailbox/tests/tb_caliptra_mbox_sram_subordinate.sv` | `984b887afc5ed0dc790c57081614aba9c8ae58b3b4018916d609757009d0da2c` |
| `dv/caliptra_bfm/mailbox/tests/run_caliptra_mbox_sram.sh` | `c1be2a38858d7d5b0e039be2c7b2cfe36c4cdba3897da50de783a8031b74c383` |
| `dv/caliptra_bfm/caliptra_bfm_caliptra_if.f` | `251b6855298b4387593560497de3d86279502bc5626db364e1bb9746d284ca4b` |
