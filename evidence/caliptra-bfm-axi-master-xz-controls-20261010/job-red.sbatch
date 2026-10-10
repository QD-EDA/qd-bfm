#!/bin/bash
#SBATCH --job-name=caliptra-axi-manager-xz-red
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-xz-red-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-xz-red-20261010-01/logs/%x-%j.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-xz-red-20261010-01
QD="$RUN/source/qd-bfm"
IVERILOG_ROOT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog
export IVERILOG_BIN="$IVERILOG_ROOT/bin/iverilog"
export VVP_BIN="$IVERILOG_ROOT/bin/vvp"
export LD_LIBRARY_PATH="$IVERILOG_ROOT/lib:/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_BFM_MAX_PROCESS_BYTES=150000000
export CALIPTRA_BFM_MIN_AVAILABLE_BYTES=6000000000
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300

printf 'QD base commit: %s\n' 29cc2af7b24c89105c3c54663f3b9e812389ea90
printf 'QD source patch SHA256: '
sha256sum "$RUN/source-patch.patch"
printf 'Icarus source commit: %s\n' c339b9f2287a743aeb7ab6de6528e8d34a4dd602
"$IVERILOG_BIN" -V > "$RUN/logs/iverilog-version.txt" 2>&1
sed -n '1p' "$RUN/logs/iverilog-version.txt"
sha256sum "$IVERILOG_BIN" "$VVP_BIN" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/run_master.sh" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master_outstanding.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master_write_outstanding.sv" \
  "$QD/scripts/caliptra_bfm_memory_guard.sh" \
  "$QD/scripts/run_with_memory_pressure_guard.py" > "$RUN/logs/source-files.sha256"

set +e
/usr/bin/time -v -o "$RUN/logs/time.log" \
  sh "$QD/dv/caliptra_bfm/axi/tests/run_master.sh" > "$RUN/logs/runner.log" 2>&1
status=$?
set -e
if [ "$status" -eq 0 ]; then
  echo 'RED check unexpectedly passed before manager fix' >&2
  exit 1
fi
if ! grep -Fq 'unknown AXI control or response waited for the ordinary timeout' "$RUN/logs/runner.log"; then
  echo 'RED check failed for a reason other than the expected timeout behavior' >&2
  exit "$status"
fi
echo 'EXPECTED RED: unknown AXI control was not rejected before ordinary timeout'
