#!/bin/bash
#SBATCH --job-name=m16-psprintf-repro
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-psprintf-empty-arg-20261018-01/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-psprintf-empty-arg-20261018-01
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
VERILATOR=/usr/bin/verilator
SOURCE="$RUN/source"
cd "$RUN"
{
  hostname
  date -u +%FT%TZ
  "$IVL" -V 2>&1 | sed -n "1p"
  "$VERILATOR" --version
  sha256sum "$IVL"
  git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD
  sha256sum "$SOURCE/psprintf_empty_arg.sv" "$SOURCE/psprintf_control.sv"
} > job-meta.txt
set +e
timeout --signal=TERM --kill-after=5s 60s "$IVL" -g2017 -s psprintf_empty_arg -o repro-empty.vvp "$SOURCE/psprintf_empty_arg.sv" > icarus-empty.compile.log 2>&1
icarus_empty_compile=$?
if [[ $icarus_empty_compile == 0 ]]; then timeout --signal=TERM --kill-after=5s 60s "$VVP" -n repro-empty.vvp > icarus-empty.run.log 2>&1; icarus_empty_run=$?; else icarus_empty_run=NOT_RUN; fi
timeout --signal=TERM --kill-after=5s 60s "$IVL" -g2017 -s psprintf_control -o repro-control.vvp "$SOURCE/psprintf_control.sv" > icarus-control.compile.log 2>&1
icarus_control_compile=$?
if [[ $icarus_control_compile == 0 ]]; then timeout --signal=TERM --kill-after=5s 60s "$VVP" -n repro-control.vvp > icarus-control.run.log 2>&1; icarus_control_run=$?; else icarus_control_run=NOT_RUN; fi
timeout --signal=TERM --kill-after=5s 60s "$VERILATOR" --lint-only -Wno-fatal --top-module psprintf_empty_arg "$SOURCE/psprintf_empty_arg.sv" > verilator-empty.log 2>&1
verilator_empty=$?
timeout --signal=TERM --kill-after=5s 60s "$VERILATOR" --lint-only -Wno-fatal --top-module psprintf_control "$SOURCE/psprintf_control.sv" > verilator-control.log 2>&1
verilator_control=$?
set -e
{
  printf 'icarus_empty_compile=%s\nicarus_empty_run=%s\nicarus_control_compile=%s\nicarus_control_run=%s\nverilator_empty_lint=%s\nverilator_control_lint=%s\n' "$icarus_empty_compile" "$icarus_empty_run" "$icarus_control_compile" "$icarus_control_run" "$verilator_empty" "$verilator_control"
} > result.txt
cat result.txt
