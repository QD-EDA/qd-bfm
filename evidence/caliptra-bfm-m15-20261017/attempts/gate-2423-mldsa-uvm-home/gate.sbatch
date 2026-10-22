#!/usr/bin/env bash
#SBATCH --partition=verilog
#SBATCH --job-name=m15-uvmhome-gate
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261018-uvmhome-gate-01/logs/gate-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m15-20261018-uvmhome-gate-01
python3 "$RUN/src/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$RUN/src" \
  --manifest "$RUN/m15-test-to-environment.tsv" \
  --row-id 96 \
  --output-dir "$RUN/tasks/row-96" \
  --timeout 600
