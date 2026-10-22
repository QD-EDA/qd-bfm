#!/usr/bin/env bash
#SBATCH --job-name=a2-m10-awtrace-build
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-02
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-02/logs/awtrace-build-%j.out

set -euo pipefail

root=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-02
diag="$root/diagnostics/aw-handshake"
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
repo="$root/model-source"
overlay="$diag/overlay"
model="$diag/model"
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin

test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
mkdir -p "$overlay/config" "$overlay/tb" "$model" "$diag/logs"
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
python3 "$root/prepare-verilator-filelist.py" "$rtl" "$repo" \
    "$overlay/config/caliptra_top_tb.vf" > "$diag/filelist-manifest.txt"

# Diagnostic-only display of the AXI AW values sampled on consecutive clock edges.
python3 - "$overlay/rtl/src/axi/rtl/axi_sub_wr.sv" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
source = p.read_text()
marker = "    // Handshake rules"
probe = """    logic m10_trace_prev_awvalid = 1'b0;
    logic m10_trace_prev_awready = 1'b0;
    always @(posedge clk) begin
        if ($time <= 10000 && (s_axi_if.awvalid || m10_trace_prev_awvalid))
            $display("M10_AW_TRACE time=%0t %m rst_n=%b awvalid=%b awready=%b awaddr=%h prev_awvalid=%b prev_awready=%b",
                     $time, rst_n, s_axi_if.awvalid, s_axi_if.awready, s_axi_if.awaddr,
                     m10_trace_prev_awvalid, m10_trace_prev_awready);
        m10_trace_prev_awvalid <= s_axi_if.awvalid;
        m10_trace_prev_awready <= s_axi_if.awready;
    end

    M10_AW_DROP_MATCH: assert property (@(posedge clk) disable iff (!rst_n !== 0)
        ((s_axi_if.awvalid && !s_axi_if.awready) ##1 !s_axi_if.awvalid) |-> 1'b0)
        else $display("M10_AW_SAMPLED_DROP time=%0t %m past_valid=%b past_ready=%b past_addr=%h sampled_valid=%b sampled_ready=%b sampled_rst_n=%b",
                      $time, $past(s_axi_if.awvalid), $past(s_axi_if.awready),
                      $past(s_axi_if.awaddr), $sampled(s_axi_if.awvalid),
                      $sampled(s_axi_if.awready), $sampled(rst_n));

"""
assert source.count(marker) == 1
assert "M10_AW_TRACE" not in source
p.write_text(source.replace(marker, probe + marker, 1))
assert "M10_AW_SAMPLED_DROP" in p.read_text()
assert "M10_AW_TRACE" in p.read_text()
PY

export PATH="$gcc_dir:$PATH"
export CALIPTRA_ROOT="$rtl"
export CALIPTRA_AXI4PC_DIR="$rtl/src/integration/tb"
export CALIPTRA_PRIM_ROOT="$rtl/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
cd "$model"
"$verilator" --version > "$diag/verilator.version"
/usr/bin/time -v -o "$diag/build.resource" make -f "$rtl/tools/scripts/Makefile" \
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
    verilator-build > "$diag/build.log" 2>&1

grep -Fq -- '--assert' "$diag/build.log"
grep -Fq ' +define+CLP_ASSERT_ON' "$diag/build.log"
test -x "$model/obj_dir/Vcaliptra_top_tb"
sha256sum "$model/obj_dir/Vcaliptra_top_tb" > "$diag/model.sha256"
date -Is > "$diag/build.completed.txt"
