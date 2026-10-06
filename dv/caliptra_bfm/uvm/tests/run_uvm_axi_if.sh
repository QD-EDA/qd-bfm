#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
CALIPTRA_RTL=${CALIPTRA_RTL:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/uvm_axi_if.vvp"
log="$tmpdir/uvm_axi_if.log"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
"$IVERILOG_BIN" -uvm -g2012 -DXCELIUM -s tb_axi4_caliptra_uvm_axi_if -o "$out" \
  -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
  "$CALIPTRA_RTL/src/axi/rtl/axi_pkg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_if.sv" \
  dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv \
  dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv \
  dv/caliptra_bfm/uvm/tests/tb_axi4_caliptra_uvm_axi_if.sv
"$VVP_BIN" "$out" >"$log" 2>&1 || { cat "$log"; exit 1; }
cat "$log"
if grep -Eq '^UVM_(ERROR|FATAL) :[[:space:]]*[1-9]' "$log"; then
  echo "UVM axi_if test reported errors or fatals" >&2
  exit 1
fi
