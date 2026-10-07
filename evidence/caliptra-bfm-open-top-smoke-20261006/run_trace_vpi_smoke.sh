#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
iverilog_bin=$(command -v "${IVERILOG_BIN:-iverilog}")
vvp_bin=$(command -v "${VVP_BIN:-vvp}")
vpi_bin=$(command -v "${IVERILOG_VPI_BIN:-$(dirname -- "$iverilog_bin")/iverilog-vpi}")

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/caliptra-trace-vpi-smoke.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

"$iverilog_bin" -g2012 -s caliptra_top_tb -o "$tmp_dir/trace_smoke.vvp" \
  "$script_dir/trace_vpi_smoke.sv"
(
  cd "$tmp_dir"
  "$vpi_bin" "$script_dir/sim-axi-trace-vpi.c"
)
"$vvp_bin" -M "$tmp_dir" -m sim-axi-trace-vpi "$tmp_dir/trace_smoke.vvp" \
  > "$tmp_dir/trace.log" 2>&1

if ! {
  rg -q '^CALIPTRA_TRACE_BOUND$' "$tmp_dir/trace.log" &&
  rg -q '^CALIPTRA_RESET_TRACE_BOUND$' "$tmp_dir/trace.log" &&
  rg -q 'CALIPTRA_RESET_REQUEST .*code=ee ' "$tmp_dir/trace.log" &&
  rg -q 'CALIPTRA_RESET_EDGE state=assert ' "$tmp_dir/trace.log" &&
  rg -q 'CALIPTRA_RESET_EDGE state=deassert ' "$tmp_dir/trace.log" &&
  rg -q 'CALIPTRA_AXI AW count=1 ' "$tmp_dir/trace.log" &&
  rg -q '^CALIPTRA_TRACE_END ' "$tmp_dir/trace.log" &&
  awk '
    /CALIPTRA_RESET_REQUEST .*code=ee / { request = NR }
    /CALIPTRA_RESET_EDGE state=assert / { asserted = NR }
    /CALIPTRA_RESET_EDGE state=deassert / { deasserted = NR }
    /CALIPTRA_AXI AW count=1 / { address = NR }
    END { exit !(request && request < asserted && asserted < deasserted && deasserted < address) }
  ' "$tmp_dir/trace.log"
}; then
  cat "$tmp_dir/trace.log" >&2
  exit 1
fi

printf 'PASS: VPI trace binds the Caliptra hierarchy and records reset plus AXI events.\n'
