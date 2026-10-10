#!/bin/bash
#SBATCH --job-name=axi-reset-edge
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
run_timed "$iverilog" -g2012 -s tb_axi4_caliptra_master -o "$run_dir/build-master" ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv tb_axi4_caliptra_master.sv
run_timed "$vvp" "$run_dir/build-master"
for case_name in WRAP_NARROW W_BEFORE_AW CONCURRENT RESET_ABORT RESET_HANDSHAKES; do
  run_timed "$vvp" "$run_dir/build-master" "+CASE=$case_name"
done
run_timed "$iverilog" -g2012 -Ptb_axi4_caliptra_master.CHECKER_ENABLED=0 -s tb_axi4_caliptra_master -o "$run_dir/build-no-checker" ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv tb_axi4_caliptra_master.sv
for case_name in BAD_BID BAD_RLAST; do
  run_timed "$vvp" "$run_dir/build-no-checker" "+CASE=$case_name"
done
run_timed "$iverilog" -g2012 -s tb_axi4_caliptra_master_outstanding -o "$run_dir/build-outstanding" ../axi4_caliptra_master.sv tb_axi4_caliptra_master_outstanding.sv
run_timed "$vvp" "$run_dir/build-outstanding"
run_timed "$iverilog" -g2012 -s tb_axi4_caliptra_master_write_outstanding -o "$run_dir/build-write-outstanding" ../axi4_caliptra_master.sv tb_axi4_caliptra_master_write_outstanding.sv
run_timed "$vvp" "$run_dir/build-write-outstanding"
printf 'PASS\n' > "$run_dir/result.txt"
