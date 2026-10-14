#!/bin/bash
#SBATCH --job-name=caliptra-axi-if-post-xz
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-post-xz-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-post-xz-20261010-01/logs/%x-%j.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-post-xz-20261010-01
QD="$RUN/source/qd-bfm"
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$BASE/source/caliptra-rtl"
IVERILOG_SOURCE="$BASE/source/iverilog-uvm"
IVERILOG_ROOT="$BASE/toolchain/iverilog"
export CALIPTRA_RTL="$RTL"
export IVERILOG_BIN="$IVERILOG_ROOT/bin/iverilog"
export VVP_BIN="$IVERILOG_ROOT/bin/vvp"
export LD_LIBRARY_PATH="$BASE/deps/lib"
export CALIPTRA_BFM_MAX_PROCESS_BYTES=150000000
export CALIPTRA_BFM_MIN_AVAILABLE_BYTES=6000000000
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300

QD_SHA=b965acf0437236971a482a46e3d0499ce7988e16
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$IVERILOG_SOURCE" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$IVERILOG_SOURCE" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -x "$IVERILOG_BIN" && test -x "$VVP_BIN"
printf 'QD=%s\nIcarus=%s\nCaliptra=%s\n' "$QD_SHA" "$IVERILOG_SHA" "$RTL_SHA" > "$RUN/logs/source-commits.txt"
"$IVERILOG_BIN" -V > "$RUN/logs/iverilog-version.txt" 2>&1
sha256sum "$RUN/source/qd-bfm-source.tar.gz" "$IVERILOG_BIN" "$VVP_BIN" \
  "$RTL/src/axi/rtl/axi_pkg.sv" \
  "$RTL/src/axi/rtl/axi_if.sv" \
  "$RTL/src/soc_ifc/rtl/soc_ifc_pkg.sv" \
  "$RTL/src/integration/tb/caliptra_top_tb_pkg.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_fifo_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_recovery_sequence.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_recovery_avail.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_dma_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_random_stalls.sv" \
  "$QD/dv/caliptra_bfm/axi/caliptra_top_tb_axi_complex_bfm.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_caliptra_top_tb_axi_complex_bfm.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/run_caliptra_axi_complex_bfm.sh" \
  "$QD/scripts/caliptra_bfm_memory_guard.sh" \
  "$QD/scripts/run_with_memory_pressure_guard.py" > "$RUN/logs/source-files.sha256"
/usr/bin/time -v -o "$RUN/logs/resource.log" \
  sh "$QD/dv/caliptra_bfm/axi/tests/run_caliptra_axi_complex_bfm.sh" \
  > "$RUN/logs/runner.log" 2>&1
