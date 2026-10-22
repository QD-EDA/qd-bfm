#!/bin/bash
set -euo pipefail

ATTEMPT="$(cd "$(dirname "$0")" && pwd)"
WORK=/tmp/a2-m18-iverilog-cae035642e056644274a01e98d4422ce286685b4-local-01
SOURCE_ARCHIVE="$ATTEMPT/../iverilog-main-cae0356-20261019-02/raw/source-snapshot.tar.gz"
SOURCE="$WORK/source"
TOOL="$WORK/tool"

mkdir -p "$WORK"
tar -xzf "$SOURCE_ARCHIVE" -C "$WORK"
test -f "$SOURCE/configure.ac"
cd "$SOURCE"
export PATH="/opt/homebrew/opt/bison/bin:$PATH"

sh autoconf.sh > "$ATTEMPT/raw/autoconf.log" 2>&1
./configure --prefix="$TOOL" --enable-libveriuser > "$ATTEMPT/raw/configure.log" 2>&1
make -j1 > "$ATTEMPT/raw/make.log" 2>&1
make install > "$ATTEMPT/raw/install.log" 2>&1

{
  hostname
  date -u +%FT%TZ
  uname -a
  git --version
  clang --version | sed -n '1p'
  bison --version | sed -n '1p'
  flex --version | sed -n '1p'
  gperf --version | sed -n '1p'
  printf 'source_sha=cae035642e056644274a01e98d4422ce286685b4\n'
  "$TOOL/bin/iverilog" -V 2>&1 | sed -n '1p'
  "$TOOL/bin/vvp" -V 2>&1 | sed -n '1p'
  shasum -a 256 "$TOOL/bin/iverilog" "$TOOL/bin/vvp"
  otool -L "$TOOL/bin/iverilog"
  otool -L "$TOOL/bin/vvp"
} > "$ATTEMPT/raw/build-info.txt"

"$TOOL/bin/iverilog" -g2012 -uvm -o "$WORK/smoke.vvp" tests/no_rand_test.sv > "$ATTEMPT/raw/smoke-compile.log" 2>&1
"$TOOL/bin/vvp" "$WORK/smoke.vvp" > "$ATTEMPT/raw/smoke-run.log" 2>&1
grep -q 'No-rand test PASSED!' "$ATTEMPT/raw/smoke-run.log"
printf '%s\n' "$TOOL" > "$ATTEMPT/toolchain-path.txt"
