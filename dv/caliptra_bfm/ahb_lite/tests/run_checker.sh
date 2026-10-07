#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
out=$(mktemp)
log=$(mktemp)
trap 'rm -f "$out" "$log"' EXIT

"$IVERILOG_BIN" -g2012 -s tb_ahb_lite_caliptra_checker -o "$out" \
  ../ahb_lite_caliptra_checker.sv tb_ahb_lite_caliptra_checker.sv
"$VVP_BIN" "$out" +CASE=GOOD

for entry in \
  'BAD_X:1' \
  'BAD_BUSY:2' \
  'BAD_SIZE:3' \
  'BAD_ALIGN:4' \
  'BAD_ADDR_STABILITY:5' \
  'BAD_ADDR_COMPLETION:5' \
  'BAD_WDATA_STABILITY:6' \
  'BAD_ERROR_SECOND:7' \
  'BAD_ERROR_SINGLE:8' \
  'BAD_ORPHAN_SEQ:9' \
  'BAD_ORPHAN_ERROR:10'; do
  case_name=${entry%%:*}
  error_code=${entry#*:}
  if "$VVP_BIN" "$out" "+CASE=$case_name" >"$log" 2>&1; then
    printf '%s unexpectedly passed\n' "$case_name" >&2
    exit 1
  fi
  if ! grep -Fq "EXPECTED_CHECKER_REJECTION case=$case_name code=$error_code" "$log"; then
    cat "$log" >&2
    printf '%s was not rejected with checker code %s\n' "$case_name" "$error_code" >&2
    exit 1
  fi
done

printf 'PASS: AHB checker rejected all eleven injected protocol violations\n'
