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

## Current-state SHA-384 and SHA-512 UVM rerun (2026-10-10)

The native UVM-agent sequence now checks both HMAC modes against Caliptra's
single-block known-answer vectors. SHA-384 writes its 384-bit key into the
shared 512-bit key window with the remaining 128 bits cleared; both modes
compare the full 512-bit tag window, including the zero-padded SHA-384 result.

| IEEE edition | Result | Transfers | UVM warnings/errors/fatals |
| --- | --- | ---: | --- |
| 2012 | PASS | 344 | 0 / 0 / 0 |
| 2017 | PASS | 344 | 0 / 0 / 0 |
| 2023 | PASS | 344 | 0 / 0 / 0 |

The monitor counted 220 reads and 124 writes, all 4-byte transfers, with zero
protocol errors. Each local guarded run observed 0.36–0.37 GiB process-group
RSS. Slurm was unavailable during this run, so these are not scheduler MaxRSS
measurements.

Run the same three-edition loop from the reproduction section with
`dv/caliptra_bfm/ahb_lite/tests/run_caliptra_hmac_ahb_uvm_bfm.sh`.

Logs: [IEEE 2012](logs/uvm-sha384-512-sv-2012.log),
[IEEE 2017](logs/uvm-sha384-512-sv-2017.log),
[IEEE 2023](logs/uvm-sha384-512-sv-2023.log).

SHA-256: UVM runner
`7239b86c4d226c02db912a78f745445bbe5db39fd6f32af12e530247f1fd4bdd`;
testbench
`4d73d7d97572f5273a2007d6c6649684c94c14a42f2c0d41f3fa832ea1014ecc`;
logs respectively
`92ac91263410bbf8d6c699f3518c8bd9c9129ea6b85262a83e3413d896a62050`,
`f090137a7388a3c92a132892e3303e65622ebfffac571a554acccde0ae970213`, and
`ef24e9753acd3730fcf49ef9ec2b58592fdb503e109992ae36a219fcf78121a8`.

## Current-state multi-block continuation rerun (2026-10-10)

The native UVM sequence now also exercises SHA-512 continuation: it writes a
full first block, waits for ready, writes a padded final block, issues `NEXT`,
then compares the complete digest from Caliptra's two-block HMAC vector. The
single-block SHA-384 and SHA-512 cases still run in the same sequence.

| IEEE edition | Result | Transfers | UVM warnings/errors/fatals |
| --- | --- | ---: | --- |
| 2012 | PASS | 612 | 0 / 0 / 0 |
| 2017 | PASS | 612 | 0 / 0 / 0 |
| 2023 | PASS | 612 | 0 / 0 / 0 |

The monitor counted 393 reads and 219 writes, all 4-byte transfers, with zero
protocol errors. The local guard measured 0.36–0.37 GiB peak process-group RSS;
these runs were not submitted through Slurm. Logs:
[IEEE 2012](logs/uvm-sha384-512-init-next-sv-2012.log),
[IEEE 2017](logs/uvm-sha384-512-init-next-sv-2017.log),
[IEEE 2023](logs/uvm-sha384-512-init-next-sv-2023.log).

SHA-256: UVM runner
`9eb9107be6489469f453d2f9c79d0ae5e9bd58031210661d0b404abe618b9eab`;
testbench
`5c41f43457434ccbf725a06ed04f49415d0e47312cf6dc9563ed3041336e537c`;
logs respectively
`7f1ab05aeb35a1f069c1edf3507bc8f0de99ded8db7b68a4f91341ff709ba07d`,
`83c2d50299680e4fd43e0153304c7acdddecf95484bb6ba7dd081aa3724f04c1`, and
`5166290c94646778feff284d46a2f7a2f2aec394d44048f37fff4d8f672a9637`.

## Current-state monitor-driven HMAC RAL prediction (2026-10-10)

The native HMAC UVM test now connects the AHB agent's completed-transfer
stream to `ahb_reg_predictor` with RAL auto-prediction disabled. Its smoke RAL
map includes the 78 HMAC CSR words used by the SHA-384, SHA-512, and two-block
`INIT`/`NEXT` cases. After all three cases, the test checks that the monitor's
final CTRL write updated the register mirror to the zeroize value.

