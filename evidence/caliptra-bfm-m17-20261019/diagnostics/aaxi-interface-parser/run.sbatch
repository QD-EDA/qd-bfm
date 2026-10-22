#!/bin/bash
#SBATCH --job-name=m17-aaxi-min
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-aaxi-min-20261019-11
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-aaxi-min-20261019-11/logs/%x-%j.out
set -u
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-aaxi-min-20261019-11
IVERILOG=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
mkdir -p "$RUN/logs"
{
  hostname
  date -u +%FT%TZ
  "$IVERILOG" -V 2>&1 | sed -n '1p'
  verilator --version
} > "$RUN/tool-versions.txt" 2>&1
for variant in ansi-wire ansi-logic nonansi-wire no-port; do
  set +e
  "$IVERILOG" -g2017 -s top -o "$RUN/$variant.vvp" "$RUN/source/$variant.sv" > "$RUN/logs/iverilog-$variant.log" 2>&1
  ivl_rc=$?
  verilator --lint-only --top-module top "$RUN/source/$variant.sv" > "$RUN/logs/verilator-$variant.log" 2>&1
  vlt_rc=$?
  set -e
  printf 'iverilog_%s=%s\nverilator_%s=%s\n' "$variant" "$ivl_rc" "$variant" "$vlt_rc" >> "$RUN/results.txt"
done
exit 0
