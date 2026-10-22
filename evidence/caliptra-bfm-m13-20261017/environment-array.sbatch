#!/usr/bin/env bash
#SBATCH --job-name=bfm-m13-env-main
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --array=0-43%6
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-env-main-9b5fad2-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-env-main-9b5fad2-20261017-01/logs/slurm-%A_%a.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-env-main-9b5fad2-20261017-01
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL_ROOT=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
IVL_SRC=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source
IVERILOG=$IVL_ROOT/bin/iverilog
VVP=$IVL_ROOT/bin/vvp
TASKS=$RUN/environment-tasks.tsv

IFS=$'\t' read -r ENV_ID TOP SOURCE_REPO FILELIST < <(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$TASKS")
case "$SOURCE_REPO" in
  caliptra_v2.1.2) ROOT="$RTL"; EXTRA_INCLUDES=() ;;
  adams_bridge_v2.0.3)
    ROOT="$RTL/submodules/adams-bridge"
    EXTRA_INCLUDES=(-I "$ROOT/src/abr_prim/rtl" -I "$ROOT/src/abr_libs/rtl")
    ;;
  *) echo "unknown source repo: $SOURCE_REPO" >&2; exit 2 ;;
esac

TASK_DIR="$RUN/tasks/$ENV_ID"
mkdir -p "$TASK_DIR/runtime"
export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$RTL/submodules/adams-bridge"
export PATH="$IVL_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$IVL_ROOT/lib:$IVL_ROOT/lib64:/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

FILE="$ROOT/$FILELIST"
test -f "$FILE"
test -x "$IVERILOG" && test -x "$VVP"
test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test "$(git -C "$IVL_SRC" rev-parse HEAD)" = 9b5fad2afb4104caa816b257d5bccc40f01b8c66
TOP_FILE=$(find "$ROOT/src" -type f -path "*/tb/$TOP.sv" -print -quit)
if [[ -n "$TOP_FILE" ]]; then SOURCE_CWD=$(dirname "$TOP_FILE"); else SOURCE_CWD=$(dirname "$FILE"); fi
cp -a "$SOURCE_CWD/." "$TASK_DIR/runtime/"

{
  printf 'environment_id=%s\ntop=%s\nsource_repo=%s\nfilelist=%s\n' "$ENV_ID" "$TOP" "$SOURCE_REPO" "$FILELIST"
  printf 'host=%s\nslurm_job_id=%s\narray_task_id=%s\n' "$(hostname)" "$SLURM_JOB_ID" "$SLURM_ARRAY_TASK_ID"
  printf 'iverilog_source=9b5fad2afb4104caa816b257d5bccc40f01b8c66\ncaliptra_rtl=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e\nadams_bridge=b77e3d899e828d626cfc2a0d26a6b5704cc121e0\n'
  printf 'runtime_cwd=%s\n' "$SOURCE_CWD"
} > "$TASK_DIR/source-revisions.txt"
sha256sum "$FILE" > "$TASK_DIR/filelist.sha256"
sha256sum "$IVERILOG" "$VVP" > "$TASK_DIR/tool-binaries.sha256"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

start=$(date +%s)
set +e
/usr/bin/time -v -o "$TASK_DIR/compile.resource" timeout --signal=TERM --kill-after=30s 6900s \
  "$IVERILOG" -g2017 -gassertions -s "$TOP" "${EXTRA_INCLUDES[@]}" \
  -f "$FILE" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
compile_rc=$?
sim_rc=NOT_RUN
if [[ $compile_rc == 0 ]]; then
  elapsed_before_sim=$(( $(date +%s) - start ))
  remaining=$((6900 - elapsed_before_sim))
  if ((remaining > 0)); then
    cd "$TASK_DIR/runtime"
    /usr/bin/time -v -o "$TASK_DIR/sim.resource" timeout --signal=TERM --kill-after=30s "${remaining}s" \
      "$VVP" -n "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/sim.log" 2>&1
    sim_rc=$?
  else
    sim_rc=124
  fi
fi
if [[ $compile_rc != 0 ]]; then runner_rc=$compile_rc; elif [[ $sim_rc != 0 ]]; then runner_rc=$sim_rc; else runner_rc=0; fi
printf "compile_exit=%s\nsim_exit=%s\n" "$compile_rc" "$sim_rc" > "$TASK_DIR/stage-status.txt"
set -e
end=$(date +%s)
passes=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
failures=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR)' "$TASK_DIR/sim.log" 2>/dev/null || true)
{
  printf 'environment_id=%s\ntop=%s\nsource_repo=%s\nfilelist=%s\nrunner_exit=%s\ncompile_exit=%s\nsim_exit=%s\npass_markers=%s\nfailure_markers=%s\nelapsed_seconds=%s\n' \
    "$ENV_ID" "$TOP" "$SOURCE_REPO" "$FILELIST" "$runner_rc" "$compile_rc" "$sim_rc" "$passes" "$failures" "$((end-start))"
} > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
exit 0
