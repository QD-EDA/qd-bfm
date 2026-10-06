#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
for edition in 2017 2023; do
  out="$tmpdir/uvmf_scoreboard_$edition.vvp"
  log="$tmpdir/uvmf_scoreboard_$edition.log"
  "$IVERILOG_BIN" -uvm -g"$edition" -s tb_uvmf_scoreboard -o "$out" \
    dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv \
    dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv \
    dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_scoreboard.sv
  "$VVP_BIN" "$out" >"$log" 2>&1 || { cat "$log"; exit 1; }
  cat "$log"
  grep -Eq '^UVM_ERROR[[:space:]]*:[[:space:]]*4$' "$log" || {
    echo "Expected two compare mismatches and two end-of-test leftover errors under IEEE $edition" >&2
    exit 1
  }
  grep -Eq '^UVM_FATAL[[:space:]]*:[[:space:]]*0$' "$log" || {
    echo "Unexpected UVM fatal under IEEE $edition" >&2
    exit 1
  }
  mismatch_count=$(grep -c '^UVM_ERROR .*\[UVMF_SB_MISMATCH\]' "$log" || true)
  ooo_mismatch_count=$(grep -c '^UVM_ERROR .*\[UVMF_OOO_MISMATCH\]' "$log" || true)
  leftover_count=$(grep -c '^UVM_ERROR .*\[UVMF_SB_LEFTOVER\]' "$log" || true)
  [ "$mismatch_count" -eq 1 ] && [ "$ooo_mismatch_count" -eq 1 ] && \
    [ "$leftover_count" -eq 2 ] || {
    echo "Expected one mismatch per scoreboard and two directional leftover reports under IEEE $edition" >&2
    exit 1
  }
  grep -q 'PASS: UVMF in-order scoreboard matched, detected mismatch, and retained leftovers' "$log" || {
    echo "Scoreboard test did not reach its pass checkpoint under IEEE $edition" >&2
    exit 1
  }
  grep -q 'PASS: out-of-order scoreboard matched reordered items and retained the mismatch' "$log" || {
    echo "Out-of-order scoreboard test did not reach its pass checkpoint under IEEE $edition" >&2
    exit 1
  }
  grep -q 'matched=2 mismatched=1' "$log" || {
    echo "Out-of-order scoreboard summary did not report the expected result under IEEE $edition" >&2
    exit 1
  }
done
