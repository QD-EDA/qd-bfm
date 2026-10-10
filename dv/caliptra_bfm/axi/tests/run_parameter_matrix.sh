#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
out=$(mktemp)
trap 'rm -f "$out"' EXIT
for config in 32:1 32:4 32:8 64:1 64:4 64:8 128:1 128:4 128:8; do
  data_width=${config%:*}
  id_width=${config#*:}
  "$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_parameter_matrix \
    -Ptb_axi4_caliptra_parameter_matrix.DATA_WIDTH="$data_width" \
    -Ptb_axi4_caliptra_parameter_matrix.ID_WIDTH="$id_width" -o "$out" \
    ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv \
    ../axi4_caliptra_memory_subordinate.sv ../axi4_caliptra_monitor.sv \
    tb_axi4_caliptra_parameter_matrix.sv
  "$VVP_BIN" "$out"
done
