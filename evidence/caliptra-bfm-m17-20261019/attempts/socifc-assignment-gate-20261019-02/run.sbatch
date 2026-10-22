#!/bin/bash
#SBATCH --job-name=m17-socifc-assign
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G
#SBATCH --time=01:05:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-socifc-assignment-gate-20261019-02/logs/%x-%j.out
set -euo pipefail
RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-socifc-assignment-gate-20261019-02
SOURCE_ROOT="$RUN_DIR/source"
IVERILOG_BIN=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP_BIN=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT" status --porcelain
  "$IVERILOG_BIN" -V | head -n 1
  "$VVP_BIN" -V | head -n 1
  sha256sum "$IVERILOG_BIN" "$VVP_BIN"
  sha256sum "$RUN_DIR/source-snapshot.tar.gz"
  sha256sum "$SOURCE_ROOT/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" "$SOURCE_ROOT/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv"
} > "$RUN_DIR/job-meta.txt"
export IVERILOG_BIN VVP_BIN CALIPTRA_ROOT
set +e
/usr/bin/time -v -o "$RUN_DIR/runner.resource" python3 "$SOURCE_ROOT/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$SOURCE_ROOT" \
  --manifest "$SOURCE_ROOT/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id 21 \
  --output-dir "$RUN_DIR/task-21" \
  --timeout 3600 \
  > "$RUN_DIR/runner.log" 2>&1
runner_rc=$?
printf '%s\n' "$runner_rc" > "$RUN_DIR/runner.exit"
exit "$runner_rc"
