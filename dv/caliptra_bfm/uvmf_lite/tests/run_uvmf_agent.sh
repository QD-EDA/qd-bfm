#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

edition_filter=${UVMF_IEEE_EDITION:-both}
case "$edition_filter" in
  both|2017|2023) ;;
  *) echo "UVMF_IEEE_EDITION must be both, 2017, or 2023" >&2; exit 2 ;;
esac

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
for edition in 2017 2023; do
  if [ "$edition_filter" != both ] && [ "$edition_filter" != "$edition" ]; then
    continue
  fi
  out="$tmpdir/uvmf_agent_$edition.vvp"
  log="$tmpdir/uvmf_agent_$edition.log"
  negative_log="$tmpdir/uvmf_agent_mismatch_$edition.log"
  "$IVERILOG_BIN" -uvm -g"$edition" -s tb_uvmf_agent -o "$out" \
    dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv \
    dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv \
    dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_agent.sv
  "$VVP_BIN" "$out" >"$log" 2>&1 || { cat "$log"; exit 1; }
  cat "$log"
  grep -q 'PASS: active/passive factory BFM path and scoreboard control' "$log" || {
    echo "Agent test did not reach its pass checkpoint under IEEE $edition" >&2
    exit 1
  }
  grep -Eq '^UVM_ERROR[[:space:]]*:[[:space:]]*0$' "$log" || {
    echo "Unexpected UVM error under IEEE $edition" >&2
    exit 1
  }
  grep -Eq '^UVM_FATAL[[:space:]]*:[[:space:]]*0$' "$log" || {
    echo "Unexpected UVM fatal under IEEE $edition" >&2
    exit 1
  }

  "$VVP_BIN" "$out" +BFM_LITE_EXPECT_MISMATCH >"$negative_log" 2>&1 || {
    cat "$negative_log"
    exit 1
  }
  cat "$negative_log"
  grep -q 'PASS: active/passive factory BFM path and scoreboard control' "$negative_log" || {
    echo "Mismatch-control test did not reach its pass checkpoint under IEEE $edition" >&2
    exit 1
  }
  grep -Eq '^UVM_ERROR[[:space:]]*:[[:space:]]*1$' "$negative_log" || {
    echo "Expected one intentional scoreboard mismatch under IEEE $edition" >&2
    exit 1
  }
  grep -Eq '^UVM_FATAL[[:space:]]*:[[:space:]]*0$' "$negative_log" || {
    echo "Unexpected UVM fatal in mismatch control under IEEE $edition" >&2
    exit 1
  }
  grep -q '\[UVMF_SB_MISMATCH\]' "$negative_log" || {
    echo "Negative control did not report a scoreboard mismatch under IEEE $edition" >&2
    exit 1
  }
done
