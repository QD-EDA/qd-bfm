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
"$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_checker -o "$out" ../axi4_caliptra_checker.sv tb_axi4_caliptra_checker.sv
"$VVP_BIN" "$out"
"$VVP_BIN" "$out" +CASE=GOOD_REORDER
"$VVP_BIN" "$out" +CASE=GOOD_EXCLUSIVE

for entry in \
  'BAD_AW_STABILITY:AW payload changed' \
  'BAD_R_STABILITY:R payload changed' \
  'BAD_WLAST:AXI W burst has' \
  'BAD_NO_WLAST:WLAST missing on final' \
  'BAD_RLAST:AXI RLAST does not match' \
  'BAD_4KB:crosses a 4KB boundary' \
  'BAD_BID:B response ID has no completed' \
  'BAD_RID:R response ID has no active' \
  'BAD_EXOKAY_B:EXOKAY for a non-exclusive write' \
  'BAD_EXOKAY_R:EXOKAY for a non-exclusive read' \
  'BAD_X_AWLOCK:AWLOCK is unknown' \
  'BAD_X_ARLOCK:ARLOCK is unknown' \
  'BAD_X_BRESP:BRESP is unknown' \
  'BAD_X_RRESP:RRESP is unknown' \
  'BAD_LOCK_MIXED_R:exclusive read mixes EXOKAY and non-EXOKAY' \
  'BAD_MISSING_R:incomplete read response' \
  'BAD_EARLY_B:B response ID has no completed write transaction' \
  'BAD_DUP_BID:one outstanding write per ID' \
  'BAD_DUP_RID:one outstanding read per ID' \
  'BAD_LOCK_ALIGNMENT:exclusive AXI address is not aligned to its transaction size' \
  'BAD_LOCK_TOO_LONG:exclusive burst exceeds 16 transfers' \
  'BAD_LOCK_NON_POWER2:exclusive byte count is not a power of 2' \
  'BAD_LOCK_NO_READ:exclusive write has no completed exclusive read' \
  'BAD_LOCK_EARLY_WRITE:exclusive write issued before the read completes' \
  'BAD_LOCK_MISMATCH:exclusive read/write request fields differ' \
  'BAD_LOCK_LEN_MISMATCH:exclusive read/write request fields differ' \
  'BAD_LOCK_SIZE_MISMATCH:exclusive read/write request fields differ' \
  'BAD_LOCK_BURST_MISMATCH:exclusive read/write request fields differ'; do
  case_name=${entry%%:*}
  expected=${entry#*:}
  if "$VVP_BIN" "$out" "+CASE=$case_name" >"$log" 2>&1; then
    printf '%s unexpectedly passed\n' "$case_name" >&2
    exit 1
  fi
  if ! grep -q "$expected" "$log"; then
    cat "$log" >&2
    printf '%s failed for an unexpected reason\n' "$case_name" >&2
    exit 1
  fi
done
printf 'PASS: AXI checker accepted W-before-AW, cross-ID reordering, and legal exclusives; rejected twenty-eight injected protocol violations\n'
