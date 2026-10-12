#!/usr/bin/env bash
#SBATCH --job-name=a2-sharedfix
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=01:00:00
#SBATCH --array=0-3%4
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/sharedfix-rerun-c339-20261011-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/sharedfix-rerun-c339-20261011-01/logs/slurm-%A_%a.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/sharedfix-rerun-c339-20261011-01
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$RUN/source"
TASKS="$RUN/tasks.tsv"
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
IFS=$'\t' read -r ENV_ID TOP SOURCE_REPO FILELIST < <(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$TASKS")
case "$SOURCE_REPO" in
  caliptra_v2.1.2) ROOT="$RTL"; EXTRA_INCLUDES=() ;;
  adams_bridge_v2.0.3) ROOT="$RTL/submodules/adams-bridge"; EXTRA_INCLUDES=(-I "$ROOT/src/abr_prim/rtl" -I "$ROOT/src/abr_libs/rtl") ;;
  *) echo "unknown source repo: $SOURCE_REPO" >&2; exit 2 ;;
esac
FILE="$ROOT/$FILELIST"
TASK_DIR="$RUN/tasks/$ENV_ID"
TOP_FILE=$(find "$ROOT/src" -type f -path "*/tb/$TOP.sv" -print -quit)
test -f "$FILE" && test -n "$TOP_FILE"
mkdir -p "$TASK_DIR/runtime"
cp -a "$(dirname "$TOP_FILE")/." "$TASK_DIR/runtime/"
export CALIPTRA_ROOT="$RTL" CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb" ADAMSBRIDGE_ROOT="$RTL/submodules/adams-bridge"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="$RUN/python-env/bin:$PATH"
export RUN BASE RTL ROOT IVERILOG VVP TASK_DIR TOP FILE
printf '%s\t%s\t%s\t%s\n' "$ENV_ID" "$TOP" "$SOURCE_REPO" "$FILELIST" > "$TASK_DIR/row.txt"
cat "$RUN/source/revisions.txt" > "$TASK_DIR/source-revisions.txt"
sha256sum "$FILE" "$IVERILOG" "$VVP" > "$TASK_DIR/input-hashes.txt"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1
python3 --version > "$TASK_DIR/python-version.txt" 2>&1
python3 -m pip freeze > "$TASK_DIR/python-packages.txt" 2>&1 || true
start=$(date +%s)
set +e
timeout --signal=TERM --kill-after=30s 600s bash -c '
  set +e
  /usr/bin/time -v -o "$TASK_DIR/compile.resource" "$IVERILOG" -g2017 -gassertions -s "$TOP" "$@" -f "$FILE" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
  compile_rc=$?
  if [[ $compile_rc == 0 ]]; then
    cd "$TASK_DIR/runtime"
    /usr/bin/time -v -o "$TASK_DIR/sim.resource" "$VVP" -n "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/sim.log" 2>&1
    sim_rc=$?
  else sim_rc=NOT_RUN; fi
  printf "compile_exit=%s\\nsim_exit=%s\\n" "$compile_rc" "$sim_rc" > "$TASK_DIR/stage-status.txt"
  [[ $compile_rc == 0 && $sim_rc == 0 ]]
' bash "${EXTRA_INCLUDES[@]}"
runner_rc=$?
set -e
end=$(date +%s)
compile_rc=NOT_RECORDED; sim_rc=NOT_RECORDED
if [[ -f "$TASK_DIR/stage-status.txt" ]]; then
  compile_rc=$(sed -n 's/^compile_exit=//p' "$TASK_DIR/stage-status.txt")
  sim_rc=$(sed -n 's/^sim_exit=//p' "$TASK_DIR/stage-status.txt")
fi
passes=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
failures=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR|ERROR:|mismatch)' "$TASK_DIR/sim.log" 2>/dev/null || true)
printf 'environment_id=%s\ntop=%s\nfilelist=%s\nrunner_exit=%s\ncompile_exit=%s\nsim_exit=%s\npass_markers=%s\nfailure_markers=%s\nelapsed_seconds=%s\n' \
  "$ENV_ID" "$TOP" "$FILELIST" "$runner_rc" "$compile_rc" "$sim_rc" "$passes" "$failures" "$((end-start))" > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
exit 0
