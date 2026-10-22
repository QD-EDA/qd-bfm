#!/usr/bin/env bash
#SBATCH --job-name=bfm-m15
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --array=0-55%6
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261017-05-pilot/logs/slurm-%A_%a.out
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261017-05-pilot/submit

set -Eeuo pipefail
RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261017-05-pilot
ROW_ID=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$RUN_DIR/row-ids.txt")
test -n "$ROW_ID"
exec python3 "$RUN_DIR/repo/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$RUN_DIR/repo" \
  --manifest "$RUN_DIR/repo/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id "$ROW_ID" \
  --output-dir "$RUN_DIR/tasks/row-$ROW_ID" \
  --timeout 3600
