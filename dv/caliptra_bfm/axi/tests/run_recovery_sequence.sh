#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
out=$(mktemp)
trap 'rm -f "$out"' EXIT
"$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_recovery_sequence -o "$out" \
  ../axi4_caliptra_recovery_sequence.sv tb_axi4_caliptra_recovery_sequence.sv
"$VVP_BIN" "$out"
