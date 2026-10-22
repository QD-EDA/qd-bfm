#!/usr/bin/env bash
#SBATCH --partition=verilog
#SBATCH --job-name=m15-row68
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261018-classification-gates-01/logs/row68-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261018-classification-gates-01
exec python3 "$RUN/run_m15_test.py" \
  --repo-root "$RUN" \
  --manifest "$RUN/m15-test-to-environment.tsv" \
  --row-id 68 \
  --output-dir "$RUN/tasks/row-68" \
  --timeout 600
