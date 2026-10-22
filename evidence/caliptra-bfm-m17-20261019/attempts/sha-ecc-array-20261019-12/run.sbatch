#!/bin/bash
#SBATCH --job-name=m17-sha-ecc
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:20:00
#SBATCH --array=16,17,54,55%3
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-sha-ecc-array-20261019-12
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-sha-ecc-array-20261019-12/logs/%x-%A_%a.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-sha-ecc-array-20261019-12
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
ROW_ID="$SLURM_ARRAY_TASK_ID"
OUT="$RUN/tasks/row-$ROW_ID/output"
mkdir -p "$OUT"
{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT" status --porcelain
  git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz"
} > "$RUN/tasks/row-$ROW_ID/job-meta.txt"
set +e
/usr/bin/time -v -o "$RUN/tasks/row-$ROW_ID/runner.resource" env CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" python3 "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" --repo-root "$SOURCE" --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" --row-id "$ROW_ID" --output-dir "$OUT" --timeout 600 > "$RUN/tasks/row-$ROW_ID/runner.log" 2>&1
RC=$?
set -e
printf 'runner_exit=%s\n' "$RC" >> "$RUN/tasks/row-$ROW_ID/job-meta.txt"
exit "$RC"
