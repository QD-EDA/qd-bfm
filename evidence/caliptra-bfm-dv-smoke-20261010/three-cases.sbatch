#!/bin/bash
#SBATCH --job-name=a2-dv-smoke
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --array=0-2%1
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/dv-smoke-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/dv-smoke-20261010-01/logs/%x-%A_%a.out

set -Eeuo pipefail
RUN_ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/dv-smoke-20261010-01
QD="$RUN_ROOT/source/qd-bfm"
BUILT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL_RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-11
GCC_RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-10
IVERILOG_SRC="$BUILT/source/iverilog-uvm"
RTL="$RTL_RUN/source/caliptra-rtl"
ENV="$BUILT/deps"
IVERILOG="$BUILT/toolchain/iverilog/bin"
GCC="$GCC_RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-"
JTAG_VPI="$GCC_RUN/jtagdpi/jtagdpi.vpi"
QD_SHA=72d965adc2d7e9bfdbadaa3348add9781319bd1c
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
UVM_SHA=78c06547a2a0a29b3dc9dcafae62b75b2ff61544
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_BRIDGE_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0
JTAG_VPI_SHA=34bb301fe6ec5e6b50fba076d433310c8168a628aa3a4f8f81837324823d0d07
RUNNER_SHA=ea57294b045c7cae66a8aa6b93692a4c1ae8b343160624e0f137b71d855c6cb0

case "${SLURM_ARRAY_TASK_ID:?}" in
  0) RUN_NAME=smoke_test_dma; RUN_ARGS=() ;;
  1) RUN_NAME=smoke_test_dma_aes_gcm_short_1_dword; RUN_ARGS=(--first-aes-case-diagnostic) ;;
  2) RUN_NAME=rand_test_dma; RUN_ARGS=(--rand-dma-iterations 1) ;;
  *) echo "unsupported array task id: $SLURM_ARRAY_TASK_ID" >&2; exit 64 ;;
esac

RUN="$RUN_ROOT/runs/$RUN_NAME"
mkdir -p "$RUN/logs" "$RUN/pycache" "$RUN/output"
test "$(cat "$QD/COMMIT")" = "$QD_SHA"
test "$(sha256sum "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" | cut -d' ' -f1)" = "$RUNNER_SHA"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test "$(git -C "$IVERILOG_SRC/uvm-core" rev-parse HEAD)" = "$UVM_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_BRIDGE_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp" && test -x "$IVERILOG/iverilog-vpi"
test -x "${GCC}gcc" && test -x "$ENV/bin/python3.12" && test -f "$JTAG_VPI"

printf 'QD=%s\nIcarus=%s\nUVM=%s\nCaliptra=%s\nAdams-Bridge=%s\nJTAG-VPI-SHA=%s\narray-task-id=%s\ncase=%s\n' \
  "$QD_SHA" "$IVERILOG_SHA" "$UVM_SHA" "$RTL_SHA" "$ADAMS_BRIDGE_SHA" "$JTAG_VPI_SHA" \
  "$SLURM_ARRAY_TASK_ID" "$RUN_NAME" | tee "$RUN/source-revisions.txt"
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
/usr/bin/time -v -o "$RUN/logs/resource.log" timeout --signal=TERM --kill-after=30s 7000s \
  python3.12 "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" \
  --case "$RUN_NAME" "${RUN_ARGS[@]}" --fast-trng --fast-boot-data-preload \
  --quiet-firmware --output "$RUN/output/$RUN_NAME" \
  > "$RUN/logs/runner.log" 2>&1
runner_status=$?
set -e
printf 'runner_exit=%s\n' "$runner_status" | tee "$RUN/runner-status.txt"
grep 'Maximum resident set size' "$RUN/logs/resource.log" || true
exit "$runner_status"
