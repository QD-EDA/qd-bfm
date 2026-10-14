#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
CALIPTRA_RTL=${CALIPTRA_RTL:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_mbox_sram.vvp"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"

"$IVERILOG_BIN" -g2012 \
  -I"$CALIPTRA_RTL/src/integration/rtl" \
  -I"$CALIPTRA_RTL/src/integration/rtl/caliptra_reg" \
  -I"$CALIPTRA_RTL/src/libs/rtl" \
  -I"$CALIPTRA_RTL/src/soc_ifc/rtl" \
  -s tb_caliptra_mbox_sram_subordinate -o "$out" \
  "$CALIPTRA_RTL/src/soc_ifc/rtl/soc_ifc_pkg.sv" \
  dv/caliptra_bfm/mailbox/caliptra_mbox_sram_subordinate.sv \
  dv/caliptra_bfm/mailbox/tests/tb_caliptra_mbox_sram_subordinate.sv
"$VVP_BIN" "$out"
