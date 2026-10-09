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
"$IVERILOG_BIN" -g"$SV_EDITION" -s tb_ahb_lite_caliptra -o "$out" \
  ../ahb_lite_caliptra_master.sv \
  ../ahb_lite_caliptra_memory_subordinate.sv \
  ../ahb_lite_caliptra_checker.sv \
  ../ahb_lite_caliptra_monitor.sv \
  tb_ahb_lite_caliptra.sv
"$VVP_BIN" "$out"
