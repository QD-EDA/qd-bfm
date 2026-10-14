#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
CALIPTRA_RTL=${CALIPTRA_RTL:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_axi_if.vvp"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
"$IVERILOG_BIN" -g2012 -DXCELIUM -s tb_axi4_caliptra_dma_if -o "$out" \
  -f dv/caliptra_bfm/caliptra_bfm.f \
  "$CALIPTRA_RTL/src/axi/rtl/axi_pkg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_if.sv" \
  dv/caliptra_bfm/axi/axi4_caliptra_master_if_manager.sv \
  dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv \
  dv/caliptra_bfm/uvm/axi4_caliptra_record_if.sv \
  dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv \
  dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_dma_if.sv
"$VVP_BIN" "$out"
