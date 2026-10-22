#!/bin/bash
#SBATCH --job-name=m17-ntt-row73
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:20:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-ntt-row73-gate-20261019-19
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-ntt-row73-gate-20261019-19/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-ntt-row73-gate-20261019-19
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
OUT="$RUN/tasks/row-73/output"
mkdir -p "$OUT"
tar -xzf "$RUN/source-snapshot.tar.gz" -C "$SOURCE"
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
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" \
    "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
    "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/test_run_m15_test.py"
} > "$RUN/tasks/row-73/job-meta.txt"
set +e
/usr/bin/time -v -o "$RUN/tasks/row-73/runner.resource" env CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" python3 "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" --repo-root "$SOURCE" --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" --row-id 73 --output-dir "$OUT" --timeout 600 > "$RUN/tasks/row-73/runner.log" 2>&1
RC=$?
set -e
printf 'runner_exit=%s\n' "$RC" >> "$RUN/tasks/row-73/job-meta.txt"
exit "$RC"
