#!/bin/bash
set -euo pipefail
run=/tmp/a2-m12-doe-guard-local-01
rtl=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl
repo=/tmp/a2-m12-local-source
gcc_dir=/Users/danielellerbrock/projects/iverilog_uvm/evidence/caliptra-exact-riscv-toolchain-20260923/toolchain/bin
verilator_root=/tmp/a2-m12-local-tools/verilator-src
overlay="$run/overlay"
model="$run/model"
filelist="$overlay/config/caliptra_top_tb.vf"
axi_if_overlay="$overlay/rtl/src/axi/rtl/axi_if.sv"
soc_bfm_overlay="$overlay/tb/caliptra_top_tb_soc_bfm.sv"
checker_overlay="$overlay/asserts/caliptra_top_sva.sv"
mkdir -p "$overlay/config" "$overlay/tb" "$model"
test "$(git -C "$repo" rev-parse HEAD)" = ffc12ab427e961f40354f32a8e7a147e5d4e5764
test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
python3.12 "$run/prepare-verilator-filelist.py" "$rtl" "$repo" "$filelist" > "$run/filelist-manifest.txt"
python3.12 "$run/prepare_axi_if_overlay.py" "$rtl/src/axi/rtl/axi_if.sv" "$axi_if_overlay" >> "$run/filelist-manifest.txt"
python3.12 "$run/prepare-doe-status-trace.py" "$rtl" "$checker_overlay" > "$run/doe-trace-manifest.txt"
python3.12 /Users/danielellerbrock/projects/bfm-work/qd-bfm/evidence/caliptra-bfm-verilator-m12-20261017/doe-reset-delay/prepare-doe-status-reset-guard.py "$rtl" "$checker_overlay" > "$run/doe-reset-guard-manifest.txt"
python3.12 - "$filelist" "$axi_if_overlay" >> "$run/filelist-manifest.txt" <<'PY'
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
print(f"axi_if_overlay_filelist_entry={overlay}")
PY
sha256sum "$axi_if_overlay" > "$run/axi_if.overlay.sha256"
grep -Fq d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1 "$run/axi_if.overlay.sha256"
sha256sum "$checker_overlay" > "$run/doe.overlay.sha256"
export PATH="$gcc_dir:/opt/homebrew/opt/bison/bin:/opt/homebrew/opt/openssl@3/bin:/opt/homebrew/opt/mbedtls@3/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
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
