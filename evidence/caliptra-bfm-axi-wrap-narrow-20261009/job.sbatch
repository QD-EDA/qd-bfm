#!/bin/bash
#SBATCH --job-name=axi-wrap-narrow-green
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-wrap-narrow-green-20261009-18
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-wrap-narrow-green-20261009-18/logs/%x-%j.out

set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-wrap-narrow-green-20261009-18
QD="$RUN/source/qd-bfm"
IVERILOG_ROOT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog
ENV_ROOT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/deps
export LD_LIBRARY_PATH="$IVERILOG_ROOT/lib:$ENV_ROOT/lib"
IVERILOG_BIN="$IVERILOG_ROOT/bin/iverilog"
VVP_BIN="$IVERILOG_ROOT/bin/vvp"
"$IVERILOG_BIN" -V > "$RUN/logs/iverilog-version.txt" 2>&1
sha256sum "$IVERILOG_BIN" "$VVP_BIN" > "$RUN/logs/simulator-sha256.txt"
/usr/bin/time -v env IVERILOG_BIN="$IVERILOG_BIN" VVP_BIN="$VVP_BIN" \
  sh "$QD/dv/caliptra_bfm/axi/tests/run_master.sh" \
  2> "$RUN/logs/master-resource.log"
