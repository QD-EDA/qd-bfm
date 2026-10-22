#!/usr/bin/env bash
#SBATCH --job-name=m16-cast-repro
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-param-cast-repro-20261018-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-param-cast-repro-20261018-01/logs/%x-%j.out

set -euo pipefail
run_dir=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-param-cast-repro-20261018-01
source_file="$run_dir/ahb_parameterized_cast.sv"
ivl_root=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
mkdir -p "$run_dir/logs" "$run_dir/build"
{
  hostname
  date -u +%FT%TZ
  "$ivl_root/bin/iverilog" -V | head -1
  "$ivl_root/bin/vvp" -V | head -1
  sha256sum "$ivl_root/bin/iverilog" "$ivl_root/bin/vvp" "$source_file"
  verilator --version
} > "$run_dir/job-meta.txt"

set +e
"$ivl_root/bin/iverilog" -g2017 -s tb -o "$run_dir/build/iverilog.vvp" "$source_file" > "$run_dir/build/iverilog.compile.log" 2>&1
iverilog_compile_rc=$?
if [ "$iverilog_compile_rc" -eq 0 ]; then
  "$ivl_root/bin/vvp" "$run_dir/build/iverilog.vvp" > "$run_dir/build/iverilog.run.log" 2>&1
  iverilog_run_rc=$?
else
  iverilog_run_rc=NA
fi

verilator --binary --timing --top-module tb --Mdir "$run_dir/build/verilator_obj" "$source_file" > "$run_dir/build/verilator.compile.log" 2>&1
verilator_compile_rc=$?
if [ "$verilator_compile_rc" -eq 0 ]; then
  "$run_dir/build/verilator_obj/Vtb" > "$run_dir/build/verilator.run.log" 2>&1
  verilator_run_rc=$?
else
  verilator_run_rc=NA
fi
set -e

{
  echo "iverilog_compile_rc=$iverilog_compile_rc"
  echo "iverilog_run_rc=$iverilog_run_rc"
  echo "verilator_compile_rc=$verilator_compile_rc"
  echo "verilator_run_rc=$verilator_run_rc"
  if [ -f "$run_dir/build/iverilog.run.log" ]; then cat "$run_dir/build/iverilog.run.log"; fi
  if [ -f "$run_dir/build/verilator.run.log" ]; then cat "$run_dir/build/verilator.run.log"; fi
} > "$run_dir/result.txt"
