#!/usr/bin/env bash
#SBATCH --job-name=caliptra-env04
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --array=0-2%3
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/env-matrix-c339-20261011-04
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/env-matrix-c339-20261011-04/logs/slurm-%A_%a.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/env-matrix-c339-20261011-04
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$RUN/source"
TASKS="$RUN/source/tasks.tsv"
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"

IFS=$'\t' read -r ENV_ID TOP SOURCE_REPO FILELIST < <(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$TASKS")
case "$SOURCE_REPO" in
  caliptra_v2.1.2) ROOT="$RTL" ;;
  adams_bridge_v2.0.3) ROOT="$RTL/submodules/adams-bridge" ;;
  *) echo "unknown source repo: $SOURCE_REPO" >&2; exit 2 ;;
esac

TASK_DIR="$RUN/tasks/$ENV_ID"
mkdir -p "$TASK_DIR"
export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$RTL/submodules/adams-bridge"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export RUN BASE RTL IVERILOG VVP TASK_DIR FILE TOP

FILE="$ROOT/$FILELIST"
test -f "$FILE"
TOP_FILE=$(find "$ROOT/src" -type f -path "*/tb/$TOP.sv" -print -quit)
if [[ -n "$TOP_FILE" ]]; then
  SOURCE_CWD=$(dirname "$TOP_FILE")
else
  SOURCE_CWD=$(dirname "$FILE")
fi
mkdir -p "$TASK_DIR/runtime"
cp -a "$SOURCE_CWD/." "$TASK_DIR/runtime/"
if [[ "$TOP" == ntt_top_tb ]]; then
  cp -a "$SOURCE_CWD/test_vectors/." "$TASK_DIR/runtime/"
  sha256sum "$SOURCE_CWD"/test_vectors/* > "$TASK_DIR/vector-inputs.sha256"
fi
test "$(cat "$RUN/source/caliptra-rtl.commit")" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$BASE/source/iverilog-uvm" rev-parse HEAD)" = c339b9f2287a743aeb7ab6de6528e8d34a4dd602
test -z "$(git -C "$BASE/source/iverilog-uvm" status --porcelain --untracked-files=all)"
test -x "$IVERILOG" && test -x "$VVP"
printf '%s\n' "$ENV_ID" "$TOP" "$SOURCE_REPO" "$FILELIST" > "$TASK_DIR/row.txt"
cat "$RUN/source/revisions.txt" > "$TASK_DIR/source-revisions.txt"
sha256sum "$FILE" > "$TASK_DIR/filelist.sha256"
sha256sum "$IVERILOG" "$VVP" > "$TASK_DIR/tool-binaries.sha256"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

start=$(date +%s)
runner_rc=0
set +e
timeout --signal=TERM --kill-after=30s 7100s bash -c '
  set +e
  /usr/bin/time -v -o "$TASK_DIR/compile.resource" "$IVERILOG" -g2017 -gassertions -s "$TOP" -f "$FILE" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
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
'
runner_rc=$?
set -e
end=$(date +%s)
compile_rc=NOT_RECORDED
sim_rc=NOT_RECORDED
if [[ -f "$TASK_DIR/stage-status.txt" ]]; then
  compile_rc=$(sed -n 's/^compile_exit=//p' "$TASK_DIR/stage-status.txt")
  sim_rc=$(sed -n 's/^sim_exit=//p' "$TASK_DIR/stage-status.txt")
fi
passes=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
failures=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR)' "$TASK_DIR/sim.log" 2>/dev/null || true)
{
  printf 'environment_id=%s\ntop=%s\nsource_repo=%s\nfilelist=%s\nrunner_exit=%s\ncompile_exit=%s\nsim_exit=%s\npass_markers=%s\nfailure_markers=%s\nelapsed_seconds=%s\n' \
    "$ENV_ID" "$TOP" "$SOURCE_REPO" "$FILELIST" "$runner_rc" "$compile_rc" "$sim_rc" "$passes" "$failures" "$((end-start))"
} > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
exit 0
