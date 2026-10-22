#!/usr/bin/env bash
#SBATCH --job-name=m16-mldsa-ahb-96gate
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-mldsa-row96-model-fatal-20261018-01/logs/%x-%j.out
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-mldsa-row96-model-fatal-20261018-01/submit
set -euo pipefail
run_dir=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-mldsa-row96-model-fatal-20261018-01
source_root="$run_dir/source"
mkdir -p "$run_dir/tasks/row-96"
iverilog=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
{
  hostname
  date -u +%FT%TZ
  python3 --version
  cc --version | head -1
  make --version | head -1
  git -C /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl rev-parse HEAD
  git -C /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl/submodules/adams-bridge rev-parse HEAD
  "$iverilog" -V | head -1
  sha256sum "$iverilog" "${iverilog%/*}/vvp"
  sha256sum "$source_root/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" "$source_root/dv/caliptra_bfm/uvm/caliptra_ahb_mvc_compat_pkg.sv" "$source_root/dv/caliptra_bfm/uvm/caliptra_ahb_qvip_compat_pkg.sv" "$source_root/dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f" "$source_root/dv/caliptra_bfm/native_vectors/stage_mldsa.py" "$source_root/dv/caliptra_bfm/native_vectors/check_native_mldsa.py"
} > "$run_dir/job-meta.txt"
/usr/bin/time -v -o "$run_dir/runner.resource" python3 "$source_root/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"   --repo-root "$source_root"   --manifest "$source_root/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv"   --row-id 96   --output-dir "$run_dir/tasks/row-96"   --timeout 600
