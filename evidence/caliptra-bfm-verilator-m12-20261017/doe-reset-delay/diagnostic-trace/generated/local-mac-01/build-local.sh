#!/bin/bash
set -euo pipefail
run=/tmp/a2-m12-doe-local-01
rtl=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl
repo=/tmp/a2-m12-local-source
gcc_dir=/Users/danielellerbrock/projects/iverilog_uvm/evidence/caliptra-exact-riscv-toolchain-20260923/toolchain/bin
verilator_root=/tmp/a2-m12-local-tools/verilator-src
overlay="$run/overlay"
model="$run/model"
filelist="$overlay/config/caliptra_top_tb.vf"
mkdir -p "$overlay/config" "$overlay/tb" "$model"
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
test "$(git -C "$repo" rev-parse HEAD)" = ffc12ab427e961f40354f32a8e7a147e5d4e5764
test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -x "$gcc_dir/riscv-none-elf-gcc"
export PATH="$gcc_dir:/opt/homebrew/opt/bison/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export CALIPTRA_ROOT="$rtl"
export CALIPTRA_AXI4PC_DIR="$rtl/src/integration/tb"
export CALIPTRA_PRIM_ROOT="$rtl/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export VERILATOR_ROOT="$verilator_root"
cd "$model"
"$verilator_root/bin/verilator" --version > "$run/verilator.version"
make -f "$rtl/tools/scripts/Makefile" \
  "CALIPTRA_ROOT=$rtl" \
  CALIPTRA_INTERNAL_TRNG=1 \
  "TBDIR=$overlay/tb" \
  "INCLUDES_DIR=$rtl/src/integration/test_suites/includes" \
  "BUILD_DIR=$model" \
  "VERILATOR=$verilator_root/bin/verilator --Wno-fatal --assert" \
  GCC_PREFIX=riscv-none-elf \
  "VERILATOR_DEBUG=" \
  "VERILATOR_MAKE_FLAGS=-j 3 OPT_FAST=-Os" \
  "CFLAGS=-std=c++20 -I$rtl/src/integration/test_suites/libs/jtagdpi -I$rtl/src/integration/test_suites/libs/tcp_server" \
  "TB_DEFS=+define+CALIPTRA_INTERNAL_TRNG +define+CALIPTRA_BFM_CHECKER +define+CLP_ASSERT_ON" \
  verilator-build > "$run/build.log" 2>&1
rg -Fq -- '--assert' "$run/build.log"
rg -Fq ' +define+CLP_ASSERT_ON' "$run/build.log"
test -x "$model/obj_dir/Vcaliptra_top_tb"
shasum -a 256 "$model/obj_dir/Vcaliptra_top_tb" > "$run/model.sha256"
du -sh "$model" > "$run/model.size"
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$run/build.completed.txt"
