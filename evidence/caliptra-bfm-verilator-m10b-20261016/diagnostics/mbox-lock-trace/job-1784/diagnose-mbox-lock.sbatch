#!/usr/bin/env bash
#SBATCH --job-name=a2-m10b-mbox-trace
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m10b-mbox-lock-trace-20261016-05
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m10b-mbox-lock-trace-20261016-05/logs/diagnose-%j.out

set -euo pipefail

# The separate logger omits assertions so the known AW monitor does not stop before the MBOX read.
run="${RUN_DIR:?RUN_DIR must name a fresh run directory}"
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
openssl=/home/dsell/toolchains/iverilog-c339/openssl
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
axi_trace="$run/inputs/axi_if.trace.sv"
mbox_trace="$run/overlay/mbox_csr.trace.sv"
filelist="$run/overlay/config/caliptra_top_tb.vf"
model="$run/model/obj_dir/Vcaliptra_top_tb"

test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -x "$gcc_dir/riscv-none-elf-gcc"
mkdir -p "$run/overlay/config" "$run/overlay/tb" "$run/model" "$run/results" "$run/logs"
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$run/overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$run/overlay/config/caliptra_top_tb.vlt"
python3 "$run/prepare-verilator-filelist.py" "$rtl" "$run/model-source" "$filelist" > "$run/filelist-manifest.txt"
python3 - "$filelist" "$axi_trace" "$mbox_trace" >> "$run/filelist-manifest.txt" <<'PY'
import hashlib
import sys
from pathlib import Path

filelist, axi_trace, mbox_trace = map(Path, sys.argv[1:])
text = filelist.read_text()
axi_original = "${CALIPTRA_ROOT}/src/axi/rtl/axi_if.sv"
mbox_original = "${CALIPTRA_ROOT}/src/soc_ifc/rtl/mbox_csr.sv"
if text.count(axi_original) != 1 or text.count(mbox_original) != 1:
    raise SystemExit("expected exactly one AXI and mailbox CSR source entry")
text = text.replace(axi_original, str(axi_trace), 1)
text = text.replace(mbox_original, str(mbox_trace), 1)
if axi_original in text or mbox_original in text or text.count(str(axi_trace)) != 1 or text.count(str(mbox_trace)) != 1:
    raise SystemExit("diagnostic filelist overlay validation failed")
filelist.write_text(text)
print(f"filelist_sha256={hashlib.sha256(filelist.read_bytes()).hexdigest()}")
print(f"axi_if_trace_sha256={hashlib.sha256(axi_trace.read_bytes()).hexdigest()}")
print(f"mbox_csr_trace_sha256={hashlib.sha256(mbox_trace.read_bytes()).hexdigest()}")
PY

export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"
export CALIPTRA_ROOT="$rtl"
export CALIPTRA_AXI4PC_DIR="$rtl/src/integration/tb"
export CALIPTRA_PRIM_ROOT="$rtl/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
cd "$run/model"
"$verilator" --version > "$run/verilator.version"
/usr/bin/time -v -o "$run/build.resource" make -f "$rtl/tools/scripts/Makefile" \
    "CALIPTRA_ROOT=$rtl" \
    CALIPTRA_INTERNAL_TRNG=1 \
    "TBDIR=$run/overlay/tb" \
    "INCLUDES_DIR=$rtl/src/integration/test_suites/includes" \
    "BUILD_DIR=$run/model" \
    "VERILATOR=$verilator --Wno-fatal" \
    GCC_PREFIX=riscv-none-elf \
    VERILATOR_DEBUG= \
    VERILATOR_MAKE_FLAGS=OPT_FAST=-Os \
    "CFLAGS=-std=c++20 -I$rtl/src/integration/test_suites/libs/jtagdpi -I$rtl/src/integration/test_suites/libs/tcp_server" \
    "TB_DEFS=+define+CALIPTRA_INTERNAL_TRNG +define+CALIPTRA_BFM_CHECKER" \
    verilator-build > "$run/build.log" 2>&1
test -x "$model"
sha256sum "$model" > "$run/model.sha256"

mkdir -p "$run/results"
test ! -e "$run/results/smoke_test_mbox"
set +e
/usr/bin/time -v -o "$run/sim.resource" timeout --signal=TERM --kill-after=30s 180 \
    "$deps/bin/python3.12" "$run/run-verilator-top-case.py" \
    --source "$run/source" --rtl "$rtl" --model "$model" \
    --output "$run/results/smoke_test_mbox" --case smoke_test_mbox \
    --case-yaml smoke_test_mbox/smoke_test_mbox.yml --timeout 6873 \
    --c339-outcome PASS --c339-mcycle 74924 --c339-elapsed NA
rc=$?
set -e
printf 'wrapper_exit=%s completed_at=%s\n' "$rc" "$(date -Is)" > "$run/wrapper-exit.txt"
( cd "$run" && { find build.log build.resource filelist-manifest.txt model.sha256 verilator.version wrapper-exit.txt results -type f -print0 | sort -z | xargs -0 -r sha256sum; sha256sum sim.resource; } ) > "$run/SHA256SUMS"
exit 0
