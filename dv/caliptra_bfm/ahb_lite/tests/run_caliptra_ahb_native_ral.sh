#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
SV_EDITION=${SV_EDITION:-2012}
AHB_DATA_WIDTH=${AHB_DATA_WIDTH:-64}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_ahb_native_ral.vvp"
log="$tmpdir/caliptra_ahb_native_ral.log"
trap 'rm -rf "$tmpdir"' EXIT

case "$SV_EDITION" in
  2012|2017|2023) ;;
  *) echo "SV_EDITION must be 2012, 2017, or 2023" >&2; exit 2 ;;
esac
case "$AHB_DATA_WIDTH" in
  32) data_width_define=-DCALIPTRA_BFM_AHB_32BIT ;;
  64) data_width_define= ;;
  *) echo "AHB_DATA_WIDTH must be 32 or 64" >&2; exit 2 ;;
esac

cd "$repo_root"
if [ "$AHB_DATA_WIDTH" = 32 ]; then
  "$IVERILOG_BIN" -uvm -g"$SV_EDITION" "$data_width_define" \
    -s tb_ahb_lite_caliptra_native_ral -o "$out" \
    -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
    dv/caliptra_bfm/ahb_lite/tests/tb_ahb_lite_caliptra_native_ral.sv
else
  "$IVERILOG_BIN" -uvm -g"$SV_EDITION" -s tb_ahb_lite_caliptra_native_ral -o "$out" \
    -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
    dv/caliptra_bfm/ahb_lite/tests/tb_ahb_lite_caliptra_native_ral.sv
fi
if ! "$VVP_BIN" "$out" >"$log" 2>&1; then
  cat "$log" >&2
  exit 1
fi
cat "$log"
if grep -Eq '^UVM_(ERROR|FATAL) :[[:space:]]*[1-9]' "$log"; then
  echo "Native AHB RAL test reported UVM errors or fatals" >&2
  exit 1
fi
grep -Fq "PASS: native AHB RAL byte/halfword frontdoors, monitor prediction, and ERROR status" "$log"
