#!/bin/bash
#SBATCH --job-name=m16-row20-csrng-filelist
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-row20-csrng-filelist-20261018-01/logs/%x-%j.out
set -euo pipefail

RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-row20-csrng-filelist-20261018-01
SOURCE_ROOT="$RUN_DIR/source"
IVERILOG=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP="${IVERILOG%/*}/vvp"
mkdir -p "$RUN_DIR/tasks/row-20"
{
  hostname
  date -u +%FT%TZ
  python3 --version
  sha256sum "$SOURCE_ROOT/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
  sha256sum "$SOURCE_ROOT/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv"
  sha256sum "$IVERILOG" "$VVP"
  "$IVERILOG" -V | head -n 1
  git -C /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl rev-parse HEAD
  git -C /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/submodules/adams-bridge rev-parse HEAD
  sha256sum /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/src/csrng/config/csrng_tb.vf
} > "$RUN_DIR/job-meta.txt"
/usr/bin/time -v -o "$RUN_DIR/runner.resource" python3 "$SOURCE_ROOT/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$SOURCE_ROOT" \
  --manifest "$SOURCE_ROOT/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id 20 \
  --output-dir "$RUN_DIR/tasks/row-20" \
  --timeout 600
