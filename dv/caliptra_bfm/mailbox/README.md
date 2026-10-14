# Caliptra mailbox SRAM subordinate

[`caliptra_mbox_sram_subordinate.sv`](caliptra_mbox_sram_subordinate.sv) is a
bounded synchronous target for Caliptra's `soc_ifc_pkg` mailbox SRAM request
and response structs. Include it through
[`../caliptra_bfm_caliptra_if.f`](../caliptra_bfm_caliptra_if.f), after
`soc_ifc_pkg.sv`.

Each accepted request is sampled on a rising edge when `req.cs` is high. A
write stores the complete 32-bit data plus 7-bit ECC value. A read updates the
registered response after that edge. The default depth is
`CPTRA_MBOX_DEPTH`; memory starts at zero and survives reset, while reset
clears the response register and error pulse. `INIT_FILE` can load packed
39-bit words with `$readmemh`, and `ZERO_INIT` controls the initial clear.

`access_error` pulses for unknown request controls or an address outside the
configured depth. An out-of-range read returns X. Setting
`ENABLE_WRITE_XOR_MASK` applies the packed `write_xor_mask` to each stored
word, allowing deterministic data or ECC bit-flip injection; leave the mask at
zero for normal traffic. `ENABLE_ECC_INJECTION` interprets
`inject_ecc_error[0]` as one flipped bit and `[1]` as two flipped bits. It
chooses a stable address-derived mask across the data and ECC fields; double
bit mode takes precedence if both flags are set. The `load_word` and `peek_word`
tasks support testbench preload and inspection.

The model stores the ECC bits supplied on writes; it does not generate or
correct ECC. With `ZERO_INIT=1` and no `INIT_FILE`, unwritten words read as
zero without a depth-wide initialization sweep; writes and `load_word` mark
words that contain stored data. File-backed initialization keeps eager
zero-fill behavior for partial files. It is a pin-level memory target, separate
from the generated UVMF responder agent. The opt-in generated SoC-IFC top
attachment passes a four-word host-to-SRAM probe through `--open-mbox-target`.
Single- and double-bit injection from the generated mailbox agent configuration
also pass, including one-shot clearing and stored-data checks. Firmware response
handling, the full command/status handshake, and ECC syndrome handling remain
unqualified. See the
[generated-runtime evidence](../../../evidence/caliptra-bfm-soc-ifc-generated-env-runtime-20261005/README.md).
The disposable top overlay promotes the target's `access_error` pulse to a
reset-gated `$fatal`, so invalid or unknown SRAM requests fail directly.
The generated driver overlay synchronizes the live UVM injection flags at the
falling clock edge. The local mask intentionally does not match the sequence's
randomized bit positions; it preserves the requested single- or double-bit
error class.
Run the actual-Caliptra-type component regression with:

```sh
sh dv/caliptra_bfm/mailbox/tests/run_caliptra_mbox_sram.sh
```

The component-level result and source hashes are recorded in
[`mailbox SRAM evidence`](../../../evidence/caliptra-bfm-mbox-sram-20261005/README.md).
