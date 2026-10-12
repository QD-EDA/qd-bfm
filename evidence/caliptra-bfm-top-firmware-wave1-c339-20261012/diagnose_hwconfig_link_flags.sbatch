#!/usr/bin/env bash
#SBATCH --job-name=a2-hwcfg-flags
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:25:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m5-hwconfig-linkdiag-c339-20261012-02/logs/%x-%j.out

set -Eeuo pipefail

ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m5-hwconfig-linkdiag-c339-20261012-02
RTL=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-11/source/caliptra-rtl
DEPS=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/deps
GCC_BIN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-10/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin

test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
mkdir -p "$ROOT/gnu89-inline" "$ROOT/os" "$ROOT/o2-inline"
export PATH="$DEPS/bin:$GCC_BIN:$PATH"
export CALIPTRA_ROOT="$RTL"
export CALIPTRA_MBEDTLS_ROOT="$DEPS"

run_build() {
  local name=$1
  local flags=$2
  local dir="$ROOT/$name"
  set +e
  (cd "$dir" && make -f "$RTL/tools/scripts/Makefile" \
    TESTNAME=smoke_test_hw_config GCC_PREFIX=riscv-none-elf \
    CALIPTRA_INTERNAL_TRNG=1 PLAYBOOK_RANDOM_SEED=1 \
    BUILD_CFLAGS="$flags" program.hex) >"$dir/build.log" 2>&1
  local status=$?
  set -e
  printf 'host=%s\nrtl_commit=%s\nBUILD_CFLAGS=%s\nexit_code=%s\n' \
    "$(hostname)" "$(git -C "$RTL" rev-parse HEAD)" "$flags" "$status" \
    >"$dir/status.txt"
}

run_build gnu89-inline '-std=gnu11 -O2 -fgnu89-inline'
run_build os '-std=gnu11 -Os'
run_build o2-inline '-std=gnu11 -O2 -finline-functions'
