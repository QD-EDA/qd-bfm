#!/bin/bash
#SBATCH --job-name=m16-kv-ahb-row6
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-kv-open-ahb-20261018-01/logs/%x-%j.out
set -euo pipefail
run_dir=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-kv-open-ahb-20261018-01
source_root="$run_dir/source"
mkdir -p "$run_dir/tasks/row-6"
{
  hostname
  date -u +%FT%TZ
  python3 --version
  sha256sum "$source_root/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
  sha256sum /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
  sha256sum /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
} > "$run_dir/job-meta.txt"
/usr/bin/time -v -o "$run_dir/runner.resource" python3 "$source_root/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$source_root" \
  --manifest "$source_root/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id 6 \
  --output-dir "$run_dir/tasks/row-6" \
  --timeout 600
