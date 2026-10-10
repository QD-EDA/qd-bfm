#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
CALIPTRA_RTL=${CALIPTRA_RTL:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_axi_complex_bfm.vvp"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
"$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_random_stalls_distribution -o "$out" \
  dv/caliptra_bfm/axi/axi4_caliptra_random_stalls.sv \
  dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_random_stalls_distribution.sv
"$VVP_BIN" "$out"
"$IVERILOG_BIN" -g2012 -DVERILATOR -DXCELIUM -DCALIPTRA_BFM_CHECKER \
  -I"$CALIPTRA_RTL/src/integration/rtl" \
  -I"$CALIPTRA_RTL/src/integration/rtl/caliptra_reg" \
  -I"$CALIPTRA_RTL/src/libs/rtl" \
  -I"$CALIPTRA_RTL/src/integration/tb" \
  -I"$CALIPTRA_RTL/src/axi/rtl" \
  -I"$CALIPTRA_RTL/src/soc_ifc/rtl" \
  -s tb_caliptra_top_tb_axi_complex_bfm -o "$out" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_pkg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_if.sv" \
  "$CALIPTRA_RTL/src/soc_ifc/rtl/soc_ifc_pkg.sv" \
  "$CALIPTRA_RTL/src/integration/tb/caliptra_top_tb_pkg.sv" \
  dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv \
  dv/caliptra_bfm/axi/axi4_caliptra_fifo_subordinate.sv \
  dv/caliptra_bfm/axi/axi4_caliptra_recovery_sequence.sv \
  dv/caliptra_bfm/axi/axi4_caliptra_recovery_avail.sv \
  dv/caliptra_bfm/axi/axi4_caliptra_dma_subordinate.sv \
  dv/caliptra_bfm/axi/axi4_caliptra_checker.sv \
  dv/caliptra_bfm/axi/axi4_caliptra_random_stalls.sv \
  dv/caliptra_bfm/axi/caliptra_top_tb_axi_complex_bfm.sv \
  dv/caliptra_bfm/axi/tests/tb_caliptra_top_tb_axi_complex_bfm.sv
"$VVP_BIN" "$out" \
  +ERR_RESP_START_ADDR=0000fa570000 \
  +ERR_RESP_END_ADDR=000123440000 \
  +CLP_DMA_TB_MODE_NOT_EMPTY
