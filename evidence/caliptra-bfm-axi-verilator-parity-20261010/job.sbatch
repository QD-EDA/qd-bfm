#!/bin/bash
#SBATCH --job-name=caliptra-axi-verilator-parity
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-verilator-parity-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-verilator-parity-20261010-01/logs/%x-%j.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-verilator-parity-20261010-01
QD="$RUN/source/qd-bfm"
printf 'QD commit: %s\n'  bdc69ea2f7ae0de3f15f038928abff0bedecf77c
/usr/bin/verilator --version
sha256sum "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_queue.sv" \
  "$QD/scripts/run_with_memory_pressure_guard.py" > "$RUN/source-files.sha256"
/usr/bin/time -v -o "$RUN/logs/time.log" python3 "$QD/scripts/run_with_memory_pressure_guard.py" \
  --max-process-bytes 750000000 --min-available-bytes 6000000000 \
  --timeout-seconds 540 --log "$RUN/logs/run.log" -- \
  "$RUN/run-regressions.sh"
