#!/usr/bin/env bash
#SBATCH --job-name=m15-full-rows
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --array=0-103%6
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261018-full-rows-01/logs/slurm-%A_%a.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261018-full-rows-01
ROW_ID=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$RUN/rows-to-run.txt")
test -n "$ROW_ID"
exec python3 "$RUN/src/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$RUN/src" \
  --manifest "$RUN/m15-test-to-environment.tsv" \
  --row-id "$ROW_ID" \
  --output-dir "$RUN/tasks/row-$ROW_ID" \
  --timeout 3600
