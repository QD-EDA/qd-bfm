#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
VERILATOR_BIN=${VERILATOR_BIN:-verilator}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/caliptra_axi_checker.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT
ulimit -c 0
cd "$repo_root/dv/caliptra_bfm/axi/tests"

"$VERILATOR_BIN" --binary --timing -j 1 -Wno-fatal -O0 \
  --output-split 20000 --output-split-cfuncs 1000 -CFLAGS -O0 \
  --top-module tb_axi4_caliptra_checker --Mdir "$tmpdir/obj_dir" \
  ../axi4_caliptra_checker.sv tb_axi4_caliptra_checker.sv
sim="$tmpdir/obj_dir/Vtb_axi4_caliptra_checker"

for test_case in GOOD GOOD_REORDER GOOD_SAME_ID_READS GOOD_SAME_ID_WRITES \
  GOOD_EXCLUSIVE GOOD_NARROW_INCR GOOD_NARROW_FIXED GOOD_NARROW_WRAP; do
  "$sim" "+CASE=$test_case"
done

for entry in \
  'BAD_WLAST:AXI W burst has' \
  'BAD_RLAST:AXI RLAST does not match' \
  'BAD_4KB:crosses a 4KB boundary' \
  'BAD_BID:B response ID has no completed' \
  'BAD_WRITE_QUEUE_FULL:AXI write response queue is full' \
  'BAD_READ_QUEUE_FULL:read request queue is full'; do
  test_case=${entry%%:*}
  expected=${entry#*:}
  if "$sim" "+CASE=$test_case" >"$tmpdir/output.log" 2>&1; then
    printf '%s unexpectedly passed\n' "$test_case" >&2
    exit 1
  fi
  if ! grep -q "$expected" "$tmpdir/output.log"; then
    cat "$tmpdir/output.log" >&2
    printf '%s failed for an unexpected reason\n' "$test_case" >&2
    exit 1
  fi
done

printf 'PASS: Verilator accepted AXI reorder, exclusive, and narrow transfers; rejected six protocol violations\n'
