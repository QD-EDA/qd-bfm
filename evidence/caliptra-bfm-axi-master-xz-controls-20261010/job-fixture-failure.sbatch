#!/bin/bash
#SBATCH --job-name=caliptra-axi-manager-xz-green
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:30:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-xz-green-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-xz-green-20261010-01/logs/%x-%j.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-xz-green-20261010-01
QD="$RUN/source/qd-bfm"
IVERILOG_ROOT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog
export IVERILOG_BIN="$IVERILOG_ROOT/bin/iverilog"
export VVP_BIN="$IVERILOG_ROOT/bin/vvp"
export LD_LIBRARY_PATH="$IVERILOG_ROOT/lib:/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_BFM_MAX_PROCESS_BYTES=150000000
export CALIPTRA_BFM_MIN_AVAILABLE_BYTES=6000000000
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300

printf 'QD base commit: %s\n' 29cc2af7b24c89105c3c54663f3b9e812389ea90
printf 'Icarus source commit: %s\n' c339b9f2287a743aeb7ab6de6528e8d34a4dd602
"$IVERILOG_BIN" -V > "$RUN/logs/iverilog-version.txt" 2>&1
sed -n '1p' "$RUN/logs/iverilog-version.txt"
/usr/bin/verilator --version > "$RUN/logs/verilator-version.txt" 2>&1
cat "$RUN/logs/verilator-version.txt"
sha256sum "$RUN/job.sbatch" "$RUN/run-crosssim.sh" \
  "$RUN/source/qd-bfm-source.tar.gz" "$RUN/source-patch.patch" \
  "$IVERILOG_BIN" "$VVP_BIN" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/run_master.sh" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master_outstanding.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master_write_outstanding.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_parameter_matrix.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_queue.sv" \
  "$QD/scripts/caliptra_bfm_memory_guard.sh" \
  "$QD/scripts/run_with_memory_pressure_guard.py" > "$RUN/logs/source-files.sha256"

/usr/bin/time -v -o "$RUN/logs/master-time.log" \
  sh "$QD/dv/caliptra_bfm/axi/tests/run_master.sh" > "$RUN/logs/master.log" 2>&1
/usr/bin/time -v -o "$RUN/logs/crosssim-time.log" \
  python3 "$QD/scripts/run_with_memory_pressure_guard.py" \
    --max-process-bytes 750000000 --min-available-bytes 6000000000 \
    --timeout-seconds 1200 --log "$RUN/logs/crosssim.log" -- \
    bash "$RUN/run-crosssim.sh"
