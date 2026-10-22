#!/bin/bash
#SBATCH --job-name=m16-darray-slice-repro
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-darray-slice-20261018-01/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-darray-slice-20261018-01
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
VERILATOR=/usr/bin/verilator
SOURCE="$RUN/source"
cd "$RUN"
{
  hostname
  date -u +%FT%TZ
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VERILATOR" --version
  sha256sum "$IVL" "$SOURCE"/*.sv
  git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD
} > job-meta.txt
set +e
/usr/bin/time -v -o icarus-slice.resource timeout --signal=TERM --kill-after=5s 60s "$IVL" -g2017 -s dynamic_array_slice -o slice.vvp "$SOURCE/dynamic_array_slice.sv" > icarus-slice.compile.log 2>&1
icarus_slice_compile=$?
if [[ $icarus_slice_compile == 0 ]]; then /usr/bin/time -v -o icarus-slice.run.resource timeout --signal=TERM --kill-after=5s 60s "$VVP" -n slice.vvp > icarus-slice.run.log 2>&1; icarus_slice_run=$?; else icarus_slice_run=NOT_RUN; fi
/usr/bin/time -v -o icarus-control.resource timeout --signal=TERM --kill-after=5s 60s "$IVL" -g2017 -s dynamic_array_slice_control -o control.vvp "$SOURCE/dynamic_array_slice_control.sv" > icarus-control.compile.log 2>&1
icarus_control_compile=$?
if [[ $icarus_control_compile == 0 ]]; then /usr/bin/time -v -o icarus-control.run.resource timeout --signal=TERM --kill-after=5s 60s "$VVP" -n control.vvp > icarus-control.run.log 2>&1; icarus_control_run=$?; else icarus_control_run=NOT_RUN; fi
/usr/bin/time -v -o verilator-slice.resource timeout --signal=TERM --kill-after=5s 60s "$VERILATOR" --binary --timing -Wno-fatal --top-module dynamic_array_slice --Mdir obj_slice "$SOURCE/dynamic_array_slice.sv" > verilator-slice.compile.log 2>&1
verilator_slice_compile=$?
if [[ $verilator_slice_compile == 0 ]]; then /usr/bin/time -v -o verilator-slice.run.resource timeout --signal=TERM --kill-after=5s 60s obj_slice/Vdynamic_array_slice > verilator-slice.run.log 2>&1; verilator_slice_run=$?; else verilator_slice_run=NOT_RUN; fi
set -e
printf 'icarus_slice_compile=%s\nicarus_slice_run=%s\nicarus_control_compile=%s\nicarus_control_run=%s\nverilator_slice_compile=%s\nverilator_slice_run=%s\n' "$icarus_slice_compile" "$icarus_slice_run" "$icarus_control_compile" "$icarus_control_run" "$verilator_slice_compile" "$verilator_slice_run" > result.txt
cat result.txt
