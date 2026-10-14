#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
caliptra_root=${CALIPTRA_ROOT:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
SV_EDITION=${SV_EDITION:-2012}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_ecc_ahb_bfm.vvp"
trap 'rm -rf "$tmpdir"' EXIT

case "$SV_EDITION" in
  2012|2017|2023) ;;
  *) echo "SV_EDITION must be 2012, 2017, or 2023" >&2; exit 2 ;;
esac

CALIPTRA_ROOT="$caliptra_root" \
CALIPTRA_PRIM_ROOT="$caliptra_root/src/caliptra_prim_generic" \
CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic \
  "$IVERILOG_BIN" -g"$SV_EDITION" -s tb_caliptra_ecc_ahb_bfm -o "$out" \
  -f "$caliptra_root/src/ecc/config/ecc_top.vf" \
  "$repo_root/dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_master.sv" \
  "$repo_root/dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_checker.sv" \
  "$repo_root/dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_monitor.sv" \
  "$repo_root/dv/caliptra_bfm/ahb_lite/tests/tb_caliptra_ecc_ahb_bfm.sv"
"$VVP_BIN" "$out"
