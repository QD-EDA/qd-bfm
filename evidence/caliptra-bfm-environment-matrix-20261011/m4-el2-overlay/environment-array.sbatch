#!/usr/bin/env bash
#SBATCH --job-name=env-el2-overlay
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --array=0-0
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m4-env-overlay-c339-20261011-03/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m4-env-overlay-c339-20261011-03/logs/%x-%A_%a.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m4-env-overlay-c339-20261011-03
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$RUN/source"
OVERLAYS="$RUN/overlays"
ENV_ID=caliptra-v2-1-2-el2_veer_wrapper_tb
TOP=el2_veer_wrapper_tb
FILELIST=src/riscv_core/veer_el2/config/el2_veer_wrapper_tb.vf
TASK_DIR="$RUN/tasks/$ENV_ID"
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
export RUN BASE RTL IVERILOG VVP TOP FILELIST TASK_DIR

mkdir -p "$TASK_DIR"
test ! -e "$RTL/.git"
test "$(cat "$RTL/caliptra-rtl.commit")" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$BASE/source/iverilog-uvm" rev-parse HEAD)" = c339b9f2287a743aeb7ab6de6528e8d34a4dd602
test -z "$(git -C "$BASE/source/iverilog-uvm" status --porcelain --untracked-files=all)"
test -x "$IVERILOG" && test -x "$VVP"
"$OVERLAYS/apply.sh" "$RTL" el2-veer-remove-stale-dft-ports.patch

export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$RTL/submodules/adams-bridge"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
TOP_FILE="$RTL/src/riscv_core/veer_el2/tb/$TOP.sv"
test -f "$TOP_FILE" && test -f "$RTL/$FILELIST"
sha256sum "$RTL/src/riscv_core/veer_el2/tb/el2_veer_wrapper_tb.sv" "$OVERLAYS/el2-veer-remove-stale-dft-ports.patch" > "$TASK_DIR/overlay-hashes.txt"
printf 'host=%s\nenvironment=%s\ntop=%s\nfilelist=%s\nCaliptra=%s\nIcarus=%s\n' \
  "$(hostname)" "$ENV_ID" "$TOP" "$FILELIST" \
  "$(cat "$RTL/caliptra-rtl.commit")" \
  "$(git -C "$BASE/source/iverilog-uvm" rev-parse HEAD)" > "$TASK_DIR/provenance.txt"
sha256sum "$IVERILOG" "$VVP" > "$TASK_DIR/tool-binaries.sha256"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

set +e
timeout --signal=TERM --kill-after=30s 6900s bash -c '
  set +e
  /usr/bin/time -v -o "$TASK_DIR/compile.resource" "$IVERILOG" -g2017 -gassertions -s "$TOP" \
    -I "$RTL/src/riscv_core/veer_el2/rtl" -I "$RTL/src/riscv_core/veer_el2/rtl/include" \
    -f "$RTL/$FILELIST" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
  compile_rc=$?
  if [ "$compile_rc" -eq 0 ]; then
    /usr/bin/time -v -o "$TASK_DIR/sim.resource" "$VVP" -n "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/sim.log" 2>&1
    sim_rc=$?
  else
    sim_rc=NOT_RUN
  fi
  printf "compile_exit=%s\nsim_exit=%s\n" "$compile_rc" "$sim_rc" > "$TASK_DIR/stage-status.txt"
  [ "$compile_rc" -eq 0 ] && [ "$sim_rc" -eq 0 ]
'
runner_exit=$?
set -e
printf 'runner_exit=%s\n' "$runner_exit" > "$TASK_DIR/runner-status.txt"
cat "$TASK_DIR/stage-status.txt" 2>/dev/null || true
exit 0
