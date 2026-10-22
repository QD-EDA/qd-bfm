#!/usr/bin/env bash
#SBATCH --job-name=m13-compress-overlay
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-compress-overlay-main-9b5fad2-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-compress-overlay-main-9b5fad2-20261017-01/logs/%x-%j.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-compress-overlay-main-9b5fad2-20261017-01
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
ABR=$RTL/submodules/adams-bridge
IVL_ROOT=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
IVL_SRC=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source
TASK_DIR=$RUN/task
FILELIST=$RUN/compress_tb_qd.vf
IVERILOG=$IVL_ROOT/bin/iverilog
VVP=$IVL_ROOT/bin/vvp

mkdir -p "$TASK_DIR/runtime"
export CALIPTRA_ROOT=$RTL
export CALIPTRA_PRIM_ROOT=$RTL/src/caliptra_prim_generic
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR=$RTL/src/integration/tb
export ADAMSBRIDGE_ROOT=$ABR
export PATH=$IVL_ROOT/bin:$PATH
export LD_LIBRARY_PATH="$IVL_ROOT/lib:$IVL_ROOT/lib64:/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$ABR" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test "$(git -C "$IVL_SRC" rev-parse HEAD)" = 9b5fad2afb4104caa816b257d5bccc40f01b8c66
test -f "$RTL/submodules/adams-bridge/src/compress/config/compress_tb.vf"
test -f "$ABR/src/ntt_top/rtl/ntt_defines_pkg.sv"
test -f "$FILELIST" && test -x "$IVERILOG" && test -x "$VVP"
cp -a "$ABR/src/compress/tb/." "$TASK_DIR/runtime/"

{
  printf 'environment_id=adams-bridge-v2-0-3-compress_tb\ntop=compress_tb\nfilelist=%s\n' "$FILELIST"
  printf 'host=%s\nslurm_job_id=%s\n' "$(hostname)" "$SLURM_JOB_ID"
  printf 'iverilog_source=9b5fad2afb4104caa816b257d5bccc40f01b8c66\ncaliptra_rtl=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e\nadams_bridge=b77e3d899e828d626cfc2a0d26a6b5704cc121e0\n'
} > "$TASK_DIR/source-revisions.txt"
sha256sum "$RTL/submodules/adams-bridge/src/compress/config/compress_tb.vf" "$FILELIST" > "$TASK_DIR/filelist.sha256"
sha256sum "$IVERILOG" "$VVP" > "$TASK_DIR/tool-binaries.sha256"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

start=$(date +%s)
set +e
/usr/bin/time -v -o "$TASK_DIR/compile.resource" timeout --signal=TERM --kill-after=30s 600s \
  "$IVERILOG" -g2017 -gassertions -s compress_tb \
  -I "$ABR/src/abr_prim/rtl" -I "$ABR/src/abr_libs/rtl" \
  -f "$FILELIST" -o "$TASK_DIR/compress_tb.vvp" > "$TASK_DIR/compile.log" 2>&1
compile_rc=$?
sim_rc=NOT_RUN
if [[ $compile_rc == 0 ]]; then
  elapsed=$(( $(date +%s) - start ))
  remaining=$((600 - elapsed))
  if ((remaining > 0)); then
    cd "$TASK_DIR/runtime"
    /usr/bin/time -v -o "$TASK_DIR/sim.resource" timeout --signal=TERM --kill-after=30s "${remaining}s" \
      "$VVP" -n "$TASK_DIR/compress_tb.vvp" > "$TASK_DIR/sim.log" 2>&1
    sim_rc=$?
  else
    sim_rc=124
  fi
fi
set -e

passes=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
failures=$(grep -Eic '(\* TESTCASE FAILED|TESTCASE FAILED|\*\*\* ERROR|FATAL ERROR|UVM_ERROR)' "$TASK_DIR/sim.log" 2>/dev/null || true)
if [[ $compile_rc != 0 ]]; then outcome=COMPILE_FAIL
elif [[ $sim_rc == 124 ]]; then outcome=TIMEOUT
elif [[ $sim_rc != 0 || $failures != 0 ]]; then outcome=FAIL
elif [[ $passes != 0 ]]; then outcome=PASS
else outcome=INCONCLUSIVE
fi
end=$(date +%s)
printf 'outcome=%s\ncompile_exit=%s\nsim_exit=%s\npass_markers=%s\nfailure_markers=%s\nelapsed_seconds=%s\n' \
  "$outcome" "$compile_rc" "$sim_rc" "$passes" "$failures" "$((end-start))" > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
