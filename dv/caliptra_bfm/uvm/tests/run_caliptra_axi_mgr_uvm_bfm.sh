#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
CALIPTRA_RTL=${CALIPTRA_RTL:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_axi_mgr_uvm_bfm.vvp"
log="$tmpdir/caliptra_axi_mgr_uvm_bfm.log"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
"$IVERILOG_BIN" -uvm -g2012 -DXCELIUM \
  -I"$CALIPTRA_RTL/src/caliptra_prim/rtl" \
  -I"$CALIPTRA_RTL/src/libs/rtl" \
  -s tb_caliptra_axi_mgr_uvm_bfm -o "$out" \
  -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
  "$CALIPTRA_RTL/src/axi/rtl/axi_pkg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_if.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_dma_req_if.sv" \
  "$CALIPTRA_RTL/src/libs/rtl/skidbuffer.v" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_mgr_rd.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_mgr_wr.sv" \
  dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv \
  dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv \
  dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_mgr_uvm_bfm.sv
"$VVP_BIN" "$out" >"$log" 2>&1 || { cat "$log"; exit 1; }
cat "$log"
if grep -Eq '^UVM_(ERROR|FATAL) :[[:space:]]*[1-9]' "$log"; then
  echo "Caliptra AXI manager UVM BFM test reported errors or fatals" >&2
  exit 1
fi
