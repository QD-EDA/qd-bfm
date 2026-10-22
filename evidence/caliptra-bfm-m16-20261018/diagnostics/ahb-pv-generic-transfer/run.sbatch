#!/bin/bash
#SBATCH --job-name=m16-ahb-type-repro
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01/logs/%x-%j.out
set -uo pipefail

RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-pv-generic-transfer-20261018-01
IVERILOG=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
SOURCE="$RUN_DIR/pv_generic_transfer_repro.sv"

mkdir -p "$RUN_DIR/output"
{
  hostname
  date -u +%FT%TZ
  sha256sum "$SOURCE" "$IVERILOG" "$VVP"
  "$IVERILOG" -V 2>&1 | head -1
  "$VVP" -V 2>&1 | head -1
} > "$RUN_DIR/toolchain.txt"

set +e
/usr/bin/time -v -o "$RUN_DIR/output/compile.resource" timeout --signal=TERM --kill-after=5s 60s \
  "$IVERILOG" -g2012 -s pv_generic_transfer_repro -o "$RUN_DIR/output/repro.vvp" "$SOURCE" \
  > "$RUN_DIR/output/compile.log" 2>&1
compile_rc=$?
sim_rc=NOT_RUN
if [[ $compile_rc == 0 ]]; then
  /usr/bin/time -v -o "$RUN_DIR/output/sim.resource" timeout --signal=TERM --kill-after=5s 60s \
    "$VVP" -n "$RUN_DIR/output/repro.vvp" > "$RUN_DIR/output/sim.log" 2>&1
  sim_rc=$?
fi
printf 'compile_exit=%s\nsim_exit=%s\n' "$compile_rc" "$sim_rc" > "$RUN_DIR/output/result.txt"
cat "$RUN_DIR/output/result.txt"
exit 0
