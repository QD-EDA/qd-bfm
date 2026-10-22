#!/usr/bin/env bash
#SBATCH --job-name=bfm-m13-p2r-overlay
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-power2round-overlay-20261017-02
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-power2round-overlay-20261017-02/logs/%x-%j.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-power2round-overlay-20261017-02
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
ABR="$RTL/submodules/adams-bridge"
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
PYENV=/home/dsell/toolchains/python-3.14.4-numpy-2.5.4-a2-m13-20261017
TASK_DIR="$RUN/tasks/adams-bridge-v2-0-3-power2round_tb"
TOP=power2round_tb
FILELIST=src/power2round/config/power2round_tb.vf

mkdir -p "$TASK_DIR/runtime" "$TASK_DIR/python-cache"
cp -a "$ABR/src/power2round/tb/." "$TASK_DIR/runtime/"
export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$ABR"
export PATH="$PYENV/bin:$IVL/bin:$PATH"
export LD_LIBRARY_PATH="$IVL/lib:$IVL/lib64:/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONPYCACHEPREFIX="$TASK_DIR/python-cache"

test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$ABR" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test "$(git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD)" = 9b5fad2afb4104caa816b257d5bccc40f01b8c66
test -x "$PYENV/bin/python" && test -x "$IVL/bin/iverilog" && test -x "$IVL/bin/vvp"

{
  printf 'host=%s\nslurm_job_id=%s\ntop=%s\nfilelist=%s\n' "$(hostname)" "$SLURM_JOB_ID" "$TOP" "$FILELIST"
  printf 'caliptra_rtl=%s\nadams_bridge=%s\niverilog_source=%s\n' \
    "$(git -C "$RTL" rev-parse HEAD)" "$(git -C "$ABR" rev-parse HEAD)" \
    "$(git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD)"
  printf 'setup_overlay=PATH prepends protected Python 3.14.4 + NumPy 2.5.4 venv; no RTL/testbench source edits\n'
  "$PYENV/bin/python" --version
  "$PYENV/bin/python" -c 'import numpy; print("numpy=" + numpy.__version__)'
} > "$TASK_DIR/provenance.txt" 2>&1
sha256sum "$IVL/bin/iverilog" "$IVL/bin/vvp" "$PYENV/bin/python" \
  "$PYENV/lib/python3.14/site-packages/numpy/__init__.py" \
  "$ABR/src/power2round/tb/power2round.py" "$ABR/$FILELIST" > "$TASK_DIR/input-hashes.txt"
"$IVL/bin/iverilog" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$IVL/bin/vvp" -V > "$TASK_DIR/vvp-version.txt" 2>&1

set +e
/usr/bin/time -v -o "$TASK_DIR/compile.resource" timeout --signal=TERM --kill-after=30s 600s \
  "$IVL/bin/iverilog" -g2017 -gassertions -s "$TOP" \
  -I "$ABR/src/abr_prim/rtl" -I "$ABR/src/abr_libs/rtl" \
  -f "$ABR/$FILELIST" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
compile_rc=$?
sim_rc=NOT_RUN
if [[ $compile_rc == 0 ]]; then
  cd "$TASK_DIR/runtime"
  /usr/bin/time -v -o "$TASK_DIR/sim.resource" timeout --signal=TERM --kill-after=30s 600s \
    "$IVL/bin/vvp" -n "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/sim.log" 2>&1
  sim_rc=$?
fi
set -e

pass_markers=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
fail_markers=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR)' "$TASK_DIR/sim.log" 2>/dev/null || true)
vectors=present
for f in coeff_input.hex coeff_high.hex coeff_low.hex; do test -s "$TASK_DIR/runtime/$f" || vectors=missing; done
if [[ $compile_rc == 124 || $sim_rc == 124 ]]; then outcome=TIMEOUT
elif [[ $compile_rc != 0 ]]; then outcome=BLOCKED_COMPILE
elif [[ $fail_markers != 0 ]]; then outcome=FAIL
elif [[ $sim_rc == 0 && $vectors == present && $pass_markers == 1 && $fail_markers == 0 ]]; then outcome=PASS
else outcome=BLOCKED_SETUP
fi
printf 'compile_exit=%s\nsim_exit=%s\npass_markers=%s\nfailure_markers=%s\nvectors=%s\noutcome=%s\n' \
  "$compile_rc" "$sim_rc" "$pass_markers" "$fail_markers" "$vectors" "$outcome" > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
