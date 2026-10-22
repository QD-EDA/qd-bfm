#!/bin/bash
#SBATCH --job-name=m16-row71-py
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-row71-python-alias-20261018-01/logs/%x-%j.out
set -euo pipefail
RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-row71-python-alias-20261018-01
SOURCE_ROOT="$RUN_DIR/source"
mkdir -p "$RUN_DIR/tasks/row-71"
{
  hostname
  date -u +%FT%TZ
  command -v python || true
  command -v python3
  python3 --version
  sha256sum "$SOURCE_ROOT/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
  sha256sum "$SOURCE_ROOT/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv"
  sha256sum /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
} > "$RUN_DIR/job-meta.txt"
/usr/bin/time -v -o "$RUN_DIR/runner.resource" python3 "$SOURCE_ROOT/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$SOURCE_ROOT" \
  --manifest "$SOURCE_ROOT/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id 71 \
  --output-dir "$RUN_DIR/tasks/row-71" \
  --timeout 600
