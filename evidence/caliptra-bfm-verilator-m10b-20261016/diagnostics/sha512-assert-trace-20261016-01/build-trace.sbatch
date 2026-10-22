#!/usr/bin/env bash
#SBATCH --job-name=a2-m10b-sha-trace-build
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m10b-sha512-trace-20261016-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m10b-sha512-trace-20261016-01/logs/build-%j.out

set -euo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m10b-sha512-trace-20261016-01
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
overlay="$run/overlay"
model="$run/model"
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
axi_if_overlay="$overlay/rtl/src/axi/rtl/axi_if.sv"
sha512_overlay="$overlay/rtl/src/sha512/rtl/sha512.sv"
filelist="$overlay/config/caliptra_top_tb.vf"

test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
mkdir -p "$overlay/config" "$overlay/tb" "$model" "$run/logs"
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
python3 "$run/prepare-verilator-filelist.py" "$rtl" "$run/source" "$filelist" > "$run/filelist-manifest.txt"
python3 "$run/prepare_axi_if_overlay.py" "$rtl/src/axi/rtl/axi_if.sv" "$axi_if_overlay" >> "$run/filelist-manifest.txt"
sha256sum "$axi_if_overlay" > "$run/axi_if.overlay.sha256"
grep -Fq d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1 "$run/axi_if.overlay.sha256"
python3 "$run/add_sha512_trace.py" "$rtl/src/sha512/rtl/sha512.sv" "$sha512_overlay" > "$run/sha512-trace-overlay.txt"

python3 - "$filelist" "$axi_if_overlay" "$sha512_overlay" >> "$run/filelist-manifest.txt" <<'PY'
import hashlib
import sys
from pathlib import Path

filelist, axi, sha512 = map(Path, sys.argv[1:])
text = filelist.read_text()
replacements = {
    "$" + "{CALIPTRA_ROOT}/src/axi/rtl/axi_if.sv": axi,
    "$" + "{CALIPTRA_ROOT}/src/sha512/rtl/sha512.sv": sha512,
}
for pinned, overlay in replacements.items():
    if text.count(pinned) != 1:
        raise SystemExit(f"expected exactly one {pinned}, found {text.count(pinned)}")
    text = text.replace(pinned, str(overlay), 1)
    if text.count(str(overlay)) != 1:
        raise SystemExit(f"overlay filelist entry mismatch: {overlay}")
filelist.write_text(text)
print(f"verilator_filelist_sha256={hashlib.sha256(filelist.read_bytes()).hexdigest()}")
print(f"axi_if_overlay_filelist_entry={axi}")
print(f"sha512_trace_overlay_filelist_entry={sha512}")
PY

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
