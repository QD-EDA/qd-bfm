#!/usr/bin/env bash
#SBATCH --job-name=a2-vlt-pr7176
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-pr7176-20261015-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-pr7176-20261015-01/logs/%x-%j.out

set -euo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-pr7176-20261015-01
src="$run/source"
prefix=/home/dsell/toolchains/verilator-pr7176-27d3c20
expected=27d3c20afb5cf83a67bcee39b0b783b82282e23e

test ! -e "$prefix"
printf 'host=%s\n' "$(hostname)" > "$run/host.txt"
date -Is >> "$run/host.txt"
gcc --version | head -1 >> "$run/host.txt"
g++ --version | head -1 >> "$run/host.txt"
git init "$src"
git -C "$src" remote add origin https://github.com/verilator/verilator.git
git -C "$src" fetch --depth=1 origin refs/pull/7176/head
git -C "$src" checkout --detach FETCH_HEAD
test "$(git -C "$src" rev-parse HEAD)" = "$expected"
git -C "$src" rev-parse HEAD > "$run/source.commit"
git -C "$src" status --short > "$run/source.status"
cd "$src"
autoconf
./configure --prefix="$prefix" > "$run/configure.log" 2>&1
/usr/bin/time -v -o "$run/build.resource" make -j4 > "$run/build.log" 2>&1
make install > "$run/install.log" 2>&1
"$prefix/bin/verilator" --version > "$run/verilator.version"
"$prefix/bin/verilator" --help > "$run/verilator.help" 2>&1
sha256sum "$prefix/bin/verilator" > "$run/verilator.sha256"
df -h /home/dsell >> "$run/host.txt"
