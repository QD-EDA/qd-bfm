#!/bin/bash
#SBATCH --job-name=axi-width-id-matrix
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-parameter-matrix-final-20261009-26
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-parameter-matrix-final-20261009-26/logs/%x-%j.out

set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-parameter-matrix-final-20261009-26
QD="$RUN/source/qd-bfm"
IVERILOG_ROOT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog
ENV_ROOT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/deps
ICARUS_SOURCE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/source/iverilog-uvm
export LD_LIBRARY_PATH="$IVERILOG_ROOT/lib:$ENV_ROOT/lib"
IVERILOG_BIN="$IVERILOG_ROOT/bin/iverilog"
VVP_BIN="$IVERILOG_ROOT/bin/vvp"
test "$(git -C "$QD" rev-parse HEAD)" = 57aff65558d0c19dfa9a6aad5d4123f14659d1bd
test -z "$(git -C "$QD" status --porcelain)"
test -z "$(git -C "$ICARUS_SOURCE" status --porcelain)"
git -C "$ICARUS_SOURCE" merge-base --is-ancestor c339b9f2287a743aeb7ab6de6528e8d34a4dd602 origin/main
"$IVERILOG_BIN" -V > "$RUN/logs/iverilog-version.txt" 2>&1
sha256sum "$IVERILOG_BIN" "$VVP_BIN" > "$RUN/logs/simulator-sha256.txt"
printf "QD=%s\n" "$(git -C "$QD" rev-parse HEAD)" > "$RUN/logs/source-commits.txt"
printf "Icarus=%s\n" "$(git -C "$ICARUS_SOURCE" rev-parse HEAD)" >> "$RUN/logs/source-commits.txt"
sha256sum "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_parameter_matrix.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/run_parameter_matrix.sh" \
  > "$RUN/logs/source-file-sha256.txt"
if /usr/bin/time -v env IVERILOG_BIN="$IVERILOG_BIN" VVP_BIN="$VVP_BIN" \
  sh "$QD/dv/caliptra_bfm/axi/tests/run_parameter_matrix.sh" \
  > "$RUN/logs/parameter-matrix.out" 2> "$RUN/logs/resource.log"; then
  echo PASS > "$RUN/logs/result.txt"
else
  status=$?
  printf "FAIL_EXIT=%s\n" "$status" > "$RUN/logs/result.txt"
  exit "$status"
fi
git -C "$QD" status --porcelain > "$RUN/logs/qd-after-status.txt"
test ! -s "$RUN/logs/qd-after-status.txt"
git -C "$ICARUS_SOURCE" status --porcelain > "$RUN/logs/icarus-after-status.txt"
test ! -s "$RUN/logs/icarus-after-status.txt"
