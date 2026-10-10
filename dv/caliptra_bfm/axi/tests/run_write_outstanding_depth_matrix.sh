#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
out=$(mktemp)
trap 'rm -f "$out"' EXIT
for config in 32:1 32:4 32:8 64:1 64:4 64:8 128:1 128:4 128:8 \
              256:1 256:4 256:8 512:1 512:4 512:8 1024:1 1024:4 1024:8; do
  data_width=${config%:*}
  id_width=${config#*:}
  for depth in 1 2 4; do
    "$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_master_write_outstanding \
      -Ptb_axi4_caliptra_master_write_outstanding.DATA_WIDTH="$data_width" \
      -Ptb_axi4_caliptra_master_write_outstanding.ID_WIDTH="$id_width" \
      -Ptb_axi4_caliptra_master_write_outstanding.MAX_OUTSTANDING="$depth" -o "$out" \
      ../axi4_caliptra_master.sv tb_axi4_caliptra_master_write_outstanding.sv
    "$VVP_BIN" "$out"
  done
done
