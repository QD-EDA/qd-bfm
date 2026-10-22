#!/bin/bash
set -euo pipefail

IVL=/home/dsell/toolchains/iverilog-uvm-main-8c95b5cc10fc83d15b47e0364d2d7b4a2e12cac1/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-main-8c95b5cc10fc83d15b47e0364d2d7b4a2e12cac1/bin/vvp
SRC=/home/dsell/slurm-runs/caliptra-bfm/a2/m20b-iverilog-8c95b5cc-20261020-01/source/iverilog-uvm/ivtest/ivltests/sv_covergroup_wide_auto_bins.v
OUT=/home/dsell/slurm-runs/caliptra-bfm/a2/m20b-iverilog-8c95b5cc-20261020-01/wide-auto-bin-check

mkdir -p "$OUT"
printf 'source_commit=8c95b5cc10fc83d15b47e0364d2d7b4a2e12cac1\n'
"$IVL" -V 2>&1 | sed -n '1p'
sha256sum "$IVL" "$VVP" "$SRC"

timeout 60s "$IVL" -g2017 -gno-icarus-misc -gno-xtypes -s top \
  -o "$OUT/wide-auto-bin.vvp" "$SRC"
result=$(timeout 60s "$VVP" "$OUT/wide-auto-bin.vvp")
printf '%s\n' "$result"
test "$result" = 'PASSED'
