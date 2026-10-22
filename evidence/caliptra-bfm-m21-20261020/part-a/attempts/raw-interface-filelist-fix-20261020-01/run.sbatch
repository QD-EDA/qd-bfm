#!/bin/bash
#SBATCH --job-name=m21-a2-rawifc-r3
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=01:10:00
#SBATCH --array=54-55%2
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-a2-raw-interface-20261020-03/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-a2-raw-interface-20261020-03/logs/%x-%A_%a.out

set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-a2-raw-interface-20261020-03
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-main-cc25756d187314742d347267c2a513b3e640a7fb/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-main-cc25756d187314742d347267c2a513b3e640a7fb/bin/vvp
ROW="$SLURM_ARRAY_TASK_ID"
TASK="$RUN/tasks/row-$ROW"
OUT="$TASK/output"
mkdir -p "$OUT" "$RUN/raw"
case "$ROW" in 54|55) ;; *) exit 64 ;; esac
test "$(sha256sum "$RUN/source-snapshot.tar.gz" | cut -d' ' -f1)" = 464ff4649187a285cf24426a501779a36079fea8f97b6d9a1bacce2de4095012
test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test -z "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" status --porcelain --untracked-files=normal)"
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 87bb417df23d260bcfde3fb372b4a80eaad69e4fd2eea1ffb8b0eff10f7af08e
test "$(sha256sum "$VVP" | cut -d' ' -f1)" = dfc193c466a70a0917a16ab4198a111de616657d6004de79456db2a4b603b437
test "$(sha256sum "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" | cut -d' ' -f1)" = 9a8fd935742b1181b1a58e9c19d6dda988e4a04479709d7feb6f6999ac3a2556
{
  hostname; date -u +%FT%TZ; uname -a; python3 --version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'; "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
} > "$TASK/job-meta.txt"
set +e
/usr/bin/time -v -o "$TASK/runner.resource" env \
  CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" \
  python3 "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
    --repo-root "$SOURCE" \
    --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
    --row-id "$ROW" --output-dir "$OUT" --timeout 3600 \
  > "$TASK/runner.log" 2>&1
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$TASK/job-meta.txt"
set -e
ARCHIVE="$RUN/raw/job-${SLURM_ARRAY_JOB_ID}_${ROW}.tar.gz"
tar -C "$RUN" -czf "$ARCHIVE" "tasks/row-$ROW"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
exit "$RC"
