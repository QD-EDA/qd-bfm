#!/usr/bin/env bash
#SBATCH --job-name=a2-if-task
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/interface-task-c339-20261011-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/interface-task-c339-20261011-01/logs/%x-%j.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/interface-task-c339-20261011-01
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
TASK="$RUN/results"
export RUN BASE IVERILOG VVP TASK
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p "$TASK"
hostname > "$TASK/host.txt"
cat "$BASE/source/iverilog-uvm/.git/HEAD" > "$TASK/git-head.txt" || true
git -C "$BASE/source/iverilog-uvm" rev-parse HEAD > "$TASK/iverilog-source-revision.txt"
sha256sum "$IVERILOG" "$VVP" "$RUN/source/axi_if_task_mixed_driver.sv" > "$TASK/hashes.txt"
"$IVERILOG" -V > "$TASK/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK/vvp-version.txt" 2>&1
set +e
timeout --signal=TERM --kill-after=5s 120s "$IVERILOG" -g2017 -s axi_if_task_mixed_driver "$RUN/source/axi_if_task_mixed_driver.sv" -o "$TASK/baseline.vvp" > "$TASK/baseline-compile.log" 2>&1
printf '%s\n' "$?" > "$TASK/baseline-compile.exit"
timeout --signal=TERM --kill-after=5s 120s "$IVERILOG" -g2017 -DSYNTHESIS -s axi_if_task_mixed_driver "$RUN/source/axi_if_task_mixed_driver.sv" -o "$TASK/synthesis.vvp" > "$TASK/synthesis-compile.log" 2>&1
printf '%s\n' "$?" > "$TASK/synthesis-compile.exit"
sim_rc=NOT_RUN
if [[ "$(cat "$TASK/synthesis-compile.exit")" == 0 ]]; then
  timeout --signal=TERM --kill-after=5s 120s "$VVP" -n "$TASK/synthesis.vvp" > "$TASK/synthesis-sim.log" 2>&1
  sim_rc=$?
fi
printf 'baseline_compile_exit=%s\nsynthesis_compile_exit=%s\nsynthesis_sim_exit=%s\n' "$(cat "$TASK/baseline-compile.exit")" "$(cat "$TASK/synthesis-compile.exit")" "$sim_rc" > "$TASK/stage-status.txt"
cat "$TASK/stage-status.txt"
