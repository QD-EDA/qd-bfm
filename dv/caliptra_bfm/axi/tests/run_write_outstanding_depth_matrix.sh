#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
out=$(mktemp)
trap 'rm -f "$out"' EXIT
for depth in 1 2 4; do
  "$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_master_write_outstanding \
    -Ptb_axi4_caliptra_master_write_outstanding.MAX_OUTSTANDING="$depth" -o "$out" \
    ../axi4_caliptra_master.sv tb_axi4_caliptra_master_write_outstanding.sv
  "$VVP_BIN" "$out"
done
