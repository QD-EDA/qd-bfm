#!/bin/bash
#SBATCH --job-name=m20-socifc43-gate10
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G
#SBATCH --time=00:35:00
#SBATCH --array=43
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-socifc-row43-overlay-gate-20261019-10/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-socifc-row43-overlay-gate-20261019-10/logs/%x-%A_%a.out
set -euo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-socifc-row43-overlay-gate-20261019-10
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/vvp
ROW="$SLURM_ARRAY_TASK_ID"
TASK="$RUN/tasks/row-$ROW"
OUT="$TASK/output"
mkdir -p "$OUT" "$RUN/raw"

test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330
test "$(sha256sum "$VVP" | cut -d' ' -f1)" = 979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309
test "$(sha256sum "$RUN/source-snapshot.tar.gz" | cut -d' ' -f1)" = "$(cut -d' ' -f1 "$RUN/source-snapshot.tar.gz.sha256")"
test -f "$RUN/m20_socifc_overlay_runner.py"
(cd "$RUN" && sha256sum -c input-sha256.txt)
python3 "$RUN/m20_socifc_overlay_runner.py" --self-check

{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  verilator --version
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" "$RUN/m20_socifc_overlay_runner.py"
} > "$TASK/job-meta.txt"

set +e
/usr/bin/time -v -o "$TASK/runner.resource" env \
  CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" \
  M20_BASE_RUNNER="$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  python3 "$RUN/m20_socifc_overlay_runner.py" --repo-root "$SOURCE" \
    --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
    --row-id "$ROW" --output-dir "$OUT" --timeout 1800 > "$TASK/runner.log" 2>&1
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$TASK/job-meta.txt"
set -e

ARCHIVE="$RUN/raw/job-${SLURM_ARRAY_JOB_ID}_${ROW}.tar.gz"
tar -C "$RUN" -czf "$ARCHIVE" "tasks/row-$ROW"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
exit "$RC"
