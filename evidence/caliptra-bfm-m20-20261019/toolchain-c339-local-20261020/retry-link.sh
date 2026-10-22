#!/bin/bash
set -euo pipefail
src=/tmp/m20-iverilog-cae035642e056644274a01e98d4422ce286685b4-source
tool=/tmp/m20-iverilog-cae035642e056644274a01e98d4422ce286685b4-tool
evidence_dir=$(cd "$(dirname "$0")" && pwd)
export PATH="/opt/homebrew/opt/bison/bin:/opt/homebrew/bin:/usr/bin:/bin"
export LIBS=-lffi
export LDFLAGS="-L/opt/homebrew/opt/z3/lib"
export CPPFLAGS="-I/opt/homebrew/include -I$(xcrun --show-sdk-path)/usr/include/ffi"
cd "$src"
./configure --prefix="$tool" --enable-libveriuser
make -j3
make install
{
  "$tool/bin/iverilog" -V 2>&1 | head -2
  shasum -a 256 "$tool/bin/iverilog" "$tool/bin/vvp"
} > "$evidence_dir/raw/install.txt"
