#!/usr/bin/env bash
#SBATCH --job-name=a2-m10-vlt-assert-build
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-01/logs/build-%j.out

set -euo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-01
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
repo="$run/model-source"
overlay="$run/overlay"
model="$run/model"
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin

test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -x "$gcc_dir/riscv-none-elf-gcc"
mkdir -p "$overlay/config" "$overlay/tb" "$model"
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
python3 "$run/prepare-verilator-filelist.py" "$rtl" "$repo" "$overlay/config/caliptra_top_tb.vf" > "$run/filelist-manifest.txt"

export PATH="$gcc_dir:$PATH"
export CALIPTRA_ROOT="$rtl"
export CALIPTRA_AXI4PC_DIR="$rtl/src/integration/tb"
export CALIPTRA_PRIM_ROOT="$rtl/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
cd "$model"
"$verilator" --version > "$run/verilator.version"
/usr/bin/time -v -o "$run/build.resource" make -f "$rtl/tools/scripts/Makefile" \
    "CALIPTRA_ROOT=$rtl" \
    CALIPTRA_INTERNAL_TRNG=1 \
    "TBDIR=$overlay/tb" \
    "INCLUDES_DIR=$rtl/src/integration/test_suites/includes" \
    "BUILD_DIR=$model" \
    "VERILATOR=$verilator --Wno-fatal --assert" \
    GCC_PREFIX=riscv-none-elf \
    "VERILATOR_DEBUG=" \
    VERILATOR_MAKE_FLAGS=OPT_FAST=-Os \
    "CFLAGS=-std=c++20 -I$rtl/src/integration/test_suites/libs/jtagdpi -I$rtl/src/integration/test_suites/libs/tcp_server" \
    "TB_DEFS=+define+CALIPTRA_INTERNAL_TRNG +define+CALIPTRA_BFM_CHECKER +define+CLP_ASSERT_ON" \
    verilator-build > "$run/build.log" 2>&1

if ! grep -Fq -- '--assert' "$run/build.log" || ! grep -Fq ' +define+CLP_ASSERT_ON' "$run/build.log"; then
    echo "Build log is missing assertion enable flags." >&2
    exit 1
fi
test -x "$model/obj_dir/Vcaliptra_top_tb"
sha256sum "$model/obj_dir/Vcaliptra_top_tb" > "$run/model.sha256"
du -sb "$model" > "$run/model.bytes"
date -Is > "$run/build.completed.txt"
