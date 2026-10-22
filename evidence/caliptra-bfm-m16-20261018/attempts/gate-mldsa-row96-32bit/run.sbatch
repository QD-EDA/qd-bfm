#!/usr/bin/env bash
#SBATCH --job-name=m16-mldsa-32cli96
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-mldsa-row96-32bit-cli-20261018-01/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-mldsa-row96-32bit-cli-20261018-01/logs/%x-%j.out

set -euo pipefail
run_dir=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-mldsa-row96-32bit-cli-20261018-01
source_root="$run_dir/source"
mkdir -p "$run_dir/tasks/row-96"
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
ivl_root=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
{
  hostname
  date -u +%FT%TZ
  python3 --version
  git -C "$rtl" rev-parse HEAD
  git -C "$rtl/submodules/adams-bridge" rev-parse HEAD
  "$ivl_root/bin/iverilog" -V | head -1
  "$ivl_root/bin/vvp" -V | head -1
  sha256sum "$ivl_root/bin/iverilog" "$ivl_root/bin/vvp"
  sha256sum "$source_root/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" "$source_root/dv/caliptra_bfm/uvmf_lite/tests/test_run_m15_test.py" "$source_root/dv/caliptra_bfm/uvm/caliptra_ahb_mvc_compat_pkg.sv" "$source_root/dv/caliptra_bfm/uvm/caliptra_ahb_qvip_compat_pkg.sv"
} > "$run_dir/job-meta.txt"
/usr/bin/time -v -o "$run_dir/runner.resource" python3 "$source_root/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$source_root" \
  --manifest "$source_root/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id 96 \
  --output-dir "$run_dir/tasks/row-96" \
  --timeout 600
