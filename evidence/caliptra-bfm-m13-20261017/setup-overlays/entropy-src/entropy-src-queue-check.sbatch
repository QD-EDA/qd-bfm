#!/usr/bin/env bash
#SBATCH --job-name=m13-entropy-check
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-entropy-src-check-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-entropy-src-check-20261017-01/logs/slurm-%j.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-entropy-src-check-20261017-01
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL_ROOT=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
IVERILOG="$IVL_ROOT/bin/iverilog"
VVP="$IVL_ROOT/bin/vvp"
TOP=entropy_src_tb
SOURCE_TB="$RTL/src/entropy_src/tb/$TOP.sv"
SOURCE_FILELIST="$RTL/src/entropy_src/config/entropy_src_tb.vf"
TASK_DIR="$RUN/tasks/$TOP"
FILELIST="$RUN/overlay/entropy_src_tb.vf"

test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD)" = 9b5fad2afb4104caa816b257d5bccc40f01b8c66
test -x "$IVERILOG" && test -x "$VVP"
test -f "$RUN/overlay/entropy_src_tb.sv" && test -f "$FILELIST"

export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export LD_LIBRARY_PATH="$IVL_ROOT/lib:$IVL_ROOT/lib64:/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

mkdir -p "$TASK_DIR/runtime"
TOP_FILE="$RTL/src/entropy_src/tb/$TOP.sv"
cp -a "$(dirname "$TOP_FILE")/." "$TASK_DIR/runtime/"
{
  printf 'host=%s\nslurm_job_id=%s\n' "$(hostname)" "$SLURM_JOB_ID"
  printf 'environment_id=caliptra-v2-1-2-entropy_src_tb\ntop=%s\n' "$TOP"
  printf 'iverilog_source=9b5fad2afb4104caa816b257d5bccc40f01b8c66\ncaliptra_rtl=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e\n'
  printf 'overlay=diagnostic-only queue-size displays around the existing 4-word response comparison\n'
} > "$TASK_DIR/source-revisions.txt"
sha256sum "$SOURCE_TB" "$SOURCE_FILELIST" "$RUN/overlay/entropy_src_tb.sv" "$FILELIST" "$IVERILOG" "$VVP" > "$TASK_DIR/input-hashes.txt"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

start=$(date +%s)
set +e
/usr/bin/time -v -o "$TASK_DIR/compile.resource" timeout --signal=TERM --kill-after=10s 600s \
  "$IVERILOG" -g2017 -gassertions -s "$TOP" -f "$FILELIST" \
  -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
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
passes=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
failures=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR)' "$TASK_DIR/sim.log" 2>/dev/null || true)
{
  printf 'environment_id=caliptra-v2-1-2-entropy_src_tb\ntop=%s\nrunner_exit=%s\ncompile_exit=%s\nsim_exit=%s\n' "$TOP" "$runner_rc" "$compile_rc" "$sim_rc"
  printf 'pass_markers=%s\nfailure_markers=%s\nelapsed_seconds=%s\n' "$passes" "$failures" "$((end-start))"
} > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
