#!/bin/sh
set -eu

out=$(mktemp)
log=$(mktemp)
trap 'rm -f "$out" "$log"' EXIT
iverilog -g2012 -s tb_axi4 -o "$out" qd_axi4_single_master.sv tb_axi4.sv
vvp "$out"
for case_name in BAD_RID BAD_RLAST; do
  if vvp "$out" "+$case_name" > "$log" 2>&1; then
    printf '%s unexpectedly passed\n' "$case_name" >&2
    exit 1
  fi
  if grep -q '^PASS:' "$log"; then
    printf '%s emitted a pass banner\n' "$case_name" >&2
    exit 1
  fi
  case "$case_name" in
    BAD_RID) grep -q 'AXI R ID mismatch' "$log" ;;
    BAD_RLAST) grep -q 'AXI single-beat read missing RLAST' "$log" ;;
  esac
done
printf 'PASS: bad response ID and missing RLAST rejected\n'
