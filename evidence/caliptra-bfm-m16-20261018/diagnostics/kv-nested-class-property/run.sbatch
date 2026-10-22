#!/bin/bash
#SBATCH --job-name=m16-kv-nested-property
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-kv-nested-class-property-20261018-01/logs/%x-%j.out
set -euo pipefail

RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-kv-nested-class-property-20261018-01
SOURCE_ROOT="$RUN_DIR/source"
IVERILOG=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP="${IVERILOG%/*}/vvp"
mkdir -p "$RUN_DIR/build" "$RUN_DIR/output"
{
  hostname
  date -u +%FT%TZ
  sha256sum "$SOURCE_ROOT/nested_class_property_repro.sv" "$IVERILOG" "$VVP"
  "$IVERILOG" -V | head -n 1
  git -C /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl rev-parse HEAD
} > "$RUN_DIR/job-meta.txt"

set +e
/usr/bin/time -v -o "$RUN_DIR/output/compile.resource" timeout 60 \
  "$IVERILOG" -g2017 -s tb -o "$RUN_DIR/build/repro.vvp" "$SOURCE_ROOT/nested_class_property_repro.sv" \
  > "$RUN_DIR/output/compile.log" 2>&1
compile_rc=$?
set -e
echo "compile_exit=$compile_rc" > "$RUN_DIR/output/result.txt"
if [ "$compile_rc" -eq 0 ]; then
  set +e
  /usr/bin/time -v -o "$RUN_DIR/output/run.resource" timeout 30 \
    "$VVP" -n "$RUN_DIR/build/repro.vvp" > "$RUN_DIR/output/run.log" 2>&1
  run_rc=$?
  set -e
  echo "run_exit=$run_rc" >> "$RUN_DIR/output/result.txt"
fi
