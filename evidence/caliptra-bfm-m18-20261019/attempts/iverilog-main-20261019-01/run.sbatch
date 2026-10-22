#!/bin/bash
#SBATCH --job-name=m18-iverilog-main
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-iverilog-main-20261019-01/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-iverilog-main-20261019-01/logs/%x-%j.out
set -euo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-iverilog-main-20261019-01
SRC="$RUN/source"
TOOL=/home/dsell/toolchains/iverilog-uvm-m18-main-82023726be90ab269d6e0ef5e755ebb69e6f648c

test "$(git -C "$SRC" rev-parse HEAD)" = 82023726be90ab269d6e0ef5e755ebb69e6f648c
test -z "$(git -C "$SRC" status --porcelain)"
test ! -e "$TOOL"
tar -C "$RUN" --exclude='source/.git' --exclude='source/uvm-core/.git' -czf "$RUN/source-snapshot.tar.gz" source

{
  hostname
  date -u +%FT%TZ
  uname -a
  git -C "$SRC" rev-parse HEAD
  git -C "$SRC" submodule status
  gcc --version | sed -n '1p'
  bison --version | sed -n '1p'
  flex --version | sed -n '1p'
  gperf --version | sed -n '1p'
} > "$RUN/build-info.txt"

cd "$SRC"
sh autoconf.sh > "$RUN/autoconf.log" 2>&1
./configure --prefix="$TOOL" --enable-libveriuser > "$RUN/configure.log" 2>&1
make -j2 > "$RUN/make.log" 2>&1
make install > "$RUN/install.log" 2>&1

{
  "$TOOL/bin/iverilog" -V 2>&1 | sed -n '1p'
  "$TOOL/bin/vvp" -V 2>&1 | sed -n '1p'
  sha256sum "$TOOL/bin/iverilog" "$TOOL/bin/vvp"
  ldd "$TOOL/bin/iverilog"
  ldd "$TOOL/bin/vvp"
} > "$RUN/toolchain-info.txt"

"$TOOL/bin/iverilog" -g2012 -uvm -o "$RUN/smoke.vvp" tests/no_rand_test.sv > "$RUN/smoke-compile.log" 2>&1
"$TOOL/bin/vvp" "$RUN/smoke.vvp" > "$RUN/smoke-run.log" 2>&1
grep -q 'UVM' "$RUN/smoke-run.log"
