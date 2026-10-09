#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
SV_EDITION=${SV_EDITION:-2012}
out=$(mktemp)
trap 'rm -f "$out"' EXIT
case "$SV_EDITION" in
  2012|2017|2023) ;;
  *) echo "SV_EDITION must be 2012, 2017, or 2023" >&2; exit 2 ;;
esac
"$IVERILOG_BIN" -g"$SV_EDITION" -s tb_axi4_caliptra_memory_subordinate -o "$out" \
  ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv \
  ../axi4_caliptra_memory_subordinate.sv ../axi4_caliptra_monitor.sv \
  tb_axi4_caliptra_memory_subordinate.sv
"$VVP_BIN" "$out"

"$IVERILOG_BIN" -g"$SV_EDITION" -s tb_axi4_caliptra_memory_queue -o "$out" \
  ../axi4_caliptra_memory_subordinate.sv tb_axi4_caliptra_memory_queue.sv
"$VVP_BIN" "$out"
