> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated Caliptra HMAC runtime probe — 2026-10-05

## Scope and setup

The actual Caliptra `hmac_ctrl` RTL and generated HMAC UVMF input/output
packages, BFMs, environment, and `HMAC_random_test` compiled with the clean-room
`uvmf_lite` base in `BFM WORK`. The generated HDL top has no timescale, so this
probe used a disposable copy with `` `timescale 1ns/1ps `` prepended. The pinned
Caliptra checkout was clean and unchanged.

The generated predictor invokes `python ./test_gen.py`. Its parser slices
OpenSSL output using a fixed offset; with the installed OpenSSL it retained
`stdin)=` before the digest, so `$sscanf` produced a zero expected tag. The
disposable test-generator copy in this evidence bundle extracts the text after
`=`. It changes no HMAC generation logic.

## Build and run

The retained file list is `hmac_generated_full.f`. It selects the actual
generated top plus an HDL wrapper and the full HMAC controller source list.
The captured runtime used:

```sh
/private/tmp/bfm-work-install/bin/iverilog -uvm -g2017 \
  -s hmac_generated_top \
  -f evidence/caliptra-bfm-generated-hmac-runtime-20261005/hmac_generated_full.f \
  -o /private/tmp/hmac-generated-full.vvp

python3 scripts/run_with_memory_pressure_guard.py \
  --max-process-bytes 6442450944 --min-available-bytes 6442450944 \
  --timeout-seconds 300 -- \
  env PATH=/private/tmp/hmac-generated-run-clean/bin:/opt/homebrew/bin:/usr/bin:/bin \
  /private/tmp/bfm-work-install/bin/vvp /private/tmp/hmac-generated-full.vvp \
  +UVM_TESTNAME=HMAC_random_test +UVM_VERBOSITY=UVM_NONE +UVM_NO_RELNOTES
