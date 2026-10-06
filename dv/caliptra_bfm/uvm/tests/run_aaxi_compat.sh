#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
caliptra_root=${CALIPTRA_ROOT:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/aaxi-compat.vvp"
log="$tmpdir/aaxi-compat.log"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"

"$IVERILOG_BIN" -uvm -g2012 -DXCELIUM -s tb_caliptra_aaxi_compat -o "$out" \
  -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
  "$caliptra_root/src/axi/rtl/axi_pkg.sv" \
  "$caliptra_root/src/axi/rtl/axi_if.sv" \
  dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv \
  dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv \
  dv/caliptra_bfm/uvm/tests/tb_caliptra_aaxi_compat.sv
"$VVP_BIN" "$out" >"$log" 2>&1 || { cat "$log"; exit 1; }
cat "$log"
if grep -Eq '^UVM_(ERROR|FATAL) *: *[1-9]' "$log" || \
   ! grep -Fq 'PASS: SoC-IFC-compatible AAXI hierarchy drove SRAM write/read' "$log"; then
  echo "AAXI compatibility hierarchy failed its UVM/runtime gate" >&2
  exit 1
fi
