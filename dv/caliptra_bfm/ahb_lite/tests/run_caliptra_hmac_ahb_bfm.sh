#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
caliptra_root=${CALIPTRA_ROOT:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
SV_EDITION=${SV_EDITION:-2017}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_hmac_ahb_bfm.vvp"
filelist="$tmpdir/hmac_ctrl_bfm.vf"
log="$tmpdir/caliptra_hmac_ahb_bfm.log"
trap 'rm -rf "$tmpdir"' EXIT

case "$SV_EDITION" in
  2012|2017|2023) ;;
  *) echo "SV_EDITION must be 2012, 2017, or 2023" >&2; exit 2 ;;
esac

python3 - "$caliptra_root/src/hmac/config/hmac_ctrl_tb.vf" "$filelist" <<'PY'
import sys
from pathlib import Path

source, destination = map(Path, sys.argv[1:])
lines = source.read_text().splitlines()
lines = [line for line in lines if "/src/hmac/coverage/" not in line and
         not line.endswith("/src/hmac/tb/hmac_ctrl_tb.sv")]
if not lines or not any("/src/hmac/rtl/hmac_ctrl.sv" in line for line in lines):
    raise SystemExit("HMAC RTL filelist did not contain hmac_ctrl.sv")
destination.write_text("\n".join(lines) + "\n")
PY

CALIPTRA_ROOT="$caliptra_root" \
CALIPTRA_PRIM_ROOT="$caliptra_root/src/caliptra_prim_generic" \
CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic \
  "$IVERILOG_BIN" -g"$SV_EDITION" -s tb_caliptra_hmac_ahb_bfm -o "$out" \
  -f "$filelist" \
  "$repo_root/dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_master.sv" \
  "$repo_root/dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_checker.sv" \
  "$repo_root/dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_monitor.sv" \
  "$repo_root/dv/caliptra_bfm/ahb_lite/tests/tb_caliptra_hmac_ahb_bfm.sv"

if ! "$VVP_BIN" "$out" >"$log" 2>&1; then
  cat "$log" >&2
  exit 1
fi
cat "$log"
grep -Fq "PASS: native AHB BFM completed HMAC-SHA-512 known-answer test" "$log"
