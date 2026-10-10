#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
CALIPTRA_RTL=${CALIPTRA_RTL:-"$repo_root/../caliptra-rtl"}
VERILATOR_BIN=${VERILATOR_BIN:-verilator}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/caliptra_axi_complex_bfm.XXXXXX")
top=tb_caliptra_top_tb_axi_complex_bfm
trap 'rm -rf "$tmpdir"' EXIT

cd "$repo_root"
"$VERILATOR_BIN" --binary --timing --assert -j 1 -Wno-fatal -O0 \
  --output-split 20000 --output-split-cfuncs 1000 -CFLAGS -O0 \
  -DVERILATOR -DXCELIUM -DCALIPTRA_BFM_CHECKER \
  --top-module "$top" --Mdir "$tmpdir/obj_dir" \
  -I"$CALIPTRA_RTL/src/integration/rtl" \
  -I"$CALIPTRA_RTL/src/integration/rtl/caliptra_reg" \
  -I"$CALIPTRA_RTL/src/libs/rtl" \
  -I"$CALIPTRA_RTL/src/integration/tb" \
  -I"$CALIPTRA_RTL/src/axi/rtl" \
  -I"$CALIPTRA_RTL/src/soc_ifc/rtl" \
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
"$tmpdir/obj_dir/V$top" \
  +ERR_RESP_START_ADDR=0000fa570000 \
  +ERR_RESP_END_ADDR=000123440000 \
  +CLP_DMA_TB_MODE_NOT_EMPTY
