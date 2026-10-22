#!/bin/bash
#SBATCH --job-name=m17-aaxi-full
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:05:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-aaxi-full-20261019-13
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-aaxi-full-20261019-13/logs/%x-%j.out
set -u
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-aaxi-full-20261019-13
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
mkdir -p "$RUN/logs"
{
  hostname
  date -u +%FT%TZ
  "$IVL" -V 2>&1 | sed -n '1p'
  verilator --version
  sha256sum "$IVL" "$RUN/source/axi4_caliptra_record_if.sv"
} > "$RUN/tool-versions.txt" 2>&1
set +e
"$IVL" -uvm -g2017 -gassertions -DMAP_PROT_ATTR -s top -o "$RUN/full-uvm.vvp" "$RUN/source/axi4_caliptra_record_if.sv" "$RUN/source/full-interface-top.sv" > "$RUN/logs/iverilog-full-uvm.log" 2>&1
printf 'iverilog_full_uvm=%s\n' "$?" >> "$RUN/results.txt"
"$IVL" -g2017 -gassertions -DMAP_PROT_ATTR -s top -o "$RUN/full-no-uvm.vvp" "$RUN/source/axi4_caliptra_record_if.sv" "$RUN/source/full-interface-top.sv" > "$RUN/logs/iverilog-full-no-uvm.log" 2>&1
printf 'iverilog_full_no_uvm=%s\n' "$?" >> "$RUN/results.txt"
verilator --lint-only --top-module top "$RUN/source/axi4_caliptra_record_if.sv" "$RUN/source/full-interface-top.sv" > "$RUN/logs/verilator-full.log" 2>&1
printf 'verilator_full=%s\n' "$?" >> "$RUN/results.txt"
exit 0
