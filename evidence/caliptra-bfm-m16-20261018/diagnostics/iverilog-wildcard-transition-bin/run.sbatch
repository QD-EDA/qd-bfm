#!/bin/bash
#SBATCH --job-name=m16-wildcard-bin
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:02:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-wildcard-bin-repro-20261018-01/logs/%x-%j.out
set -euo pipefail
RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-wildcard-bin-repro-20261018-01
IVERILOG_BIN=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP_BIN=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
{
  hostname
  date -u +%FT%TZ
  uname -a
  "$IVERILOG_BIN" -V | head -n 1
  sha256sum "$IVERILOG_BIN" "$VVP_BIN" "$RUN_DIR/wildcard_transition_bin_tb.sv"
} > "$RUN_DIR/job-meta.txt"
set +e
/usr/bin/time -v -o "$RUN_DIR/resource.txt" timeout --signal=TERM --kill-after=2s 30s \
  "$IVERILOG_BIN" -g2012 -s wildcard_transition_bin_tb \
  -o "$RUN_DIR/wildcard_transition_bin_tb.vvp" \
  "$RUN_DIR/wildcard_transition_bin_tb.sv" \
  > "$RUN_DIR/compile.log" 2>&1
rc=$?
printf '%s\n' "$rc" > "$RUN_DIR/compile.exit"
exit "$rc"
