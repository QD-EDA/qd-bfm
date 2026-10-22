#!/bin/bash
set -euo pipefail
src=/tmp/m20-iverilog-cae035642e056644274a01e98d4422ce286685b4-source
tool=/tmp/m20-iverilog-cae035642e056644274a01e98d4422ce286685b4-tool
raw="$PWD/evidence/caliptra-bfm-m20-20261019/toolchain-c339-local-20261020/raw"
mkdir -p "$raw"
export PATH="/opt/homebrew/opt/bison/bin:/opt/homebrew/bin:/usr/bin:/bin"
export LIBS=-lffi
export LDFLAGS="-L/opt/homebrew/opt/z3/lib"
export CPPFLAGS="-I/opt/homebrew/include -I$(xcrun --show-sdk-path)/usr/include/ffi"
{
  date -u
  uname -a
  sw_vers
  printf 'source='; git -C "$src" rev-parse HEAD
  printf 'submodules='; git -C "$src" submodule status | tr '\n' ' '
  printf '\n'
  clang --version | head -1
  bison --version | head -1
  flex --version | head -1
  gperf --version | head -1
} > "$raw/metadata.txt"
cd "$src"
make distclean
sh autoconf.sh
./configure --prefix="$tool" --enable-libveriuser
make -j3
make install
{
  "$tool/bin/iverilog" -V 2>&1 | head -2
  shasum -a 256 "$tool/bin/iverilog" "$tool/bin/vvp"
} > "$raw/install.txt"
