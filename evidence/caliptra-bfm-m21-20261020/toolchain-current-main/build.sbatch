#!/bin/bash
#SBATCH --job-name=m21-ivl-main
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-iverilog-main-cc25756d-20261020-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-iverilog-main-cc25756d-20261020-01/logs/build-%j.out
set -euo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-iverilog-main-cc25756d-20261020-01
PREFIX=/home/dsell/toolchains/iverilog-uvm-main-cc25756d187314742d347267c2a513b3e640a7fb
SRC="$RUN/source/iverilog-uvm"
SOURCE_COMMIT=cc25756d187314742d347267c2a513b3e640a7fb

mkdir -p "$RUN/source"
git init "$SRC"
git -C "$SRC" remote add origin https://github.com/dsellerbrock/iverilog-uvm.git
git -C "$SRC" fetch --depth=1 origin "$SOURCE_COMMIT"
git -C "$SRC" checkout --detach FETCH_HEAD
git -C "$SRC" submodule sync --recursive
git -C "$SRC" submodule update --init --recursive
test "$(git -C "$SRC" rev-parse HEAD)" = "$SOURCE_COMMIT"

cd "$SRC"
sh ./autoconf.sh
./configure --prefix="$PREFIX" --enable-libveriuser
make -j2
make install
{
  printf 'source_commit=%s\n' "$(git rev-parse HEAD)"
  printf 'uvm_core_commit=%s\n' "$(git -C uvm-core rev-parse HEAD)"
  printf 'built_at='; date -u +%FT%TZ
  printf 'host='; hostname
  "$PREFIX/bin/iverilog" -V 2>&1 | sed -n '1p'
  "$PREFIX/bin/vvp" -V 2>&1 | sed -n '1p'
  sha256sum "$PREFIX/bin/iverilog" "$PREFIX/bin/vvp"
} | tee "$RUN/toolchain-manifest.txt"
