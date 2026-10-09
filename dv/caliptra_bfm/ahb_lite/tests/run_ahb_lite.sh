#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
SV_EDITION=${SV_EDITION:-2012}
out=$(mktemp)
log=$(mktemp)
trap 'rm -f "$out" "$log"' EXIT
case "$SV_EDITION" in
  2012|2017|2023) ;;
  *) echo "SV_EDITION must be 2012, 2017, or 2023" >&2; exit 2 ;;
esac
"$IVERILOG_BIN" -g"$SV_EDITION" -s tb_ahb_lite_caliptra -o "$out" \
  ../ahb_lite_caliptra_master.sv \
  ../ahb_lite_caliptra_memory_subordinate.sv \
  ../ahb_lite_caliptra_checker.sv \
  ../ahb_lite_caliptra_monitor.sv \
  tb_ahb_lite_caliptra.sv
"$VVP_BIN" "$out"

"$IVERILOG_BIN" -g"$SV_EDITION" -s tb_ahb_lite_caliptra_reset_abort -o "$out" \
  ../ahb_lite_caliptra_master.sv tb_ahb_lite_caliptra.sv
if "$VVP_BIN" "$out" >"$log" 2>&1; then
  :
else
  cat "$log" >&2
  exit 1
fi
for expected in \
  'AHB manager reset during address wait' \
  'AHB manager reset during data wait' \
  'AHB manager reset during incrementing burst' \
  'PASS: AHB manager aborts single/burst waits and recovers cleanly'; do
  if ! grep -Fq "$expected" "$log"; then
    cat "$log" >&2
    printf 'missing reset-abort result: %s\n' "$expected" >&2
    exit 1
  fi
done
error_count=$(grep -c '^ERROR:' "$log" || true)
if [ "$error_count" -ne 3 ]; then
  cat "$log" >&2
  printf 'expected three reset-abort diagnostics, observed %s\n' "$error_count" >&2
  exit 1
fi
grep '^PASS:' "$log"
