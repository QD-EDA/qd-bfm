#!/usr/bin/env bash
#SBATCH --job-name=caliptra-unit
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:40:00
#SBATCH --array=0-2%3
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/unit-unit-20261011-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/unit-unit-20261011-01/logs/slurm-%A_%a.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/unit-unit-20261011-01
RTL="$RUN/source/caliptra-rtl"
QD="$RUN/source/qd-bfm"
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
GUARD="$QD/scripts/run_with_memory_pressure_guard.py"

case "$SLURM_ARRAY_TASK_ID" in
  0) TOP=hmac_ctrl_tb; FILELIST="$RTL/src/hmac/config/hmac_ctrl_tb.vf" ;;
  1) TOP=sha256_ctrl_tb; FILELIST="$RTL/src/sha256/config/sha256_ctrl_tb.vf" ;;
  2) TOP=sha512_ctrl_32bit_tb; FILELIST="$RTL/src/sha512/config/sha512_ctrl_32bit_tb.vf" ;;
  *) echo "unexpected array task id: $SLURM_ARRAY_TASK_ID" >&2; exit 2 ;;
esac

TASK_DIR="$RUN/tasks/$TOP"
mkdir -p "$TASK_DIR"
export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export IVERILOG VVP TOP FILELIST TASK_DIR
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test "$(git -C "$BASE/source/iverilog-uvm" rev-parse HEAD)" = c339b9f2287a743aeb7ab6de6528e8d34a4dd602
test -z "$(git -C "$BASE/source/iverilog-uvm" status --porcelain --untracked-files=all)"
test -x "$IVERILOG" && test -x "$VVP"
{
  printf 'QD-BFM=%s (archive of feature-branch HEAD)\n' "$(cat "$RUN/source/qd-bfm-commit.txt")"
  printf 'Caliptra=%s (clean)\n' "$(git -C "$RTL" rev-parse HEAD)"
  printf 'Icarus=%s (clean)\n' "$(git -C "$BASE/source/iverilog-uvm" rev-parse HEAD)"
} > "$RUN/source-revisions.txt"
sha256sum "$IVERILOG" "$VVP" > "$RUN/tool-binaries.sha256"
sha256sum \
  "$RTL/src/hmac/config/hmac_ctrl_tb.vf" "$RTL/src/hmac/tb/hmac_ctrl_tb.sv" \
  "$RTL/src/sha256/config/sha256_ctrl_tb.vf" "$RTL/src/sha256/tb/sha256_ctrl_tb.sv" \
  "$RTL/src/sha512/config/sha512_ctrl_32bit_tb.vf" "$RTL/src/sha512/tb/sha512_ctrl_32bit_tb.sv" \
  > "$RUN/test-sources.sha256"
"$IVERILOG" -V > "$RUN/iverilog-version.txt" 2>&1

start=$(date +%s)
status=0
python3 "$GUARD" \
  --max-process-bytes 2800000000 \
  --min-available-bytes 8589934592 \
  --timeout-seconds 1200 \
  --log "$TASK_DIR/guard.log" -- \
  bash -c '
    set -euo pipefail
    cd "$TASK_DIR"
    /usr/bin/time -v -o compile.resource "$IVERILOG" -g2017 -gassertions -s "$TOP" -f "$FILELIST" -o "$TOP.vvp" >compile.log 2>&1
    /usr/bin/time -v -o sim.resource "$VVP" -n "$TOP.vvp" >sim.log 2>&1
  ' || status=$?
end=$(date +%s)

passes=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
failures=$(grep -Fc '* TESTCASE FAILED' "$TASK_DIR/sim.log" 2>/dev/null || true)
errors=$(grep -Eic '(\*\*\* ERROR: TC|TC[0-9]+: ERROR)' "$TASK_DIR/sim.log" 2>/dev/null || true)
result=UNVERIFIED
if [[ "$status" == 0 && "$passes" == 1 && "$failures" == 0 && "$errors" == 0 ]]; then
  result=PASS
fi
{
  printf 'test=%s\nresult=%s\nrunner_exit=%s\npass_markers=%s\nfail_markers=%s\nerror_markers=%s\nelapsed_seconds=%s\n' \
    "$TOP" "$result" "$status" "$passes" "$failures" "$errors" "$((end-start))"
} > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
[[ "$result" == PASS ]]
