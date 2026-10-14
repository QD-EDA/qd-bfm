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
"$IVERILOG_BIN" -g2012 -s tb_default_reset_gen -o "$tmpdir/reset.vvp" \
  dv/caliptra_bfm/uvmf_lite/default_reset_gen.sv \
  dv/caliptra_bfm/uvmf_lite/tests/tb_default_reset_gen.sv
"$VVP_BIN" "$tmpdir/reset.vvp"
