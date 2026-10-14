#!/bin/bash
#SBATCH --job-name=axi-target-reset-edge
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --time=00:05:00
set -euo pipefail
run_dir=$(pwd)
base=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
iverilog="$base/toolchain/iverilog/bin/iverilog"
vvp="$base/toolchain/iverilog/bin/vvp"
export LD_LIBRARY_PATH="$base/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export TMPDIR="$run_dir/tmp"
mkdir -p "$run_dir/logs" "$run_dir/tmp"
run_timed() { /usr/bin/time -f 'RESOURCE MaxRSS_kB=%M CMD=%C' "$@"; }
"$iverilog" -V > "$run_dir/logs/iverilog-version.txt" 2>&1
head -n 1 "$run_dir/logs/iverilog-version.txt"
cd "$run_dir/source/dv/caliptra_bfm/axi/tests"
run_timed "$iverilog" -g2012 -s tb_axi4_caliptra_memory_subordinate -o "$run_dir/build-subordinate" ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv ../axi4_caliptra_memory_subordinate.sv ../axi4_caliptra_monitor.sv tb_axi4_caliptra_memory_subordinate.sv
run_timed "$vvp" "$run_dir/build-subordinate"
run_timed "$vvp" "$run_dir/build-subordinate" +CASE=RESET_HANDSHAKES
run_timed "$iverilog" -g2012 -s tb_axi4_caliptra_memory_queue -o "$run_dir/build-queue" ../axi4_caliptra_memory_subordinate.sv tb_axi4_caliptra_memory_queue.sv
run_timed "$vvp" "$run_dir/build-queue"
printf 'PASS\n' > "$run_dir/result.txt"
