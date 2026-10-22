#!/usr/bin/env bash
#SBATCH --job-name=a2-m11b-build-gate
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-04
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-04/logs/build-gate-%j.out

set -euo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m11b-focused-traces-20261017-04
bash "$run/build.sbatch"
bash "$run/run-gate.sbatch"
