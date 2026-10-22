#!/bin/bash
#SBATCH --job-name=m20b-wide-bins
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:15:00
#SBATCH --array=16,17,54,55%2
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m20b-wide-bins-8c95b5cc-20261020-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m20b-wide-bins-8c95b5cc-20261020-01/logs/%x-%A_%a.out
set -euo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m20b-wide-bins-8c95b5cc-20261020-01
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-main-8c95b5cc10fc83d15b47e0364d2d7b4a2e12cac1/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-main-8c95b5cc10fc83d15b47e0364d2d7b4a2e12cac1/bin/vvp
ROW="$SLURM_ARRAY_TASK_ID"
TASK="$RUN/tasks/row-$ROW"
OUT="$TASK/output"
mkdir -p "$OUT" "$RUN/raw"
(cd "$RUN" && sha256sum -c input-sha256.txt)
test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test -z "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" status --porcelain --untracked-files=normal)"
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 825148179dae25095eb5ec3d7804a5c5c0a09102c78dc47d2f86ffdf95141d6d
test "$(sha256sum "$VVP" | cut -d' ' -f1)" = 36831eaf6a1902cd3625bc5db478636a1d3dc7bb8030c000e1d19a3d46f28375
{
  hostname
  date -u +%FT%TZ
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$RUN/run_m15_test_main.py" "$RUN/m15-test-to-environment.tsv"
} > "$TASK/job-meta.txt"
set +e
/usr/bin/time -v -o "$TASK/runner.resource" env \
  CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" \
  python3 "$RUN/run_m15_test_main.py" \
    --repo-root "$RUN" \
    --manifest "$RUN/m15-test-to-environment.tsv" \
    --row-id "$ROW" --output-dir "$OUT" --timeout 3600 > "$TASK/runner.log" 2>&1
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$TASK/job-meta.txt"
set -e
ARCHIVE="$RUN/raw/job-${SLURM_JOB_ID}_${ROW}.tar.gz"
tar -C "$RUN" -czf "$ARCHIVE" "tasks/row-$ROW"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
exit "$RC"
