#!/bin/bash
#SBATCH --job-name=axi-master-reset-stalls
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-reset-stalls-00de2a6-20261009-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-reset-stalls-00de2a6-20261009-01/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-master-reset-stalls-00de2a6-20261009-01
QD="$RUN/source/qd-bfm"
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
ICARUS_SOURCE="$BASE/source/iverilog-uvm"
IVERILOG_BIN="$BASE/toolchain/iverilog/bin/iverilog"
VVP_BIN="$BASE/toolchain/iverilog/bin/vvp"
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
(cd "$QD" && sha256sum --check "$RUN/source/qd-inputs.sha256")
test "$(git -C "$ICARUS_SOURCE" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$ICARUS_SOURCE" status --porcelain --untracked-files=all)"
test -x "$IVERILOG_BIN" && test -x "$VVP_BIN"
mkdir -p "$RUN/logs" "$RUN/tmp"
printf 'QD base=00de2a636dd251d01c28a9dbddd7a5453bf7800d\nQD source files=working-tree patch, recorded by SHA256 manifest\nIcarus=%s\n' "$IVERILOG_SHA" > "$RUN/logs/source-commits.txt"
sha256sum "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master_outstanding.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_master_write_outstanding.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/run_master.sh" \
  "$QD/scripts/caliptra_bfm_memory_guard.sh" \
  "$QD/scripts/run_with_memory_pressure_guard.py" > "$RUN/logs/qd-source-files.sha256"
sha256sum "$IVERILOG_BIN" "$VVP_BIN" > "$RUN/logs/simulator-sha256.txt"
export IVERILOG_BIN VVP_BIN LD_LIBRARY_PATH="$BASE/deps/lib" TMPDIR="$RUN/tmp"
"$IVERILOG_BIN" -V 2>&1 | head -1 > "$RUN/logs/iverilog-version.txt" || true
export CALIPTRA_BFM_MAX_PROCESS_BYTES=150000000
export CALIPTRA_BFM_MIN_AVAILABLE_BYTES=6000000000
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300
set +e
/usr/bin/time -v -o "$RUN/logs/resource.log" sh "$QD/dv/caliptra_bfm/axi/tests/run_master.sh" > "$RUN/logs/runner.out" 2>&1
status=$?
set -e
if [ "$status" -eq 0 ]; then
  printf 'PASS\n' > "$RUN/logs/result.txt"
else
  printf 'FAIL_EXIT=%s\n' "$status" > "$RUN/logs/result.txt"
fi
exit "$status"
