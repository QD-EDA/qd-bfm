#!/bin/bash
#SBATCH --job-name=m18-kv-9-10-r1
#SBATCH --array=0-1%2
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-kv-rows9-10-current-main-20261019-01/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-kv-rows9-10-current-main-20261019-01/logs/%x-%A_%a.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-kv-rows9-10-current-main-20261019-01
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
ADAMSBRIDGE_ROOT="$CALIPTRA_ROOT/submodules/adams-bridge"
IVL=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/vvp
case "$SLURM_ARRAY_TASK_ID" in 0) ROW=9 ;; 1) ROW=10 ;; *) exit 2 ;; esac
OUT="$RUN/tasks/row-$ROW/output"
mkdir -p "$OUT" "$RUN/raw" "$RUN/tasks/row-$ROW"
test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$ADAMSBRIDGE_ROOT" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330
{
  hostname; date -u +%FT%TZ; uname -a; python3 --version; gcc --version | head -1
  git -C "$CALIPTRA_ROOT" rev-parse HEAD; git -C "$ADAMSBRIDGE_ROOT" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'; "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
} > "$RUN/tasks/row-$ROW/job-meta.txt"
set +e
/usr/bin/time -v -o "$RUN/tasks/row-$ROW/runner.resource" env CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" python3 "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" --repo-root "$SOURCE" --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" --row-id "$ROW" --output-dir "$OUT" --timeout 600 > "$RUN/tasks/row-$ROW/runner.log" 2>&1
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$RUN/tasks/row-$ROW/job-meta.txt"
set -e
ARCHIVE="$RUN/raw/job-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.tar.gz"
tar -C "$RUN" -czf "$ARCHIVE" "tasks/row-$ROW"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
exit "$RC"
