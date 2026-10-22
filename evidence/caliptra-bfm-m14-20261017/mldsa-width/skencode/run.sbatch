#!/usr/bin/env bash
#SBATCH --job-name=m14-width-skencode
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:30:00
#SBATCH --array=0-0%1
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m14-width-skencode-20261017-03
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m14-width-skencode-20261017-03/logs/slurm-%A_%a.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m14-width-skencode-20261017-03
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
ROOT="$RTL/submodules/adams-bridge"
IVL_ROOT=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
IVERILOG="$IVL_ROOT/bin/iverilog"
VVP="$IVL_ROOT/bin/vvp"
PYTHON_BIN=$(command -v python3)
IFS=$'\t' read -r ENV_ID TOP REL_FILELIST < <(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$RUN/tasks.tsv")
TASK_DIR="$RUN/tasks/$ENV_ID"
SOURCE_FILELIST="$ROOT/$REL_FILELIST"
FILELIST="$TASK_DIR/$TOP.vf"

test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$ROOT" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test "$(git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD)" = 9b5fad2afb4104caa816b257d5bccc40f01b8c66
test -x "$IVERILOG" && test -x "$VVP" && test -x "$PYTHON_BIN" && test -f "$SOURCE_FILELIST"
test -s "$RUN/overlay/skencode_tb.sv"

export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$ROOT"
export LD_LIBRARY_PATH="$IVL_ROOT/lib:$IVL_ROOT/lib64:/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

mkdir -p "$TASK_DIR/runtime"
sed "s#\${ADAMSBRIDGE_ROOT}/src/sk_encode/tb/skencode_tb.sv#$RUN/overlay/skencode_tb.sv#" \
  "$SOURCE_FILELIST" > "$FILELIST"
TOP_FILE=$(find "$ROOT/src" -type f -path "*/tb/$TOP.sv" -print -quit)
test -n "$TOP_FILE"
cp -a "$(dirname "$TOP_FILE")/." "$TASK_DIR/runtime/"
{
  printf 'host=%s\nslurm_job_id=%s\narray_task_id=%s\n' "$(hostname)" "$SLURM_JOB_ID" "$SLURM_ARRAY_TASK_ID"
  printf 'environment_id=%s\ntop=%s\nsource_filelist=%s\n' "$ENV_ID" "$TOP" "$REL_FILELIST"
  printf 'iverilog_source=9b5fad2afb4104caa816b257d5bccc40f01b8c66\ncaliptra_rtl=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e\nadams_bridge=b77e3d899e828d626cfc2a0d26a6b5704cc121e0\n'
  printf 'overlay=testbench uses ABR_MEM_ADDR_WIDTH for its width default and binds existing dut.error_flag for the obsolete output; comparisons and negative-test expectations unchanged\n'
  printf 'python=%s\n' "$PYTHON_BIN"
  "$PYTHON_BIN" --version
} > "$TASK_DIR/source-revisions.txt"
sha256sum "$ROOT/src/abr_top/rtl/abr_params_pkg.sv" "$SOURCE_FILELIST" "$FILELIST" "$RUN/overlay/skencode_tb.sv" "$TOP_FILE" "$(dirname "$TOP_FILE")/pack_eta.py" "$PYTHON_BIN" "$IVERILOG" "$VVP" > "$TASK_DIR/input-hashes.txt"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

start=$(date +%s)
set +e
/usr/bin/time -v -o "$TASK_DIR/compile.resource" timeout --signal=TERM --kill-after=10s 600s \
  "$IVERILOG" -g2017 -gassertions -s "$TOP" \
  -I "$ROOT/src/abr_prim/rtl" -I "$ROOT/src/abr_libs/rtl" \
  -f "$FILELIST" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
compile_rc=$?
sim_rc=NOT_RUN
if [[ $compile_rc == 0 ]]; then
  remaining=$((600 - ($(date +%s) - start)))
  if ((remaining > 0)); then
    cd "$TASK_DIR/runtime"
    /usr/bin/time -v -o "$TASK_DIR/sim.resource" timeout --signal=TERM --kill-after=10s "${remaining}s" \
      "$VVP" -n "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/sim.log" 2>&1
    sim_rc=$?
  else
    sim_rc=124
  fi
fi
runner_rc=$compile_rc
if [[ $compile_rc == 0 ]]; then runner_rc=$sim_rc; fi
set -e
end=$(date +%s)
passes=$(grep -Eic 'Test passed|TESTCASE PASSED|test.*success|success.*test' "$TASK_DIR/sim.log" 2>/dev/null || true)
failures=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR|Test failed|ERROR:|Error:)' "$TASK_DIR/sim.log" 2>/dev/null || true)
vectors=present
for vector in input_sk.hex output_encoded_sk.hex error_input_sk.hex error_output_encoded_sk.hex; do
  if ! test -s "$TASK_DIR/runtime/$vector"; then vectors=missing; fi
done
completed=$(grep -Fc 'Test completed' "$TASK_DIR/sim.log" 2>/dev/null || true)
mismatches=$(grep -Fc 'Error: Output mismatch' "$TASK_DIR/sim.log" 2>/dev/null || true)
unexpected_error_flag=$(grep -Fc 'Error: Error flag should have been asserted' "$TASK_DIR/sim.log" 2>/dev/null || true)
find "$TASK_DIR/runtime" -type f -print0 | sort -z | xargs -0 sha256sum > "$TASK_DIR/runtime-files.sha256"
{
  printf 'environment_id=%s\ntop=%s\nrunner_exit=%s\ncompile_exit=%s\nsim_exit=%s\n' "$ENV_ID" "$TOP" "$runner_rc" "$compile_rc" "$sim_rc"
  printf 'pass_marker_matches=%s\nfailure_marker_matches=%s\nvectors=%s\ncomparison_completions=%s\nmismatch_messages=%s\nunexpected_error_flag_messages=%s\nelapsed_seconds=%s\n' "$passes" "$failures" "$vectors" "$completed" "$mismatches" "$unexpected_error_flag" "$((end-start))"
} > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
