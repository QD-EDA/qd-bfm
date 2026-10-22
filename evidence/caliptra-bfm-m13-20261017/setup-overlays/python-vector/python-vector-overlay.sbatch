#!/usr/bin/env bash
#SBATCH --job-name=bfm-m13-python-overlay
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --array=0-1%2
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-python-vector-overlay-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-python-vector-overlay-20261017-01/logs/%x-%A_%a.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-python-vector-overlay-20261017-01
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
ABR="$RTL/submodules/adams-bridge"
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
PYENV=/home/dsell/toolchains/python-3.14.4-numpy-2.5.4-a2-m13-20261017
IFS=$'\t' read -r ENV_ID TOP FILELIST RUNTIME_DIR REQUIRED_VECTORS < <(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$RUN/tasks.tsv")
TASK_DIR="$RUN/tasks/$ENV_ID"

mkdir -p "$TASK_DIR/runtime" "$TASK_DIR/python-cache"
cp -a "$ABR/$RUNTIME_DIR/." "$TASK_DIR/runtime/"
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

{
  printf 'host=%s\nslurm_job_id=%s\narray_task_id=%s\nenvironment_id=%s\ntop=%s\nfilelist=%s\n' \
    "$(hostname)" "$SLURM_JOB_ID" "$SLURM_ARRAY_TASK_ID" "$ENV_ID" "$TOP" "$FILELIST"
  printf 'caliptra_rtl=%s\nadams_bridge=%s\niverilog_source=%s\nsetup_overlay=Python 3.14.4 + NumPy 2.5.4 on PATH\n' \
    "$(git -C "$RTL" rev-parse HEAD)" "$(git -C "$ABR" rev-parse HEAD)" \
    "$(git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD)"
  "$PYENV/bin/python" --version
  "$PYENV/bin/python" -c 'import numpy; print("numpy=" + numpy.__version__)'
} > "$TASK_DIR/provenance.txt" 2>&1
sha256sum "$IVL/bin/iverilog" "$IVL/bin/vvp" "$PYENV/bin/python" \
  "$PYENV/lib/python3.14/site-packages/numpy/__init__.py" "$ABR/$FILELIST" > "$TASK_DIR/input-hashes.txt"
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

vectors=present
if [[ $REQUIRED_VECTORS != - ]]; then
  IFS=, read -r -a required <<< "$REQUIRED_VECTORS"
  for f in "${required[@]}"; do test -s "$TASK_DIR/runtime/$f" || vectors=missing; done
fi
pass_markers=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
fail_markers=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR|^Error: Output mismatch)' "$TASK_DIR/sim.log" 2>/dev/null || true)
if [[ $compile_rc == 124 || $sim_rc == 124 ]]; then outcome=TIMEOUT
elif [[ $compile_rc != 0 ]]; then outcome=BLOCKED_COMPILE
elif [[ $vectors == missing ]]; then outcome=BLOCKED_SETUP
elif [[ $fail_markers != 0 ]]; then outcome=FAIL
elif [[ $sim_rc == 0 && $pass_markers == 1 && $fail_markers == 0 ]]; then outcome=PASS
else outcome=BLOCKED_SETUP
fi
printf 'environment_id=%s\ntop=%s\ncompile_exit=%s\nsim_exit=%s\npass_markers=%s\nfailure_markers=%s\nvectors=%s\noutcome=%s\n' \
  "$ENV_ID" "$TOP" "$compile_rc" "$sim_rc" "$pass_markers" "$fail_markers" "$vectors" "$outcome" > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
