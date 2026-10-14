#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/ahb_uvm_agent.vvp"
log="$tmpdir/ahb_uvm_agent.log"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
"$IVERILOG_BIN" -uvm -g2012 -s tb_ahb_lite_caliptra_uvm_agent -o "$out" \
  -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
  dv/caliptra_bfm/uvm/tests/tb_ahb_lite_caliptra_uvm_agent.sv
"$VVP_BIN" "$out" "$@" >"$log" 2>&1 || { cat "$log"; exit 1; }
cat "$log"
if grep -Eq '^UVM_(ERROR|FATAL) :[[:space:]]*[1-9]' "$log"; then
  echo "UVM AHB-Lite agent test reported errors or fatals" >&2
  exit 1
fi
