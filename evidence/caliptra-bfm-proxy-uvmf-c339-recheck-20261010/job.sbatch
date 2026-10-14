#!/bin/bash
#SBATCH --job-name=a2-proxy-uvmf
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:15:00
#SBATCH --array=0-1%1
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/proxy-uvmf-c339-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/proxy-uvmf-c339-20261010-01/logs/%x-%A_%a.out

set -Eeuo pipefail
RUN_ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/proxy-uvmf-c339-20261010-01
QD="$RUN_ROOT/source/qd-bfm"
BUILT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL_RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-11
IVERILOG_SRC="$BUILT/source/iverilog-uvm"
RTL="$RTL_RUN/source/caliptra-rtl"
ENV="$BUILT/deps"
IVERILOG="$BUILT/toolchain/iverilog/bin"
QD_SHA=72d965adc2d7e9bfdbadaa3348add9781319bd1c
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
UVM_SHA=78c06547a2a0a29b3dc9dcafae62b75b2ff61544
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_BRIDGE_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0

case "${SLURM_ARRAY_TASK_ID:?}" in
  0) SUITE=pcrvault; SCRIPT=evidence/caliptra-bfm-pv-generated-uvmf-20261004/run.sh ;;
  1) SUITE=keyvault; SCRIPT=evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.sh ;;
  *) echo "unsupported array task id: $SLURM_ARRAY_TASK_ID" >&2; exit 64 ;;
esac
RUN="$RUN_ROOT/runs/$SUITE"
mkdir -p "$RUN/logs" "$RUN/pycache"

test "$(cat "$QD/COMMIT")" = "$QD_SHA"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test "$(git -C "$IVERILOG_SRC/uvm-core" rev-parse HEAD)" = "$UVM_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_BRIDGE_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp"

printf 'QD=%s\nIcarus=%s\nUVM=%s\nCaliptra=%s\nAdams-Bridge=%s\nsuite=%s\n' \
  "$QD_SHA" "$IVERILOG_SHA" "$UVM_SHA" "$RTL_SHA" "$ADAMS_BRIDGE_SHA" "$SUITE" \
  | tee "$RUN/source-revisions.txt"
sha256sum "$IVERILOG/iverilog" "$IVERILOG/vvp" > "$RUN/tool-binaries.sha256"

export PATH="$ENV/bin:$IVERILOG:$PATH"
export LD_LIBRARY_PATH="$BUILT/toolchain/iverilog/lib:$ENV/lib"
export CALIPTRA_ROOT="$RTL"
export CALIPTRA_MBEDTLS_ROOT="$ENV"
export IVERILOG_BIN="$IVERILOG/iverilog"
export VVP_BIN="$IVERILOG/vvp"
export IVERILOG_SOURCE_ROOT="$IVERILOG_SRC"
export CALIPTRA_BFM_SUMMARY_LOG="$RUN/logs/summary.log"
export PYTHONPYCACHEPREFIX="$RUN/pycache"

set +e
/usr/bin/time -v -o "$RUN/logs/resource.log" timeout --signal=TERM --kill-after=15s 600s \
  sh "$QD/$SCRIPT" > "$RUN/logs/runner.log" 2>&1
runner_status=$?
set -e
printf 'runner_exit=%s\n' "$runner_status" | tee "$RUN/runner-status.txt"
exit "$runner_status"
