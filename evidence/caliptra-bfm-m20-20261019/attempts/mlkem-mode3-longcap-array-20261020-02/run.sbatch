#!/bin/bash
#SBATCH --job-name=m20-mlkem-longcap
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=01:15:00
#SBATCH --array=85,100%2
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-mlkem-mode3-longcap-array-20261020-02
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-mlkem-mode3-longcap-array-20261020-02/logs/%x-%A_%a.out
set -euo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-mlkem-mode3-longcap-array-20261020-02
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/vvp
ROW="$SLURM_ARRAY_TASK_ID"
TASK="$RUN/tasks/row-$ROW"
SOURCE="$TASK/source"
OUT="$TASK/output"
mkdir -p "$OUT" "$RUN/raw" "$SOURCE"
(cd "$RUN" && sha256sum -c input-sha256.txt)
tar -xzf "$RUN/source-snapshot.tar.gz" -C "$SOURCE"
# The selective snapshot predates these working-tree helper files; stage their pinned overlay bytes per task.
install -m 0644 "$RUN/helper-source/native_mlkem.c" "$SOURCE/dv/caliptra_bfm/native_vectors/native_mlkem.c"
install -m 0644 "$RUN/helper-source/check_native_mlkem.py" "$SOURCE/dv/caliptra_bfm/native_vectors/check_native_mlkem.py"
install -m 0644 "$RUN/helper-source/random_test_ml_kem.py" "$SOURCE/dv/caliptra_bfm/native_vectors/random_test_ml_kem.py"
test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test -z "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" status --porcelain --untracked-files=normal)"
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330
test "$(sha256sum "$VVP" | cut -d' ' -f1)" = 979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309
cmp "$RUN/helper-source/native_mlkem.c" "$SOURCE/dv/caliptra_bfm/native_vectors/native_mlkem.c"
cmp "$RUN/helper-source/check_native_mlkem.py" "$SOURCE/dv/caliptra_bfm/native_vectors/check_native_mlkem.py"
cmp "$RUN/helper-source/random_test_ml_kem.py" "$SOURCE/dv/caliptra_bfm/native_vectors/random_test_ml_kem.py"
{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  cc --version | sed -n '1p'
  openssl version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" "$RUN/m20_mlkem_setup_runner.py" "$RUN/helper-source/native_mlkem.c" "$RUN/helper-source/check_native_mlkem.py" "$RUN/helper-source/random_test_ml_kem.py"
} > "$TASK/job-meta.txt"
set +e
/usr/bin/time -v -o "$TASK/runner.resource" env \
  CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" \
  M20_BASE_RUNNER="$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  M20_REPO_ROOT="$SOURCE" \
  python3 "$RUN/m20_mlkem_setup_runner.py" \
    --repo-root "$SOURCE" \
    --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
    --row-id "$ROW" --output-dir "$OUT" --timeout 3600 > "$TASK/runner.log" 2>&1
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$TASK/job-meta.txt"
set -e
ARCHIVE="$RUN/raw/job-${SLURM_JOB_ID}-${ROW}.tar.gz"
tar -C "$RUN" -czf "$ARCHIVE" "tasks/row-$ROW"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
exit "$RC"
