#!/bin/bash
#SBATCH --job-name=m21-a3-progress
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=04:10:00
#SBATCH --array=78,79,80,81,82,83,86,87,89,96,99,100,102,103,104,105,106%2
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-a3-progress-20261020-01/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-a3-progress-20261020-01/logs/%x-%A_%a.out

set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-a3-progress-20261020-01
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/vvp
ROW="$SLURM_ARRAY_TASK_ID"
TASK="$RUN/tasks/row-$ROW"
OUT="$TASK/output"
case "$ROW" in 78|79|80|81|82|83|86|87|89|96|99|100|102|103|104|105|106) ;; *) exit 64 ;; esac
case "$ROW" in
  78|79|81|89|104|105) CAP=2400 ;;
  83) CAP=7200 ;;
  80|82|86|87|96|99|100|102|103|106) CAP=14400 ;;
  *) exit 64 ;;
esac
mkdir -p "$OUT" "$RUN/raw"
test "$(sha256sum "$RUN/source-snapshot.tar.gz" | cut -d' ' -f1)" = 64f2547103b10bed7157951455833ce4d82d02fe501d01f8e0d6ccfaef09631c
test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test -z "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" status --porcelain --untracked-files=normal)"
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330
test "$(sha256sum "$VVP" | cut -d' ' -f1)" = 979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309
{
  hostname; date -u +%FT%TZ; uname -a; python3 --version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'; "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
  printf 'row_id=%s\nrow_timeout_seconds=%s\n' "$ROW" "$CAP"
} > "$TASK/job-meta.txt"
set +e
if [ "$ROW" = 83 ] || [ "$ROW" = 100 ]; then
  /usr/bin/time -v -o "$TASK/runner.resource" env \
    CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" \
    M20_BASE_RUNNER="$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" M20_REPO_ROOT="$SOURCE" \
    python3 "$RUN/m20_mlkem_setup_runner.py" \
      --repo-root "$SOURCE" --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
      --row-id "$ROW" --output-dir "$OUT" --timeout "$CAP" > "$TASK/runner.log" 2>&1
else
  /usr/bin/time -v -o "$TASK/runner.resource" env \
    CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" \
    python3 "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
      --repo-root "$SOURCE" --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
      --row-id "$ROW" --output-dir "$OUT" --timeout "$CAP" > "$TASK/runner.log" 2>&1
fi
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$TASK/job-meta.txt"
set -e
ARCHIVE="$RUN/raw/job-${SLURM_ARRAY_JOB_ID}_${ROW}.tar.gz"
tar -C "$RUN" -czf "$ARCHIVE" "tasks/row-$ROW"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
exit "$RC"
