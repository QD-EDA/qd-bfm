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
  out="$tmpdir/uvmf_transaction_key_$edition.vvp"
  log="$tmpdir/uvmf_transaction_key_$edition.log"
  record_log="$tmpdir/uvmf_transaction_record_$edition.log"
  "$IVERILOG_BIN" -uvm -g"$edition" -s tb_uvmf_transaction_key -o "$out" \
    dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv \
    dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv \
    dv/caliptra_bfm/uvmf_lite/tests/tb_uvmf_transaction_key.sv
  "$VVP_BIN" "$out" "+BFM_LITE_RECORD_FILE=$record_log" >"$log" 2>&1 || { cat "$log"; exit 1; }
  grep -q 'PASS: UVMF transaction key and timestamp/payload recording' "$log" || {
    cat "$log"
    echo "Transaction record test did not pass under IEEE $edition" >&2
    exit 1
  }
  for field in start_time end_time payload; do
    grep -q "$field" "$record_log" || {
      echo "UVMF transaction record omitted $field under IEEE $edition" >&2
      exit 1
    }
  done
  if grep -q 'DO_NOT_RECORD_SENTINEL' "$record_log"; then
    echo "UVMF transaction record serialized convert2string under IEEE $edition" >&2
    exit 1
  fi
  echo "PASS: UVMF transaction key and recording API under IEEE $edition"
done
