#!/usr/bin/env bash
#SBATCH --job-name=a2-top-noassert
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:30:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/top-noassert-c339-20261011-02
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/top-noassert-c339-20261011-02/logs/%x-%j.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/top-noassert-c339-20261011-02
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
ROOT="$RUN/source"
TASK="$RUN/results/caliptra_top_ss_mode_tb"
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
export RUN BASE ROOT TASK IVERILOG VVP
export CALIPTRA_ROOT="$ROOT"
export CALIPTRA_PRIM_ROOT="$ROOT/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$ROOT/qd-bfm/dv/caliptra_bfm/axi/arm_axi4pc_compat"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p "$TASK/runtime"
hostname > "$TASK/host.txt"
cp "$ROOT/revisions.txt" "$TASK/source-revisions.txt"
grep '^Icarus=' "$ROOT/revisions.txt" | cut -d= -f2 > "$TASK/iverilog-source-revision.txt"
sha256sum "$IVERILOG" "$VVP" > "$TASK/tool-binaries.sha256"
"$IVERILOG" -V > "$TASK/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK/vvp-version.txt" 2>&1
cp -a "$ROOT/src/integration/tb/." "$TASK/runtime/"
FILE="$ROOT/src/integration/config/caliptra_top_ss_mode_tb.vf"
export FILE
set +e
timeout --signal=TERM --kill-after=30s 1500s bash -c '
  /usr/bin/time -v -o "$TASK/compile.resource" "$IVERILOG" -g2017 -gno-assertions -s caliptra_top_tb -I "$ROOT/submodules/adams-bridge/src/abr_prim/rtl" -I "$ROOT/submodules/adams-bridge/src/abr_libs/rtl" -f "$FILE" -o "$TASK/caliptra_top_tb.vvp" > "$TASK/compile.log" 2>&1
  compile_rc=$?
  printf "compile_exit=%s\n" "$compile_rc" > "$TASK/stage-status.txt"
  exit "$compile_rc"
'
runner_rc=$?
set -e
printf 'runner_exit=%s\n' "$runner_rc" >> "$TASK/stage-status.txt"
cat "$TASK/stage-status.txt"
exit 0
