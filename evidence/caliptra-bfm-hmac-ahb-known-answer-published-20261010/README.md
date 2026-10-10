# Native Caliptra HMAC AHB BFM known-answer smoke

Date: 2026-10-10

This focused smoke connects the native 32-bit AHB manager, profile checker,
and passive monitor directly to Caliptra's pinned `hmac_ctrl` RTL. It writes
the SHA-512 key, padded single-block message, and seed through AHB, starts the
operation, polls status, reads the 512-bit tag, compares the expected digest,
and checks that the controller is neither busy nor in error. The input and
expected tag are the SHA-512 vector used by Caliptra's existing
`hmac_ctrl_tb.sv`; the seed is fixed here for deterministic replay.

| IEEE edition | Result | AHB transfers | BFM protocol errors | HMAC status |
| --- | --- | ---: | ---: | --- |
| 2012 | PASS | 172 | 0 | idle, no error |
| 2017 | PASS | 172 | 0 | idle, no error |
| 2023 | PASS | 172 | 0 | idle, no error |

The existing memory guard reported a maximum process group of 0.03 GiB for
each run. These are unit-level direct-RTL results; they do not exercise the
generated UVMF HMAC environment or qualify the full Caliptra top.

## Reproduction

From the QD-EDA repository root:

```sh
for edition in 2012 2017 2023; do
  CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
  SV_EDITION="$edition" dv/caliptra_bfm/ahb_lite/tests/run_caliptra_hmac_ahb_bfm.sh
done
```

Caliptra source was clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
The simulator binaries came from a clean source archive of published Icarus
`origin/main` commit `4b3f3424c440aca6af92153b6860a7253b925234`; this is the
locally available published revision used for the run.

The separate generated HMAC UVMF runtime still fails to compile on the
package-qualified parameterized proxy declarations with that Icarus revision.
This native unit smoke makes no source workaround for that simulator defect.

## Logs

- [IEEE 2012](logs/sv-2012.log)
- [IEEE 2017](logs/sv-2017.log)
- [IEEE 2023](logs/sv-2023.log)

## SHA-256 inputs

| Input | SHA-256 |
| --- | --- |
| Icarus `iverilog` binary | `00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385` |
| Icarus `vvp` binary | `f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a` |
| HMAC AHB runner | `00284208f8bb35c08d9a01aa433fe10f893987232cd6c8607cca2eb203ac7123` |
| HMAC AHB testbench | `e2bf6652871df76953509a7e030dd5f7821bc7a6e233f690c6ab1e4e26b73e3b` |
| AHB manager | `520933e2b42ba6f2e5e58e1c5be3f48088e50823045c9cdba2c4700e30d57061` |
| AHB checker | `ee3a6f9313dad251568011ac126f30f418de0f2ce15828d0e40dc0f42ffc2c05` |
| AHB monitor | `8aa79664176666801084ce7fe96ac34fe91977845cf7e36573320d5ed80d999a` |
| Caliptra HMAC filelist | `e54231cbedefd6c327e7f770fdfe60fffe8c70a788dce2ec4fa485fd10721dda` |
| Caliptra `hmac_ctrl.sv` | `5d5c34496cd8b57facb8802949901c19423b206ec13bb5662c1f8da6fe2a57d3` |
| Caliptra vector testbench | `cb0b5d82b855b3d951c19a550e0017606a24e1bf4864229f09070795e2470cbd` |
| Each edition log | `7eea3b938f33e244b7f9c8a08539bca5ab1475778fdee527f9b2a4dead90c52d` |

## Current-state rerun through the native UVM agent (2026-10-10)

The same known-answer case now runs through the native active
`ahb_lite_caliptra_agent`, its sequencer/driver, command proxy, and pin monitor
before reaching the pinned HMAC RTL. The test checks all transfer responses,
monitor records, checker/protocol error flags, the full digest, and the final
idle/no-error state.

| IEEE edition | Result | Transfers | UVM warnings/errors/fatals |
| --- | --- | ---: | --- |
| 2012 | PASS | 172 | 0 / 0 / 0 |
| 2017 | PASS | 172 | 0 / 0 / 0 |
| 2023 | PASS | 172 | 0 / 0 / 0 |

The agent monitor counted 110 reads and 62 writes, all 4-byte transfers, with
zero protocol errors. The local memory guard observed 0.36–0.37 GiB peak
process-group RSS. These are local measurements, not Slurm MaxRSS.

Reproduce with the same loop above, setting
`dv/caliptra_bfm/ahb_lite/tests/run_caliptra_hmac_ahb_uvm_bfm.sh` in place of
the direct-manager runner.

Logs: [IEEE 2012](logs/uvm-sv-2012.log),
[IEEE 2017](logs/uvm-sv-2017.log),
[IEEE 2023](logs/uvm-sv-2023.log).

SHA-256: UVM runner
`2bb37855889565b156e65c8d62129472ecf76e41de091fc1744b76769424628d`;
testbench
`aa69fd79b4eae261eeb791844b493f27b983a503e24d9a76cf9b263867f1c3c6`;
logs respectively
`442c8fb9e92b3670284abf058ff59f4cd2e216a5488b9f6dae2cbad48cc73903`,
`eacc83481b1103016bc171e60cde43381209936f2e7b7e641b12e0b41186e5dc`, and
`7eea4c05a673917ab17d137d821b923bf68733afb9fad5614d541ad301d25f78`.
