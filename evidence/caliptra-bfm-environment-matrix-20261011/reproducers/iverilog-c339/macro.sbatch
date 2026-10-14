#!/usr/bin/env bash
#SBATCH --job-name=a2-interface-min
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --time=00:10:00
#SBATCH --array=0
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/macro-c339-20261011-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/macro-c339-20261011-01/logs/%x-%A_%a.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/macro-c339-20261011-01
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
TASK="$RUN/results/force_release_axi_macro"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export RUN BASE IVERILOG VVP TASK
mkdir -p "$TASK"
hostname > "$TASK/host.txt"
git -C "$BASE/source/iverilog-uvm" rev-parse HEAD > "$TASK/iverilog-source-revision.txt"
sha256sum "$IVERILOG" "$VVP" > "$TASK/tool-binaries.sha256"
"$IVERILOG" -V > "$TASK/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK/vvp-version.txt" 2>&1

set +e
timeout --signal=TERM --kill-after=5s 120s bash -c '
  /usr/bin/time -v -o "$TASK/compile.resource" "$IVERILOG" -g2012 -s force_release_axi_macro "$RUN/source/force_release_axi_macro.sv" -o "$TASK/test.vvp" > "$TASK/compile.log" 2>&1
  compile_rc=$?
  sim_rc=NOT_RUN
  if [[ $compile_rc == 0 ]]; then
    /usr/bin/time -v -o "$TASK/sim.resource" "$VVP" -n "$TASK/test.vvp" > "$TASK/sim.log" 2>&1
    sim_rc=$?
  fi
  printf "compile_exit=%s\nsim_exit=%s\n" "$compile_rc" "$sim_rc" > "$TASK/stage-status.txt"
  [[ $compile_rc == 0 && $sim_rc == 0 ]]
'
runner_rc=$?
set -e
printf 'runner_exit=%s\n' "$runner_rc" >> "$TASK/stage-status.txt"
cat "$TASK/stage-status.txt"
exit 0
