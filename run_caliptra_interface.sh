#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
caliptra=$(cd "${1:?usage: run_caliptra_interface.sh CALIPTRA_ROOT EVIDENCE_DIR}" && pwd)
mkdir -p "${2:?provide an evidence output directory}"
out=$(cd "$2" && pwd)
pin=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
if [[ $(git -C "$caliptra" rev-parse HEAD) != "$pin" ]] ||
   [[ -n $(git -C "$caliptra" status --porcelain) ]]; then
  echo 'ERROR: expected clean Caliptra v2.1.2 pinned checkout' >&2
  exit 1
fi
verilator --version | tee "$out/version.log"
sources=("$caliptra/src/axi/rtl/axi_pkg.sv" "$caliptra/src/axi/rtl/axi_if.sv"
  qd_axi4_single_master.sv qd_caliptra_axi_single_master.sv tb_caliptra_axi_if.sv)
shasum -a 256 "${sources[@]}" > "$out/inputs.sha256"
warnings=0
for config in 32-8 64-1 mismatch; do
  params=(-GDW=32 -GIW=8)
  if [[ $config == 64-1 ]]; then params=(-GDW=64 -GIW=1); fi
  if [[ $config == mismatch ]]; then params+=(-GIF_IW=1); fi
  # Continue compilation solely to collect behavioral evidence. Every warning
  # remains printed/archived and makes this overall pilot exit nonzero below.
  command=(verilator --binary --timing -Wno-fatal --top-module tb_caliptra_axi_if
    --timescale 1ns/1ps --Mdir "$out/obj-$config" "${params[@]}" "${sources[@]}")
  printf '%q ' "${command[@]}" > "$out/command-$config.txt"
  printf '\n' >> "$out/command-$config.txt"
  if ! "${command[@]}" > "$out/build-$config.log" 2>&1; then
    cat "$out/build-$config.log"
    exit 1
  fi
  cat "$out/build-$config.log"
  # Diagnostics from the intentionally invalid width configuration are retained
  # as negative-test evidence, not treated as diagnostics on supported inputs.
  if [[ $config != mismatch ]] && grep -q '^%Warning' "$out/build-$config.log"; then warnings=1; fi
  sim="$out/obj-$config/Vtb_caliptra_axi_if"
  if [[ $config == mismatch ]]; then
    if "$sim" > "$out/run-$config.log" 2>&1; then exit 1; fi
    grep -q 'Caliptra adapter/interface width mismatch' "$out/run-$config.log"
    if grep -q '^PASS:' "$out/run-$config.log"; then exit 1; fi
  else
    "$sim" | tee "$out/run-$config.log"
    grep -q '^PASS: Caliptra interface mapping' "$out/run-$config.log"
    if "$sim" +BAD_RID > "$out/bad-rid-$config.log" 2>&1; then exit 1; fi
    grep -q 'AXI R ID mismatch' "$out/bad-rid-$config.log"
    if grep -q '^PASS:' "$out/bad-rid-$config.log"; then exit 1; fi
  fi
done
if [[ $warnings == 1 ]]; then
  echo 'UNKNOWN: behavioral checks completed; compiler diagnostics prevent a clean pilot'
  exit 2
fi
echo 'PASS: interface pilot (not Caliptra RTL or DV qualification)'
