#!/bin/bash
#SBATCH --job-name=bfm-rand-reset-3127
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/bfm-rand-reset-c339-20261010-02
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/bfm-rand-reset-c339-20261010-02/logs/%x-%j.out

set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/bfm-rand-reset-c339-20261010-02
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/bfm-rand-reset-c339-20261010-01
BUILT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
PRIOR=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-11
GCC_RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-10
QD="$BASE/source/qd-bfm"
IVERILOG_SRC="$BUILT/source/iverilog-uvm"
RTL="$PRIOR/source/caliptra-rtl"
ENV="$BUILT/deps"
IVERILOG="$BUILT/toolchain/iverilog/bin"
GCC="$GCC_RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-"
JTAG_VPI="$GCC_RUN/jtagdpi/jtagdpi.vpi"
QD_SHA=708e51cd304422f367a61064449c5617fc97fec6
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
UVM_SHA=78c06547a2a0a29b3dc9dcafae62b75b2ff61544
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_BRIDGE_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0
JTAG_VPI_SHA=34bb301fe6ec5e6b50fba076d433310c8168a628aa3a4f8f81837324823d0d07
RUNNER_SHA=ea57294b045c7cae66a8aa6b93692a4c1ae8b343160624e0f137b71d855c6cb0
TRACE_SOURCE_SHA=cf378ed88ab6c3ec39fd38d3767d64a5598ad05a7afee63e90b5799743e09ae5

test "$(git -C "$QD" rev-parse HEAD)" = "$QD_SHA"
test -z "$(git -C "$QD" status --porcelain --untracked-files=all)"
test "$(sha256sum "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" | cut -d' ' -f1)" = "$RUNNER_SHA"
test "$(sha256sum "$QD/dv/caliptra_bfm/uvm/tests/sim-axi-trace-vpi.c" | cut -d' ' -f1)" = "$TRACE_SOURCE_SHA"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test "$(git -C "$IVERILOG_SRC/uvm-core" rev-parse HEAD)" = "$UVM_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_BRIDGE_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp" && test -x "$IVERILOG/iverilog-vpi"
test -x "${GCC}gcc" && test -x "$ENV/bin/python3.12" && test -f "$JTAG_VPI"

# Current firmware trace: start=2511; wait+2 asserts at 5640, after six W beats and before B.
printf 'QD=%s\nrunner-sha256=%s\ntrace-source-sha256=%s\nIcarus=%s\nUVM=%s\nCaliptra=%s\nAdams-Bridge=%s\nJTAG-VPI-SHA=%s\nreset-delay-cycles=3127\n' \
  "$QD_SHA" "$RUNNER_SHA" "$TRACE_SOURCE_SHA" "$IVERILOG_SHA" "$UVM_SHA" "$RTL_SHA" "$ADAMS_BRIDGE_SHA" "$JTAG_VPI_SHA" \
  | tee "$RUN/source-revisions.txt"
sha256sum "$JTAG_VPI" "$IVERILOG/iverilog" "$IVERILOG/vvp" | tee "$RUN/tool-binaries.sha256"
grep -q "$JTAG_VPI_SHA" "$RUN/tool-binaries.sha256"

export PATH="$ENV/bin:$IVERILOG:$GCC_RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin:$PATH"
export LD_LIBRARY_PATH="$BUILT/toolchain/iverilog/lib:$ENV/lib"
export CALIPTRA_MBEDTLS_ROOT="$ENV"
export CALIPTRA_RTL="$RTL"
export IVERILOG_BIN="$IVERILOG/iverilog"
export VVP_BIN="$IVERILOG/vvp"
export IVERILOG_SOURCE_ROOT="$IVERILOG_SRC"
export IVERILOG_VPI_BIN="$IVERILOG/iverilog-vpi"
export CALIPTRA_BFM_PROFILE="$RTL/src/integration/config/caliptra_top_tb.vf"
export CALIPTRA_GCC_PREFIX="$GCC"
export CALIPTRA_JTAGDPI_VPI="$JTAG_VPI"
export PYTHONPYCACHEPREFIX="$RUN/pycache"

python3.12 -m py_compile "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
set +e
/usr/bin/time -v -o "$RUN/logs/rand-dma-reset-resource.log" timeout --signal=TERM --kill-after=30s 7000s \
  python3.12 "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" \
  --case rand_test_dma --rand-dma-iterations 1 --force-first-rand-dma-reset \
  --rand-dma-reset-delay-cycles 3127 --fast-trng --fast-boot-data-preload \
  --quiet-firmware --trace-axi --output "$RUN/output/reset-3127-cycle" \
  > "$RUN/logs/rand-dma-reset.out" 2>&1
runner_status=$?
set -e
printf 'runner_exit=%s\n' "$runner_status" | tee "$RUN/runner-status.txt"
grep 'Maximum resident set size' "$RUN/logs/rand-dma-reset-resource.log" || true
exit "$runner_status"