| IEEE edition | Result | Transfers | UVM warnings/errors/fatals |
| --- | --- | ---: | --- |
| 2012 | PASS | 612 | 0 / 0 / 0 |
| 2017 | PASS | 612 | 0 / 0 / 0 |
| 2023 | PASS | 612 | 0 / 0 / 0 |

The monitor counted 393 reads and 219 writes; all were 4-byte transfers with
zero checker or protocol errors. The three runs used the same UVM-enabled
Icarus binaries identified above as clean published Icarus main
`4b3f3424c440aca6af92153b6860a7253b925234`, and Accellera UVM 2020.3.1. The
Caliptra RTL checkout was clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
SSH to Slurm timed out, so these reruns used the local guarded runner. They
validate monitor-driven prediction for this smoke map, not the generated HMAC
RAL model or RAL frontdoor behavior.

Reproduce from the QD-EDA repository root with:

```sh
set -e
for edition in 2012 2017 2023; do
  logfile="evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/logs/uvm-ral-predictor-sv-$edition.log"
  CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
  SV_EDITION="$edition" dv/caliptra_bfm/ahb_lite/tests/run_caliptra_hmac_ahb_uvm_bfm.sh \
    >"$logfile" 2>&1
  gzip -n "$logfile"
done
```

Logs: [IEEE 2012](logs/uvm-ral-predictor-sv-2012.log.gz),
[IEEE 2017](logs/uvm-ral-predictor-sv-2017.log.gz),
[IEEE 2023](logs/uvm-ral-predictor-sv-2023.log.gz).

SHA-256: updated HMAC UVM testbench
`eb82e122f1b29d86263523afaf494c2c2c0373584bf97c11fde57ec82be03783`;
UVM runner
`9eb9107be6489469f453d2f9c79d0ae5e9bd58031210661d0b404abe618b9eab`;
logs respectively
`8ffd998869a8f5f3cae62a8b7024e3e66645d5c2e198b85d43a0912182adc68b`,
`4099f0f12354263a6c3848106357aab938a2376769f936f483ed7b91ffbee71a`, and
`cc2e08b80d900fd807fdab2126c28ef44620743bde1e9b73dd9f67fb75873848`.

## Current-state native-agent RAL frontdoor (2026-10-10)

The test now uses `ahb_lite_caliptra_native_reg_adapter` with the active native
AHB sequencer. After the three HMAC known-answer cases, it writes a distinct
value to key word 0, reads the HMAC status CSR, and writes CTRL zeroize through
UVM RAL. RAL auto-prediction stays disabled; the monitor's completed-transfer
stream predicts each access, and the test checks the key, status, and CTRL
mirrors.

| IEEE edition | Result | Transfers | UVM warnings/errors/fatals |
| --- | --- | ---: | --- |
| 2012 | PASS | 615 | 0 / 0 / 0 |
| 2017 | PASS | 615 | 0 / 0 / 0 |
| 2023 | PASS | 615 | 0 / 0 / 0 |

The monitor counted 394 reads and 221 writes, all 4-byte transfers, with zero
checker or protocol errors. The published Icarus revision, executable hashes,
UVM version, and clean Caliptra revision are the same as the preceding
monitor-prediction rerun. SSH to Slurm timed out, so the local guarded runner
was used. This covers three scalar frontdoor operations through the native
agent; it does not instantiate Caliptra's full generated HMAC RAL model.

Reproduce from the QD-EDA repository root with:

```sh
set -e
for edition in 2012 2017 2023; do
  logfile="evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/logs/uvm-ral-frontdoor-sv-$edition.log"
  CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
  SV_EDITION="$edition" dv/caliptra_bfm/ahb_lite/tests/run_caliptra_hmac_ahb_uvm_bfm.sh \
    >"$logfile" 2>&1
  gzip -n "$logfile"
done
```

Logs: [IEEE 2012](logs/uvm-ral-frontdoor-sv-2012.log.gz),
[IEEE 2017](logs/uvm-ral-frontdoor-sv-2017.log.gz),
[IEEE 2023](logs/uvm-ral-frontdoor-sv-2023.log.gz).

