#!/bin/bash
set -euo pipefail

tool=/tmp/m20-iverilog-cae035642e056644274a01e98d4422ce286685b4-tool/bin
source_file="$(cd "$(dirname "$0")" && pwd)/wide_auto_bin.sv"
build_dir=$(mktemp -d /tmp/m20-wide-auto-bin.XXXXXX)

echo "Icarus source pin: cae035642e056644274a01e98d4422ce286685b4"
shasum -a 256 "$tool/iverilog" "$tool/vvp"
"$tool/iverilog" -V >"$build_dir/version.log" 2>&1
sed -n '1,2p' "$build_dir/version.log"

"$tool/iverilog" -g2012 -s m20_auto_bin_repro \
  -Pm20_auto_bin_repro.WIDTH=64 -o "$build_dir/narrow.vvp" "$source_file"
"$tool/vvp" "$build_dir/narrow.vvp"

if "$tool/iverilog" -g2012 -s m20_auto_bin_repro \
  -o "$build_dir/wide.vvp" "$source_file" >"$build_dir/wide.log" 2>&1; then
  echo "ERROR: the 512-bit auto-bin coverpoint unexpectedly compiled"
  exit 1
fi
if ! rg -q 'automatic bins for a coverpoint wider than 64 bits are not represented' "$build_dir/wide.log"; then
  cat "$build_dir/wide.log"
  echo "ERROR: wide compile failed for a different reason"
  exit 1
fi
cat "$build_dir/wide.log"
echo "EXPECTED: 64-bit auto bins compile; 512-bit auto bins fail at the width limit"
