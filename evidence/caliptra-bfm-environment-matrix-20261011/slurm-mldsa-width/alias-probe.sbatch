#!/usr/bin/env bash
#SBATCH --job-name=a2-width-alias
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/env-mldsa-alias-c339-20261011-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/env-mldsa-alias-c339-20261011-01/logs/slurm-%j.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/env-mldsa-alias-c339-20261011-01
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$RUN/source"
ROOT="$RTL/submodules/adams-bridge"
TOP=decompose_tb
FILE="$ROOT/src/decompose/config/decompose_tb.vf"
TASK_DIR="$RUN/tasks/$TOP"
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"

export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$ROOT"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p "$TASK_DIR"
test "$(cat "$RUN/source/caliptra-rtl.commit")" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$BASE/source/iverilog-uvm" rev-parse HEAD)" = c339b9f2287a743aeb7ab6de6528e8d34a4dd602
test -z "$(git -C "$BASE/source/iverilog-uvm" status --porcelain --untracked-files=all)"
test -f "$FILE" && test -x "$IVERILOG" && test -x "$VVP"
printf '%s\n' "$RUN/source/revisions.txt" > "$TASK_DIR/source-path.txt"
cat "$RUN/source/revisions.txt" > "$TASK_DIR/source-revisions.txt"
sha256sum "$FILE" "$ROOT/src/abr_top/rtl/abr_params_pkg.sv" "$IVERILOG" "$VVP" > "$TASK_DIR/input-hashes.txt"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

set +e
timeout --signal=TERM --kill-after=10s 120s /usr/bin/time -v -o "$TASK_DIR/compile.resource" \
  "$IVERILOG" -g2017 -gassertions -s "$TOP" \
  -I "$ROOT/src/abr_prim/rtl" -I "$ROOT/src/abr_libs/rtl" \
  -f "$FILE" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
rc=$?
set -e
printf 'top=%s\ncompile_exit=%s\n' "$TOP" "$rc" > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
