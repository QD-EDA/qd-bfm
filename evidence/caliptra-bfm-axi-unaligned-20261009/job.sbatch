#!/bin/bash
#SBATCH --job-name=axi-unaligned-final
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-unaligned-final-20261009-24
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-unaligned-final-20261009-24/logs/%x-%j.out

set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-unaligned-final-20261009-24
QD="$RUN/source/qd-bfm"
IVERILOG_ROOT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog
ENV_ROOT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/deps
ICARUS_SOURCE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/source/iverilog-uvm
export LD_LIBRARY_PATH="$IVERILOG_ROOT/lib:$ENV_ROOT/lib"
IVERILOG_BIN="$IVERILOG_ROOT/bin/iverilog"
VVP_BIN="$IVERILOG_ROOT/bin/vvp"
test "$(git -C "$QD" rev-parse HEAD)" = 72123e9f055630781e664fd6aa4960671afe3394
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
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_subordinate.sv" \
  > "$RUN/logs/source-file-sha256.txt"
for suite in master subordinate; do
  if /usr/bin/time -v env IVERILOG_BIN="$IVERILOG_BIN" VVP_BIN="$VVP_BIN" \
    sh "$QD/dv/caliptra_bfm/axi/tests/run_${suite}.sh" \
    > "$RUN/logs/${suite}.out" 2> "$RUN/logs/${suite}-resource.log"; then
    echo PASS > "$RUN/logs/${suite}-result.txt"
  else
    status=$?
    printf "FAIL_EXIT=%s\n" "$status" > "$RUN/logs/${suite}-result.txt"
    exit "$status"
  fi
done
git -C "$QD" status --porcelain > "$RUN/logs/qd-after-status.txt"
test ! -s "$RUN/logs/qd-after-status.txt"
git -C "$ICARUS_SOURCE" status --porcelain > "$RUN/logs/icarus-after-status.txt"
test ! -s "$RUN/logs/icarus-after-status.txt"
