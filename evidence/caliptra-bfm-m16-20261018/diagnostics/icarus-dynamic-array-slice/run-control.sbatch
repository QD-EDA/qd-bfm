#!/bin/bash
#SBATCH --job-name=m16-darray-control
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-darray-slice-20261018-03/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-darray-slice-20261018-03
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
VERILATOR=/usr/bin/verilator
SOURCE="$RUN/source/dynamic_array_slice_class_control.sv"
cd "$RUN"
{
  hostname
  date -u +%FT%TZ
  "$IVL" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$SOURCE"
  git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD
  "$VERILATOR" --version
} > job-meta.txt
set +e
/usr/bin/time -v -o icarus.resource timeout --signal=TERM --kill-after=5s 60s "$IVL" -g2017 -s dynamic_array_slice_class_control -o control.vvp "$SOURCE" > icarus.compile.log 2>&1
icarus_compile=$?
if [[ $icarus_compile == 0 ]]; then /usr/bin/time -v -o icarus-run.resource timeout --signal=TERM --kill-after=5s 60s "$VVP" -n control.vvp > icarus.run.log 2>&1; icarus_run=$?; else icarus_run=NOT_RUN; fi
/usr/bin/time -v -o verilator.resource timeout --signal=TERM --kill-after=5s 60s "$VERILATOR" --binary --timing -Wno-fatal --top-module dynamic_array_slice_class_control --Mdir obj "$SOURCE" > verilator.compile.log 2>&1
verilator_compile=$?
if [[ $verilator_compile == 0 ]]; then /usr/bin/time -v -o verilator-run.resource timeout --signal=TERM --kill-after=5s 60s obj/Vdynamic_array_slice_class_control > verilator.run.log 2>&1; verilator_run=$?; else verilator_run=NOT_RUN; fi
set -e
cat > result.txt <<RESULT
icarus_compile=$icarus_compile
icarus_run=$icarus_run
verilator_compile=$verilator_compile
verilator_run=$verilator_run
RESULT
cat result.txt
