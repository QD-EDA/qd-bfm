#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

cd "$(dirname "$0")"
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
out=$(mktemp)
out_no_checker=$(mktemp)
out_outstanding=$(mktemp)
out_write_outstanding=$(mktemp)
trap 'rm -f "$out" "$out_no_checker" "$out_outstanding" "$out_write_outstanding"' EXIT
"$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_master -o "$out" \
  ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv tb_axi4_caliptra_master.sv
"$VVP_BIN" "$out"
"$VVP_BIN" "$out" +CASE=WRAP_NARROW
"$VVP_BIN" "$out" +CASE=W_BEFORE_AW
"$VVP_BIN" "$out" +CASE=CONCURRENT
"$VVP_BIN" "$out" +CASE=RESET_ABORT
"$IVERILOG_BIN" -g2012 -Ptb_axi4_caliptra_master.CHECKER_ENABLED=0 \
  -s tb_axi4_caliptra_master -o "$out_no_checker" \
  ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv tb_axi4_caliptra_master.sv
"$VVP_BIN" "$out_no_checker" +CASE=BAD_BID
"$VVP_BIN" "$out_no_checker" +CASE=BAD_RLAST
"$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_master_outstanding -o "$out_outstanding" \
  ../axi4_caliptra_master.sv tb_axi4_caliptra_master_outstanding.sv
"$VVP_BIN" "$out_outstanding"
"$IVERILOG_BIN" -g2012 -s tb_axi4_caliptra_master_write_outstanding -o "$out_write_outstanding" \
  ../axi4_caliptra_master.sv tb_axi4_caliptra_master_write_outstanding.sv
"$VVP_BIN" "$out_write_outstanding"
