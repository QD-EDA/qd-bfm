#!/usr/bin/env bash
#SBATCH --job-name=m13-decompose-gate
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-decompose-alias-gate-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-decompose-alias-gate-20261017-01/logs/slurm-%j.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-decompose-alias-gate-20261017-01
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
ROOT="$RTL/submodules/adams-bridge"
IVL_ROOT=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
IVERILOG="$IVL_ROOT/bin/iverilog"
VVP="$IVL_ROOT/bin/vvp"
TOP=decompose_tb
SOURCE_TB="$ROOT/src/decompose/tb/$TOP.sv"
SOURCE_FILELIST="$ROOT/src/decompose/config/decompose_tb.vf"
TASK_DIR="$RUN/tasks/$TOP"
FILELIST="$RUN/overlay/decompose_tb.vf"

test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$ROOT" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test "$(git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD)" = 9b5fad2afb4104caa816b257d5bccc40f01b8c66
test -x "$IVERILOG" && test -x "$VVP"
test -f "$RUN/overlay/abr_params_pkg.sv" && test -f "$RUN/overlay/decompose_tb.sv"

export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$ROOT"
export LD_LIBRARY_PATH="$IVL_ROOT/lib:$IVL_ROOT/lib64:/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

mkdir -p "$TASK_DIR/runtime"
python3 - "$SOURCE_TB" "$RUN/overlay/decompose_tb.sv" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text()
old = "    .decompose_done(),\n    .w1_encode_done()\n"
new = "    .decompose_done()\n"
if source.count(old) != 1:
    raise SystemExit("expected one exact obsolete-port sequence")
Path(sys.argv[2]).write_text(source.replace(old, new, 1))
PY
sed "s#\${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv#$RUN/overlay/abr_params_pkg.sv#; s#\${ADAMSBRIDGE_ROOT}/src/decompose/tb/decompose_tb.sv#$RUN/overlay/decompose_tb.sv#" \
  "$SOURCE_FILELIST" > "$FILELIST"
grep -Fxc "$RUN/overlay/abr_params_pkg.sv" "$FILELIST" | grep -qx 1
grep -Fxc "$RUN/overlay/decompose_tb.sv" "$FILELIST" | grep -qx 1
TOP_FILE=$(find "$ROOT/src" -type f -path "*/tb/$TOP.sv" -print -quit)
test -n "$TOP_FILE"
cp -a "$(dirname "$TOP_FILE")/." "$TASK_DIR/runtime/"

{
  printf 'host=%s\nslurm_job_id=%s\n' "$(hostname)" "$SLURM_JOB_ID"
  printf 'environment_id=adams-bridge-v2-0-3-decompose_tb\ntop=%s\n' "$TOP"
  printf 'iverilog_source=9b5fad2afb4104caa816b257d5bccc40f01b8c66\ncaliptra_rtl=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e\nadams_bridge=b77e3d899e828d626cfc2a0d26a6b5704cc121e0\n'
  printf 'overlay=package width alias plus removal of obsolete w1_encode_done port\n'
} > "$TASK_DIR/source-revisions.txt"
sha256sum "$ROOT/src/abr_top/rtl/abr_params_pkg.sv" "$SOURCE_TB" "$SOURCE_FILELIST" \
  "$RUN/overlay/abr_params_pkg.sv" "$RUN/overlay/decompose_tb.sv" "$FILELIST" "$IVERILOG" "$VVP" \
  > "$TASK_DIR/input-hashes.txt"
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
{
  printf 'environment_id=adams-bridge-v2-0-3-decompose_tb\ntop=%s\nrunner_exit=%s\ncompile_exit=%s\nsim_exit=%s\n' "$TOP" "$runner_rc" "$compile_rc" "$sim_rc"
  printf 'elapsed_seconds=%s\n' "$((end-start))"
} > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
