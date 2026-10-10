#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
verilator_bin=${VERILATOR_BIN:-verilator}
unset VERILATOR_BIN
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT HUP INT TERM
for config in 32:1 32:4 32:8 64:1 64:4 64:8 128:1 128:4 128:8 \
              256:1 256:4 256:8 512:1 512:4 512:8 1024:1 1024:4 1024:8; do
  data_width=${config%:*}
  id_width=${config#*:}
  dir="$build/$data_width-$id_width"
  mkdir -p "$dir"
  "$verilator_bin" --binary --timing --build-jobs 1 -Wno-fatal \
    --top-module tb_axi4_caliptra_parameter_matrix \
    -GDATA_WIDTH="$data_width" -GID_WIDTH="$id_width" --Mdir "$dir" \
    ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv \
    ../axi4_caliptra_memory_subordinate.sv ../axi4_caliptra_monitor.sv \
    ../axi4_caliptra_transaction_monitor.sv \
    tb_axi4_caliptra_parameter_matrix.sv
  "$dir/Vtb_axi4_caliptra_parameter_matrix"
  rm -rf "$dir"
done
