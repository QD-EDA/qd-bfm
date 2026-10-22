#!/usr/bin/env bash
#SBATCH --job-name=a2-vlt-xsim-build11
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-11
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-11/logs/%x-%j.out

set -euo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-11
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
repo="$run/source"
overlay="$run/overlay"
model="$run/model-xsim"
verilator=/home/dsell/toolchains/verilator-pr7176-27d3c20/bin/verilator
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin

test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -x "$gcc_dir/riscv-none-elf-gcc"
test ! -e "$model"
test "$(cat "$run/source.commit")" = dd6d43d5416006a9e77f2458e8df2a5a754f86c7
test -f "$repo/dv/caliptra_bfm/caliptra_bfm.f"
for f in stage_sha256_wntz.py native_mlkem.c random_test_ml_kem.py stage_mldsa.py check_native_mlkem.py check_native_mldsa.py; do
    test -f "$repo/dv/caliptra_bfm/native_vectors/$f"
done
export PATH="$gcc_dir:$PATH"
"$gcc_dir/riscv-none-elf-gcc" --version > "$run/riscv-gcc.version"
sha256sum "$gcc_dir/riscv-none-elf-gcc" > "$run/riscv-gcc.sha256"
mkdir -p "$overlay/config" "$overlay/tb" "$model"
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
python3 "$run/prepare-verilator-filelist.py" "$rtl" "$repo" "$overlay/config/caliptra_top_tb.vf" > "$run/filelist-manifest.txt"

export CALIPTRA_ROOT="$rtl"
export CALIPTRA_AXI4PC_DIR="$rtl/src/integration/tb"
export CALIPTRA_PRIM_ROOT="$rtl/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
cd "$model"
"$verilator" --version > "$run/xsim-verilator.version"
/usr/bin/time -v -o "$run/xsim-build.resource" make -f "$rtl/tools/scripts/Makefile" \
    "CALIPTRA_ROOT=$rtl" \
    CALIPTRA_INTERNAL_TRNG=1 \
    "TBDIR=$overlay/tb" \
    "INCLUDES_DIR=$rtl/src/integration/test_suites/includes" \
    "BUILD_DIR=$model" \
    "VERILATOR=$verilator --x-sim --Wno-fatal" \
    GCC_PREFIX=riscv-none-elf \
    "VERILATOR_DEBUG=" \
    VERILATOR_MAKE_FLAGS=OPT_FAST=-Os \
    "CFLAGS=-std=c++20 -I$rtl/src/integration/test_suites/libs/jtagdpi -I$rtl/src/integration/test_suites/libs/tcp_server" \
    "TB_DEFS=+define+CALIPTRA_INTERNAL_TRNG +define+CALIPTRA_BFM_CHECKER" \
    verilator-build > "$run/xsim-build.log" 2>&1
test -x "$model/obj_dir/Vcaliptra_top_tb"
sha256sum "$model/obj_dir/Vcaliptra_top_tb" > "$run/model-xsim.sha256"
du -sb "$model" > "$run/model-xsim.bytes"
date -Is > "$run/xsim-completed.txt"
