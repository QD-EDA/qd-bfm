> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Generated Caliptra SHA-512 runtime — 2026-10-05

## Scope

The pinned Caliptra SHA-512 `hdl_top` and `SHA512_random_test` compiled with
the clean-room `uvmf_lite` base and ran against the actual `sha512_ctrl` RTL.
The generated input driver reads the SHA-512 `.rsp` vectors from the runtime
working directory. The two-line `hdl_top_timescale_overlay.sv` adds the
required `1ns/1ps` timescale and includes the upstream top without copying it.
The Caliptra checkout stayed clean.

The stock generated output monitor publishes a zero-valued record after reset
before waiting for a real digest read. That record has no matching predictor
item and shifts the scoreboard streams: the stock run has 12 mismatches and
one leftover actual item, although the generated sequence unconditionally
prints `TESTCASE PASSED`. The hash-guarded
[`sha512_out_monitor_reset_event_overlay.py`](../../docs/conformance/release_overlays/caliptra/sha512_out_monitor_reset_event_overlay.py)
changes a disposable copy to wait through reset and then capture the next
flagged digest in that same monitor call. It leaves digest sampling unchanged.
The resulting run reports 13 expected and 13 observed transactions, all
matched, with no pending items.

## Build and run

Run from the repository root. `sha512_generated_full.f` keeps the original
generated monitor path; the overlay helper writes a temporary replacement and
an overlay filelist outside the Caliptra checkout.

```sh
REPO_ROOT="$PWD"
CALIPTRA_ROOT="$REPO_ROOT/../caliptra-rtl"
EVIDENCE_DIR="$REPO_ROOT/evidence/caliptra-bfm-generated-sha512-runtime-20261005"
RUN_DIR=/private/tmp/sha512-final-run
mkdir -p "$RUN_DIR"
cp "$CALIPTRA_ROOT"/src/sha512/tb/vectors/SHA*.rsp "$RUN_DIR/"

python3 docs/conformance/release_overlays/caliptra/sha512_out_monitor_reset_event_overlay.py \
  --caliptra-root "$CALIPTRA_ROOT" \
  --filelist "$EVIDENCE_DIR/sha512_generated_full.f" \
  --output-dir "$RUN_DIR/reset-event-overlay" \
  --manifest "$EVIDENCE_DIR/reset-event-overlay/manifest.json"

/private/tmp/bfm-work-install/bin/iverilog -uvm -g2017 \
  -s sha512_generated_top \
  -f "$RUN_DIR/reset-event-overlay/sha512_generated_overlay.f" \
  -o "$RUN_DIR/sha512_generated_overlay.vvp" \
  > "$EVIDENCE_DIR/compile.log" 2>&1

(cd "$RUN_DIR" && python3 "$REPO_ROOT/scripts/run_with_memory_pressure_guard.py" \
  --max-process-bytes 6442450944 --min-available-bytes 6442450944 \
  --timeout-seconds 600 \
  --log "$EVIDENCE_DIR/run.log" -- \
  env PATH=/opt/homebrew/bin:/usr/bin:/bin \
  /private/tmp/bfm-work-install/bin/vvp "$RUN_DIR/sha512_generated_overlay.vvp" \
  +UVM_TESTNAME=SHA512_random_test +UVM_VERBOSITY=UVM_LOW +UVM_NO_RELNOTES \
  > "$EVIDENCE_DIR/memory_guard.log" 2>&1)
```

## Result and limits

The runtime ended at 604,960 ns. The scoreboard summary is
`expected=13 actual=13; matched=13 mismatched=0; pending expected=0 actual=0`.
UVM reported zero warnings, errors, and fatals. The 600-second guard used a
50% free-memory floor; the run observed 64% before launch and 62% minimum.

The compile emitted seven `eval_object_select` warnings from the clean-room
base and generated coverage-stub warnings. This result qualifies this bounded
generated SHA-512 test path only; it does not qualify the full UVMF API,
functional coverage, other SHA-512 sequences, or Caliptra top-level DV. The
runtime was built with Icarus/VVP 13.0-devel at revision
`246c58e4580f38a130ec08e5a7e6d93f110a5084` and Caliptra v2.1.2
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

The retained stock-monitor log records the baseline mismatch. The overlay
manifest and hashes pin the source and transformed monitor; the transformed
vendor-generated file itself is not retained.

## Evidence hashes

| Artifact | SHA-256 |
| --- | --- |
| `sha512_generated_full.f` | `fcc7c718de6915a0fe00af582f830de12ef96c4b6d008a9811c9de7734002a22` |
| `compile.log` | `ea59cb6533f43f7b8380f7b051c80c519e4f9bec2b6c7175900abf38d7eefe95` |
| `run.log` | `88a76e27a31f3159f22510bf6cb0932b727939e86d833529494e10a74ce0637d` |
| `run-original-monitor.log` | `7e0b1955081da3ef6f1b72136d0d7e3a3784eb530e4fef6bedc65cb11850d79d` |
| `memory_guard.log` | `25c17eef3e0aacf49d34d9f309d9263fbbe9093a41e7adcad9dfcc5d7fad111e` |
| `reset-event-overlay/manifest.json` | `872d3154072fad5a4621910773f24ae9ce246518a440774f1e2960dc6e21e9b7` |
