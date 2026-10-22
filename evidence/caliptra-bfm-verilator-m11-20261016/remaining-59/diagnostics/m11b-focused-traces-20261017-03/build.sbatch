#!/usr/bin/env bash
#SBATCH --job-name=a2-m11b-trace-rebuild
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-03
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-03/logs/build-%j.out

set -euo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-03
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
repo="$run/source"
overlay="$run/overlay"
model="$run/model"
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
axi_if_overlay="$overlay/rtl/src/axi/rtl/axi_if.sv"
filelist="$overlay/config/caliptra_top_tb.vf"

mkdir -p "$overlay/config" "$overlay/tb" "$model" "$run/logs"
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -x "$gcc_dir/riscv-none-elf-gcc"
python3 "$run/prepare-verilator-filelist.py" "$rtl" "$repo" "$filelist" > "$run/filelist-manifest.txt"
python3 "$run/prepare_axi_if_overlay.py" "$rtl/src/axi/rtl/axi_if.sv" "$axi_if_overlay" >> "$run/filelist-manifest.txt"
sha256sum "$axi_if_overlay" > "$run/axi_if.overlay.sha256"
grep -Fq d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1 "$run/axi_if.overlay.sha256"
python3 - "$filelist" "$axi_if_overlay" >> "$run/filelist-manifest.txt" <<'PY'
import hashlib
import sys
from pathlib import Path

filelist, overlay = map(Path, sys.argv[1:])
text = filelist.read_text()
pinned = "${CALIPTRA_ROOT}/src/axi/rtl/axi_if.sv"
if text.count(pinned) != 1:
    raise SystemExit(f"expected one pinned axi_if entry, found {text.count(pinned)}")
text = text.replace(pinned, str(overlay), 1)
if pinned in text or text.count(str(overlay)) != 1:
    raise SystemExit("axi_if filelist overlay check failed")
filelist.write_text(text)
print(f"verilator_filelist_sha256={hashlib.sha256(filelist.read_bytes()).hexdigest()}")
PY
python3 "$run/prepare_m11b_traces.py" "$rtl" "$filelist" "$overlay" > "$run/trace-overlay-manifest.txt"

test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
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

grep -Fq -- '--assert' "$run/build.log"
grep -Fq ' +define+CLP_ASSERT_ON' "$run/build.log"
test -x "$model/obj_dir/Vcaliptra_top_tb"
sha256sum "$model/obj_dir/Vcaliptra_top_tb" > "$run/model.sha256"
du -sb "$model" > "$run/model.bytes"
date -Is > "$run/build.completed.txt"
