#!/bin/bash
#SBATCH --job-name=m16-psprintf-verilator
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-psprintf-empty-arg-20261018-02/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-psprintf-empty-arg-20261018-02
cd "$RUN"
{
  hostname
  date -u +%FT%TZ
  /usr/bin/verilator --version
  sha256sum source/*.sv
} > job-meta.txt
set +e
timeout --signal=TERM --kill-after=5s 60s /usr/bin/verilator --binary --timing -Wno-fatal --top-module psprintf_empty_arg --Mdir obj_empty source/psprintf_empty_arg.sv > verilator-empty.compile.log 2>&1
empty_compile=$?
if [[ $empty_compile == 0 ]]; then timeout --signal=TERM --kill-after=5s 60s obj_empty/Vpsprintf_empty_arg > verilator-empty.run.log 2>&1; empty_run=$?; else empty_run=NOT_RUN; fi
timeout --signal=TERM --kill-after=5s 60s /usr/bin/verilator --binary --timing -Wno-fatal --top-module psprintf_control --Mdir obj_control source/psprintf_control.sv > verilator-control.compile.log 2>&1
control_compile=$?
if [[ $control_compile == 0 ]]; then timeout --signal=TERM --kill-after=5s 60s obj_control/Vpsprintf_control > verilator-control.run.log 2>&1; control_run=$?; else control_run=NOT_RUN; fi
set -e
printf 'verilator_empty_compile=%s\nverilator_empty_run=%s\nverilator_control_compile=%s\nverilator_control_run=%s\n' "$empty_compile" "$empty_run" "$control_compile" "$control_run" > result.txt
cat result.txt
