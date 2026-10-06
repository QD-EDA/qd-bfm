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
out="$tmpdir/caliptra_ecc_ahb_uvm_bfm.vvp"
log="$tmpdir/caliptra_ecc_ahb_uvm_bfm.log"
trap 'rm -rf "$tmpdir"' EXIT

case "$SV_EDITION" in
  2012|2017|2023) ;;
  *) echo "SV_EDITION must be 2012, 2017, or 2023" >&2; exit 2 ;;
esac

cd "$repo_root"
CALIPTRA_ROOT="$caliptra_root" \
CALIPTRA_PRIM_ROOT="$caliptra_root/src/caliptra_prim_generic" \
CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic \
  "$IVERILOG_BIN" -uvm -g"$SV_EDITION" -s tb_caliptra_ecc_ahb_uvm_bfm -o "$out" \
  -f "$caliptra_root/src/ecc/config/ecc_top.vf" \
  -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
  dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_checker.sv \
  dv/caliptra_bfm/ahb_lite/tests/tb_caliptra_ecc_ahb_uvm_bfm.sv
"$VVP_BIN" "$out" >"$log" 2>&1 || { cat "$log"; exit 1; }
cat "$log"
if grep -Eq '^UVM_(ERROR|FATAL) :[[:space:]]*[1-9]' "$log"; then
  echo "Caliptra ECC AHB UVM BFM smoke reported UVM errors or fatals" >&2
  exit 1
fi
