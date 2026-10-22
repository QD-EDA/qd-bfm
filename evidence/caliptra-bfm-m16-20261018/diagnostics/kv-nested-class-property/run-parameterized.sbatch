#!/bin/bash
#SBATCH --job-name=m16-kv-nested-repro
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-kv-nested-repro-20261018-01/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-kv-nested-repro-20261018-01
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
VERILATOR=/usr/bin/verilator
SRC="$RUN/source"
cd "$RUN"
{
  hostname
  date -u +%FT%TZ
  "$IVL" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$SRC"/*.sv
  git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD
  "$VERILATOR" --version
} > job-meta.txt
set +e
/usr/bin/time -v -o icarus-primary.resource timeout --signal=TERM --kill-after=5s 60s "$IVL" -g2017 -s top -o primary.vvp "$SRC/parameterized_config_path.sv" > icarus-primary.compile.log 2>&1
icarus_primary_compile=$?
if [[ $icarus_primary_compile == 0 ]]; then /usr/bin/time -v -o icarus-primary-run.resource timeout --signal=TERM --kill-after=5s 60s "$VVP" -n primary.vvp > icarus-primary.run.log 2>&1; icarus_primary_run=$?; else icarus_primary_run=NOT_RUN; fi
/usr/bin/time -v -o icarus-control.resource timeout --signal=TERM --kill-after=5s 60s "$IVL" -g2017 -s top -o control.vvp "$SRC/parameterized_config_alias_control.sv" > icarus-control.compile.log 2>&1
icarus_control_compile=$?
if [[ $icarus_control_compile == 0 ]]; then /usr/bin/time -v -o icarus-control-run.resource timeout --signal=TERM --kill-after=5s 60s "$VVP" -n control.vvp > icarus-control.run.log 2>&1; icarus_control_run=$?; else icarus_control_run=NOT_RUN; fi
/usr/bin/time -v -o verilator-primary.resource timeout --signal=TERM --kill-after=5s 60s "$VERILATOR" --binary --timing -Wno-fatal --top-module top --Mdir obj_primary "$SRC/parameterized_config_path.sv" > verilator-primary.compile.log 2>&1
verilator_primary_compile=$?
if [[ $verilator_primary_compile == 0 ]]; then /usr/bin/time -v -o verilator-primary-run.resource timeout --signal=TERM --kill-after=5s 60s obj_primary/Vtop > verilator-primary.run.log 2>&1; verilator_primary_run=$?; else verilator_primary_run=NOT_RUN; fi
/usr/bin/time -v -o verilator-control.resource timeout --signal=TERM --kill-after=5s 60s "$VERILATOR" --binary --timing -Wno-fatal --top-module top --Mdir obj_control "$SRC/parameterized_config_alias_control.sv" > verilator-control.compile.log 2>&1
verilator_control_compile=$?
if [[ $verilator_control_compile == 0 ]]; then /usr/bin/time -v -o verilator-control-run.resource timeout --signal=TERM --kill-after=5s 60s obj_control/Vtop > verilator-control.run.log 2>&1; verilator_control_run=$?; else verilator_control_run=NOT_RUN; fi
set -e
cat > result.txt <<RESULT
icarus_primary_compile=$icarus_primary_compile
icarus_primary_run=$icarus_primary_run
icarus_control_compile=$icarus_control_compile
icarus_control_run=$icarus_control_run
verilator_primary_compile=$verilator_primary_compile
verilator_primary_run=$verilator_primary_run
verilator_control_compile=$verilator_control_compile
verilator_control_run=$verilator_control_run
RESULT
cat result.txt
