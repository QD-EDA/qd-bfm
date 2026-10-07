#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
SV_EDITION=${SV_EDITION:-2012}
AHB_PROFILE=${AHB_PROFILE:-64}
ahb_define=
case "$AHB_PROFILE" in
  32) ahb_define=-DCALIPTRA_BFM_AHB_32BIT ;;
  64) ;;
  *) echo "AHB_PROFILE must be 32 or 64, got $AHB_PROFILE" >&2; exit 2 ;;
esac
tmpdir=$(mktemp -d)
out="$tmpdir/ahb_qvip_compat_${AHB_PROFILE}_${SV_EDITION}.vvp"
log="$tmpdir/ahb_qvip_compat_${AHB_PROFILE}_${SV_EDITION}.log"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
"$IVERILOG_BIN" -uvm -g"$SV_EDITION" $ahb_define -s tb_ahb_qvip_compat_env -o "$out" \
  -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
  dv/caliptra_bfm/uvm/tests/tb_ahb_qvip_compat_env.sv
"$VVP_BIN" "$out" >"$log" 2>&1 || { cat "$log"; exit 1; }
cat "$log"
if grep -Eq '^UVM_(ERROR|FATAL) :[[:space:]]*[1-9]' "$log"; then
  echo "AHB QVIP compatibility test reported errors or fatals" >&2
  exit 1
fi
