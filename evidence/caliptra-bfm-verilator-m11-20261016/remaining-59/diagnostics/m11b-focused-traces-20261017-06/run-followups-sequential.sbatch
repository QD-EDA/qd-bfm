#!/usr/bin/env bash
#SBATCH --job-name=a2-m11b-seq06
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:35:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-06
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-06/logs/followups-%j.out

set -euo pipefail
run=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-06
for task in 1 2 3; do
    SLURM_ARRAY_TASK_ID="$task" SLURM_ARRAY_JOB_ID="$SLURM_JOB_ID" bash "$run/run-followups.sbatch"
done