```

For the runtime, `bin/python` in the temporary run directory resolved to
`python3`, and the parser-adjusted copy was installed there as `test_gen.py`.
The `hdl_top_timescale_overlay.sv`, `hmac_generated_top.sv`, and parser-adjusted
`test_gen_openssl3_overlay.py` are the exact temporary sources used. The full
log is in `run.log` (raw artifact omitted from this checkpoint).

## Original monitor result

The original combined source compiles, but its runtime reports **16 scoreboard
mismatches and one leftover actual transaction** (17 UVM errors, zero
fatals). The sequence's `TESTCASE PASSED` message is unconditional. The output
stream is offset by one transaction.

## Reset-event overlay result

The output monitor emits a record when external reset ends, then treats the
shared reset-complete flag as another output event. The hash-guarded
[`hmac_out_monitor_reset_event_overlay.py`](../../docs/conformance/release_overlays/caliptra/hmac_out_monitor_reset_event_overlay.py)
changes the disposable monitor copy to wait for the flag and publish one
record for that event, without first publishing a reset-only record. It leaves
the digest sampling schedule unchanged and does not modify the pinned Caliptra
checkout.

With that overlay, the generated `HMAC_random_test` completes at 441780 ns with
17 predictor operations, **zero UVM warnings, errors, or fatals**, and no
scoreboard mismatch or leftover report. This confirms the one-event offset was
the cause of the original failures; it does not qualify other HMAC sequences
or the full Caliptra top. The exact build/run logs are
`compile-reset-overlay.log` (raw artifact omitted from this checkpoint) and
`run-reset-overlay.log` (raw artifact omitted from this checkpoint); the overlay source, filelist,
and source/output hashes are in [`reset-event-overlay`](reset-event-overlay/).
The successful runtime used a 65% free-memory floor and observed 69% minimum.

## Inputs

- Caliptra v2.1.2: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; checkout clean.
- Icarus/VVP: 13.0 devel, revision `246c58e4580f38a130ec08e5a7e6d93f110a5084`,
  with Accellera UVM 2020.3.1 and the clean-room `uvmf_lite` base.
- Original HMAC `hdl_top.sv` SHA-256:
  `5486f39e88836fed8c3e38fbf10095382efa4045af282d37d9b85cd74e1e0d32`.
- Original `src/hmac/tb/test_gen.py` SHA-256:
  `ea91ed5f5b481e69c8840e3b4f3ac8bfeed37ab0552d070f9ddf7e0d3501399b`.
- `HMAC_predictor.svh` SHA-256:
  `f433948c4d6da3decf497fe40752320cc64b3c5b4fefddaa3821b324dab0bc72`.
- `HMAC_in_driver_bfm.sv` SHA-256:
  `0e8acc0bc973672418acfbb8145a5eb9182559566973b6e85b1102f1b797d9d1`.
- `HMAC_out_monitor_bfm.sv` SHA-256:
  `ec42c64cbb690a8e7fcc63508d03886c301cc73e56c0c974a78fa2a40bbdbb50`.

## Artifact hashes

| Artifact | SHA-256 |
| --- | --- |
| `run.log` | `b72e0b6343c1c82df2b8b88df3e79e703355060bfbb1329c9b7a8c3c9fc3dccf` |
| `compile.log` | `44446700b50a8015e18f06ad8932c351501e0f66fed03b3f2ca8ac9312942850` |
| `hmac_generated_full.f` | `9c7303242b094c3611646bef9f2b56fc1fa45fcd528c6245fcda85ef8ef36cb4` |
| `hdl_top_timescale_overlay.sv` | `ee38433fe3a6020c27c218c0dcd2fd8fe7e60c8ea7641f1cd47ce8cb4f476063` |
| `hmac_generated_top.sv` | `1f426821aabbee154bef67bdf7f270e4190ea50f0dbaaf6fd447def3390e718a` |
| `test_gen_openssl3_overlay.py` | `2d3ae11c4931f9dd57b87f4724fd26eca065e6e304e4ae79583b734931a9fa34` |
| `run-reset-overlay.log` | `4023d63f86956b9f43d56de2ae35be1dee7ea55a68b561577fecd9fc91d92ad0` |
| `compile-reset-overlay.log` | `f599bc434f26cc0d4a24b2e186154653313f5f6770db7a3a16b34b0c4fdfe93d` |
| `reset-event-overlay/manifest.json` | `c7232944622f053883131b7801006ec22b8d57483dc0bc662463afd7171e6ee5` |
| `reset-event-overlay/hmac_generated_overlay.f` | `263bf4692f1eb55df521da55585dbc00392f35f11860d087dc8d42b56eb237ed` |
| `hmac_out_monitor_reset_event_overlay.py` | `6ab93ddcab8b62434c42289755ca0a92d462275fdce780d213d215ec708f364c` |

## Current-state compile check (2026-10-09)

The guarded HMAC runner was checked against the clean source archive for the
newest locally available `iverilog-uvm` `origin/main`,
`197f9baece79e66d25524906fb7b54c9faa8f4e2`, with UVM submodule
`78c06547a2a0a29b3dc9dcafae62b75b2ff61544` and Caliptra
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Compilation stops in the generated
HMAC driver and monitor interfaces at package-qualified parameterized proxy
class handles. The monitor overlay does not change those handles. This is an
Icarus parser blocker; no QD workaround was added and simulation did not start.
GitHub DNS resolution failed, so this local `origin/main` reference could not
be checked against the current remote head. The captured runner output is
[`published-main-197f9ba-compile.log.gz`](published-main-197f9ba-compile.log.gz);
its uncompressed SHA-256 is
`f44fd5d2176c1b1a51b3d1144db194176a5ac61ea3f8607e3a5a114038a8e1a9`.

| Input | SHA-256 or revision |
| --- | --- |
| Icarus source | `197f9baece79e66d25524906fb7b54c9faa8f4e2` |
| `iverilog` | `2588169190d99543c79d8a8c58ff3e75f7e0a9679fa871e895e5c3f15af29ba5` |
| `vvp` | `edbc97b6a9fec8d1425c16d0b1a6b32ad4cbdb0ad609dbfbca155cbc30eb5c6d` |
| HMAC runtime runner | `1741d418e10c8d9a04481501c6d521058d5e95d21b30e5f593d8a35cae1ea709` |

## Current clean published-main compile check (2026-10-10)

The same guarded runner was replayed with clean published Icarus main
`4b3f3424c440aca6af92153b6860a7253b925234`, Accellera UVM 2020.3.1, and clean
Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Compilation still stops
in the generated HMAC input driver/monitor and output driver at the
package-qualified parameterized proxy class declarations; the reset-event
overlay does not alter those declarations. The run did not start simulation,
and no QD source adaptation was made. This is a current published-Icarus
compile diagnostic, not HMAC runtime qualification.

The captured runner output is
[`published-4b3f-hmac-runtime.log`](logs/published-4b3f-hmac-runtime.log).
The matching `iverilog` and `vvp` binary SHA-256 values are
`00a0686a9f0d6962d3e9cd4790464321a608d77efe4db8e50fa02ec7f3f69385` and
`f7b6f7cbb87d60f96914ad1213beab2a359e15cc3a2bcf176190cecb28fdc19a`;
the runner SHA-256 remains
`1741d418e10c8d9a04481501c6d521058d5e95d21b30e5f593d8a35cae1ea709`.
