#!/usr/bin/env bash
#SBATCH --job-name=a2-mldsa-alias
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --array=0-7%4
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/env-mldsa-alias-matrix-c339-20261011-03
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/env-mldsa-alias-matrix-c339-20261011-03/logs/slurm-%A_%a.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/env-mldsa-alias-matrix-c339-20261011-03
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$RUN/source"
ROOT="$RTL/submodules/adams-bridge"
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
IFS=$'\t' read -r ENV_ID TOP SOURCE_REPO FILELIST < <(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$RUN/alias-tasks.tsv")
export ROOT IVERILOG VVP TOP FILELIST
test "$SOURCE_REPO" = adams_bridge_v2.0.3
test -f "$ROOT/$FILELIST"
TOP_FILE=$(find "$ROOT/src" -type f -path "*/tb/$TOP.sv" -print -quit)
test -n "$TOP_FILE"
TASK_DIR="$RUN/tasks/$ENV_ID"
export TASK_DIR
mkdir -p "$TASK_DIR/runtime"
cp -a "$(dirname "$TOP_FILE")/." "$TASK_DIR/runtime/"

export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$ROOT"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
test "$(cat "$RUN/source/caliptra-rtl.commit")" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$BASE/source/iverilog-uvm" rev-parse HEAD)" = c339b9f2287a743aeb7ab6de6528e8d34a4dd602
test -z "$(git -C "$BASE/source/iverilog-uvm" status --porcelain --untracked-files=all)"
test -x "$IVERILOG" && test -x "$VVP"
printf '%s\t%s\t%s\t%s\n' "$ENV_ID" "$TOP" "$SOURCE_REPO" "$FILELIST" > "$TASK_DIR/row.txt"
cat "$RUN/source/revisions.txt" > "$TASK_DIR/source-revisions.txt"
sha256sum "$ROOT/src/abr_top/rtl/abr_params_pkg.sv" "$ROOT/$FILELIST" "$IVERILOG" "$VVP" > "$TASK_DIR/input-hashes.txt"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

set +e
timeout --signal=TERM --kill-after=30s 6900s bash -c '
  set +e
  /usr/bin/time -v -o "$TASK_DIR/compile.resource" "$IVERILOG" -g2017 -gassertions -s "$TOP" \
    -I "$ROOT/src/abr_prim/rtl" -I "$ROOT/src/abr_libs/rtl" \
    -f "$ROOT/$FILELIST" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
  compile_rc=$?
  if [[ $compile_rc == 0 ]]; then
    cd "$TASK_DIR/runtime"
    /usr/bin/time -v -o "$TASK_DIR/sim.resource" "$VVP" -n "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/sim.log" 2>&1
    sim_rc=$?
  else
    sim_rc=NOT_RUN
  fi
  printf "compile_exit=%s\\nsim_exit=%s\\n" "$compile_rc" "$sim_rc" > "$TASK_DIR/stage-status.txt"
  [[ $compile_rc == 0 && $sim_rc == 0 ]]
' bash
runner_rc=$?
set -e
passes=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
failures=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR)' "$TASK_DIR/sim.log" 2>/dev/null || true)
{
  printf 'environment_id=%s\ntop=%s\nfilelist=%s\nrunner_exit=%s\n' "$ENV_ID" "$TOP" "$FILELIST" "$runner_rc"
  cat "$TASK_DIR/stage-status.txt" 2>/dev/null || printf 'compile_exit=TIMEOUT_OR_SETUP_FAILURE\nsim_exit=NOT_RECORDED\n'
  printf 'pass_markers=%s\nfailure_markers=%s\n' "$passes" "$failures"
} > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
exit 0
