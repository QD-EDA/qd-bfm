#!/bin/bash
#SBATCH --job-name=m18-adams-config
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:15:00
#SBATCH --array=61,65,69%2
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-adams-config-array-20261019-01/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-adams-config-array-20261019-01/logs/%x-%A_%a.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-adams-config-array-20261019-01
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
{
 hostname
 date -u +%FT%TZ
 uname -a
 python3 --version
 git -C "$CALIPTRA_ROOT" rev-parse HEAD
 git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal
 "$IVL" -V 2>&1 | sed -n '1p'
 "$VVP" -V 2>&1 | sed -n '1p'
 sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" \
   "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
} > "$TASK/job-meta.txt"
set +e
/usr/bin/time -v -o "$TASK/runner.resource" env CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" python3 "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" --repo-root "$SOURCE" --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" --row-id "$ROW" --output-dir "$OUT" --timeout 600 > "$TASK/runner.log" 2>&1
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$TASK/job-meta.txt"
set -e
ARCHIVE="$RUN/raw/job-${SLURM_ARRAY_JOB_ID}_${ROW}.tar.gz"
tar -C "$RUN" -czf "$ARCHIVE" "tasks/row-$ROW"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
exit "$RC"
