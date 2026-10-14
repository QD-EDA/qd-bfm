#!/bin/bash
#SBATCH --job-name=caliptra-axi-crosssim-matrix
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:30:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-param-crosssim-fix-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-param-crosssim-fix-20261010-01/logs/%x-%j.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-param-crosssim-fix-20261010-01
QD="$RUN/source/qd-bfm"
IVERILOG=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog/bin
printf 'QD base commit: %s\n' 16ae08093aff9e7b7e49f463bd014bad8f9b0a03
printf 'Icarus source commit: %s\n' c339b9f2287a743aeb7ab6de6528e8d34a4dd602
/usr/bin/verilator --version
sha256sum "$IVERILOG/iverilog" "$IVERILOG/vvp" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_parameter_matrix.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_queue.sv" \
  "$QD/scripts/run_with_memory_pressure_guard.py" > "$RUN/source-files.sha256"
/usr/bin/time -v -o "$RUN/logs/time.log" python3 "$QD/scripts/run_with_memory_pressure_guard.py" \
  --max-process-bytes 750000000 --min-available-bytes 6000000000 \
  --timeout-seconds 1200 --log "$RUN/logs/run.log" -- \
  "$RUN/run-all-regressions.sh"
