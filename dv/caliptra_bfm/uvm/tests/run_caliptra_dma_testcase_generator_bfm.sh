#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../../" && pwd)
CALIPTRA_RTL=${CALIPTRA_RTL:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_dma_testcase_generator_bfm.vvp"
log="$tmpdir/caliptra_dma_testcase_generator_bfm.log"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"

sed 's/\$fatal("/\$fatal(1, "/' \
  "$CALIPTRA_RTL/src/integration/tb/dma_transfer_randomizer.sv" \
  >"$tmpdir/dma_transfer_randomizer.sv"
python3 docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py \
  --caliptra-root "$CALIPTRA_RTL" \
  --output "$tmpdir/dma_testcase_generator.sv" \
  --manifest "$tmpdir/dma_testcase_generator_overlay.json"

"$IVERILOG_BIN" -uvm -g2012 -DXCELIUM \
  -I"$tmpdir" \
  -I"$CALIPTRA_RTL/src/caliptra_prim/rtl" \
  -I"$CALIPTRA_RTL/src/libs/rtl" \
  -I"$CALIPTRA_RTL/src/axi/rtl" \
  -I"$CALIPTRA_RTL/src/soc_ifc/rtl" \
  -I"$CALIPTRA_RTL/src/keyvault/rtl" \
  -I"$CALIPTRA_RTL/src/integration/rtl" \
  -I"$CALIPTRA_RTL/src/integration/rtl/caliptra_reg" \
  -I"$CALIPTRA_RTL/src/integration/tb" \
  -s tb_caliptra_dma_testcase_generator_bfm -o "$out" \
  "$CALIPTRA_RTL/src/caliptra_prim/rtl/caliptra_prim_util_pkg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_pkg.sv" \
  "$CALIPTRA_RTL/src/soc_ifc/rtl/soc_ifc_pkg.sv" \
  "$CALIPTRA_RTL/src/integration/tb/caliptra_top_tb_pkg.sv" \
  "$CALIPTRA_RTL/src/keyvault/rtl/kv_defines_pkg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_dma_reg_pkg.sv" \
  "$CALIPTRA_RTL/src/riscv_core/veer_el2/rtl/common_defines.sv" \
  "$tmpdir/dma_testcase_generator.sv" \
  dv/caliptra_bfm/axi/axi4_caliptra_recovery_sequence.sv \
  dv/caliptra_bfm/uvm/tests/tb_caliptra_dma_testcase_generator_bfm.sv

if ! "$VVP_BIN" "$out" +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=25 +CPTRA_VERBOSITY=0 >"$log" 2>&1; then
  cat "$log"
  echo "Caliptra DMA testcase generator BFM probe failed" >&2
  exit 1
fi
cat "$log"
if ! grep -q '^PASS: real dma_testcase_generator staged ' "$log"; then
  echo "Caliptra DMA testcase generator BFM probe did not report success" >&2
  exit 1
fi
