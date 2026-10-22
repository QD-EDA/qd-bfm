#!/usr/bin/env bash
#SBATCH --job-name=a2-m9-cptra-trace
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/cptra-ss-dma-20261016-02
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/cptra-ss-dma-20261016-02/logs/%x-%j.out

set -euo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/cptra-ss-dma-20261016-02
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
openssl=/home/dsell/toolchains/iverilog-c339/openssl
repo="$run/source"
overlay="$run/overlay"
model="$run/model"
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin

test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -x "$verilator" && test -x "$deps/bin/python3.12"
test -x "$gcc_dir/riscv-none-elf-gcc" && test -x "$openssl/bin/openssl"
test -f "$run/prepare-verilator-filelist.py"
test -f "$run/run-verilator-top-case.py" && test -f "$run/run-selection.tsv"
mkdir -p "$overlay/config" "$overlay/tb" "$model" "$run/logs"

ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
python3 "$run/prepare-verilator-filelist.py" "$rtl" "$repo" "$overlay/config/caliptra_top_tb.vf" > "$run/filelist-manifest.txt"

python3 - "$rtl/src/axi/rtl/axi_dma_ctrl.sv" "$overlay/axi_dma_ctrl_trace.sv" <<'PY'
import hashlib
import sys
from pathlib import Path

source = Path(sys.argv[1])
output = Path(sys.argv[2])
text = source.read_text()
marker = "    genvar i;\n"
trace = """    integer m9_dma_trace_count;
    initial m9_dma_trace_count = 0;
    always @(posedge clk) begin
        if (dv && req_data.write && req_data.addr[11:0] == 12'h02c &&
            m9_dma_trace_count < 64) begin
            $display("M9DMA t=%0t dv=%0b write=%0b hold=%0b wr_stall=%0b fifo_valid=%0b fifo_ready=%0b depth=%0d full=%0b data=%08x swmod=%0b",
                     $time, dv, req_data.write, hold, reg_wr_stall,
                     fifo_w_valid, fifo_w_ready, fifo_depth, fifo_full,
                     req_data.wdata, hwif_out.write_data.wdata.swmod);
            m9_dma_trace_count = m9_dma_trace_count + 1;
        end
    end
"""
if text.count(marker) != 1:
    raise SystemExit("axi_dma_ctrl insertion point changed")
output.write_text(text.replace(marker, trace + marker))
print(f"source_sha256={hashlib.sha256(source.read_bytes()).hexdigest()}")
print(f"instrumented_sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")
PY

python3 - "$overlay/config/caliptra_top_tb.vf" "$overlay/axi_dma_ctrl_trace.sv" <<'PY'
import sys
from pathlib import Path

filelist = Path(sys.argv[1])
instrumented = Path(sys.argv[2])
text = filelist.read_text()
target = "${CALIPTRA_ROOT}/src/axi/rtl/axi_dma_ctrl.sv"
if text.count(target) != 1:
    raise SystemExit("expected one axi_dma_ctrl source in the generated filelist")
filelist.write_text(text.replace(target, str(instrumented)))
PY

export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"
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
    "VERILATOR=$verilator --Wno-fatal" \
    GCC_PREFIX=riscv-none-elf \
    "VERILATOR_DEBUG=" \
    VERILATOR_MAKE_FLAGS=OPT_FAST=-Os \
    "CFLAGS=-std=c++20 -I$rtl/src/integration/test_suites/libs/jtagdpi -I$rtl/src/integration/test_suites/libs/tcp_server" \
    "TB_DEFS=+define+CALIPTRA_INTERNAL_TRNG +define+CALIPTRA_BFM_CHECKER" \
    verilator-build > "$run/build.log" 2>&1

test -x "$model/obj_dir/Vcaliptra_top_tb"
sha256sum "$model/obj_dir/Vcaliptra_top_tb" > "$run/model.sha256"
sha256sum "$overlay/axi_dma_ctrl_trace.sv" "$overlay/config/caliptra_top_tb.vf" > "$run/overlay.sha256"

row=$(awk -F '\t' 'NR > 1 && $3 == "cptra_ss_test_rom" { print; exit }' "$run/run-selection.tsv")
test -n "$row"
IFS=$'\t' read -r index test_id testname case_dir case_yaml official_timeout timeout_basis \
    c339_outcome c339_mcycle c339_elapsed <<< "$row"
test "$testname" = cptra_ss_test_rom

set +e
/usr/bin/time -v -o "$run/diagnostic.resource" "$deps/bin/python3.12" \
    "$run/run-verilator-top-case.py" \
    --source "$repo" --rtl "$rtl" --model "$model/obj_dir/Vcaliptra_top_tb" \
    --output "$run/diagnostic-output" --case "$case_dir" --case-yaml "$case_yaml" \
    --timeout 600 --c339-outcome "$c339_outcome" \
    --c339-mcycle "$c339_mcycle" --c339-elapsed "$c339_elapsed" \
    > "$run/diagnostic-runner.log" 2>&1
runner_exit=$?
set -e
test -s "$run/diagnostic-output/result.json"
printf 'runner_exit=%s official_timeout_s=%s diagnostic_timeout_s=600\n' \
    "$runner_exit" "$official_timeout" > "$run/diagnostic-complete.txt"
date -Is >> "$run/diagnostic-complete.txt"