SHA-256: HMAC UVM testbench
`89808dea30c0e653396272de0ab83c0b6e00195ee5082179c19c8f86dc08e62e`;
AHB UVM package (including the native adapter)
`6240666058c8fa12dafef13435648ae7880843cfef8519ae7d203079b101c7fa`;
runner
`9eb9107be6489469f453d2f9c79d0ae5e9bd58031210661d0b404abe618b9eab`;
logs respectively
`5ccfca3ff33dfa0167fe9f0c36df800907f768ee050045a174993b4f9f59640e`,
`8184a59a9a70c0331c79e483c659a06313ed68fcaff7a594b94d5355bc0647f0`, and
`13421e2507d7dfbfabd178cc49efe49ba171b033324462317ee16474cb1939f7`.

## Current-state native RAL adapter lane and status checks (2026-10-10)

The HMAC UVM test now directly checks the native adapter's conversion helpers
in addition to the full-word frontdoor run above. With a 32-bit bus, it checks
that a halfword write at byte lane 2 and a byte write at lane 3 are packed
into the upper bus lanes, and that a successful halfword read is unpacked with
the expected byte enables. Native responses marked as AHB ERROR or aborted
must map to `UVM_NOT_OK`. These conversion checks call the adapter directly;
the HMAC RTL frontdoor accesses remain full-word transactions.

| IEEE edition | Result | HMAC transfers | UVM warnings/errors/fatals |
| --- | --- | ---: | --- |
| 2012 | PASS | 615 | 0 / 0 / 0 |
| 2017 | PASS | 615 | 0 / 0 / 0 |
| 2023 | PASS | 615 | 0 / 0 / 0 |

The checks pass on clean published Icarus `4b3f3424c440aca6af92153b6860a7253b925234`
with the same UVM and Caliptra inputs as the preceding section. Slurm SSH was
unavailable, so the repository's guarded local runner was used.

Reproduce from the QD-EDA repository root:

```sh
set -e
for edition in 2012 2017 2023; do
  logfile="evidence/caliptra-bfm-hmac-ahb-known-answer-published-20261010/logs/uvm-ral-adapter-edge-sv-$edition.log"
  CALIPTRA_ROOT=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
  SV_EDITION="$edition" dv/caliptra_bfm/ahb_lite/tests/run_caliptra_hmac_ahb_uvm_bfm.sh \
    >"$logfile" 2>&1
  gzip -n "$logfile"
done
```

Logs: [IEEE 2012](logs/uvm-ral-adapter-edge-sv-2012.log.gz),
[IEEE 2017](logs/uvm-ral-adapter-edge-sv-2017.log.gz),
[IEEE 2023](logs/uvm-ral-adapter-edge-sv-2023.log.gz).

SHA-256: HMAC UVM testbench
`d681d60ff2e9b4ce1f54b496a2876f5e09d80585b088756729a3769b3c230188`;
logs respectively
`f9e4e11017160b00874b14f2d3861113226825929195c74313e456c803d0019f`,
`cfe86f99618ec67f9e4f72367a7d4349f443ec368e7fe29928106ad90aebeb3d`, and
`ea2bc74574b88d2612832860af35e070e8de55da7fbe2d34fcde0a39eb3f397a`.

## Latest published-main recheck — 2026-10-10

The complete SHA-384, SHA-512, and `INIT`/`NEXT` multi-block known-answer
sequence passes again through the native AHB UVM agent under IEEE 2017 on
published Icarus main `127b887dfdc09283ab0187a2e618421dee3d5dcc`. It checks
615 AHB transfers and both full tags, with zero UVM warnings, errors, or
fatals. Caliptra RTL is clean at
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; tested QD inputs are unchanged at
`06d4e2c2fd3f105432d987367102823c36d55def`.

Icarus/VVP executable SHA-256 values are
`a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602` and
`29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca`. The
current QD runner, testbench, AHB UVM package, and filelist hashes are
`9eb9107be6489469f453d2f9c79d0ae5e9bd58031210661d0b404abe618b9eab`,
`d681d60ff2e9b4ce1f54b496a2876f5e09d80585b088756729a3769b3c230188`,
`6240666058c8fa12dafef13435648ae7880843cfef8519ae7d203079b101c7fa`, and
`afa63b20041ebef82ff585b449c06cfd208ddc95e8ba2bfd18396fc6ddd931c4`.
