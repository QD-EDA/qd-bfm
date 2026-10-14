#!/bin/bash
#SBATCH --job-name=ecc-uvmf-c339-pilot
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:20:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/ecc-uvmf-c339-pilot-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/ecc-uvmf-c339-pilot-20261010-01/logs/%x-%j.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/ecc-uvmf-c339-pilot-20261010-01
QD="$RUN/source/qd-bfm"
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$BASE/source/caliptra-rtl"
IVERILOG_SOURCE="$BASE/source/iverilog-uvm"
IVERILOG_ROOT="$BASE/toolchain/iverilog"
export CALIPTRA_ROOT="$RTL"
export IVERILOG_BIN="$IVERILOG_ROOT/bin/iverilog"
export VVP_BIN="$IVERILOG_ROOT/bin/vvp"
export LD_LIBRARY_PATH="$BASE/deps/lib"
export ECC_IEEE_EDITION=both
export ECC_RUNTIME_PROBE=reset
export ECC_RESET_MONITOR_LOG_DIR="$RUN/logs/runtime"
export ECC_RESET_MONITOR_LOG_PREFIX=c339b9f_reset_irq
export CALIPTRA_BFM_MAX_PROCESS_BYTES=750000000
export CALIPTRA_BFM_MIN_AVAILABLE_BYTES=6000000000
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=900

QD_SHA=5269337c0cb0ec0c712dff18da6d021e4d64a681
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
  "$QD/dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh" \
  "$QD/dv/caliptra_bfm/uvmf_lite/tests/generated_ecc_monitor_overlay.py" \
  "$QD/dv/caliptra_bfm/uvmf_lite/tests/tb_generated_ecc_reset_probe_pkg.sv" \
  "$QD/dv/caliptra_bfm/uvmf_lite/tests/tb_generated_ecc_full_probe.sv" \
  "$QD/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv" \
  "$QD/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv" \
  "$RTL/src/ecc/config/ecc_top.vf" \
  "$RTL/src/ecc/uvmf_ecc/uvmf_template_output/project_benches/ECC/tb/testbench/hdl_top.sv" \
  "$RTL/src/ecc/uvmf_ecc/uvmf_template_output/project_benches/ECC/tb/testbench/hvl_top.sv" \
  > "$RUN/logs/source-files.sha256"
/usr/bin/time -v -o "$RUN/logs/resource.log" \
  sh "$QD/dv/caliptra_bfm/uvmf_lite/tests/run_generated_ecc_reset_monitor.sh" \
  > "$RUN/logs/runner.log" 2>&1
