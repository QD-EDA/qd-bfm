#!/usr/bin/env bash
#SBATCH --job-name=a2-m11b-build-gate05
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:25:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-05
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-05/logs/build-gate-%j.out

set -euo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-05
bash "$run/build.sbatch"
bash "$run/run-gate.sbatch"
