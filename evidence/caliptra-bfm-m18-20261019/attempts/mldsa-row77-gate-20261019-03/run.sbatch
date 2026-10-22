#!/bin/bash
#SBATCH --job-name=m18-mldsa-row77-r3
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-mldsa-row77-gate-20261019-03/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-mldsa-row77-gate-20261019-03/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m18-mldsa-row77-gate-20261019-03
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
ADAMSBRIDGE_ROOT="$CALIPTRA_ROOT/submodules/adams-bridge"
IVL=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/vvp
OUT="$RUN/tasks/row-77/output"
mkdir -p "$OUT" "$RUN/raw" "$RUN/tasks/row-77"
test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(git -C "$ADAMSBRIDGE_ROOT" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test -z "$(git -C "$ADAMSBRIDGE_ROOT" status --porcelain --untracked-files=normal)"
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330
test "$(sha256sum "$VVP" | cut -d' ' -f1)" = 979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309
{
  hostname; date -u +%FT%TZ; uname -a; python3 --version; gcc --version | head -1
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$ADAMSBRIDGE_ROOT" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'; "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
} > "$RUN/tasks/row-77/job-meta.txt"
set +e
/usr/bin/time -v -o "$RUN/tasks/row-77/runner.resource" env CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" python3 "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" --repo-root "$SOURCE" --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" --row-id 77 --output-dir "$OUT" --timeout 600 > "$RUN/tasks/row-77/runner.log" 2>&1
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$RUN/tasks/row-77/job-meta.txt"
set -e
tar -C "$RUN" -czf "$RUN/raw/job-${SLURM_JOB_ID}.tar.gz" tasks logs
sha256sum "$RUN/raw/job-${SLURM_JOB_ID}.tar.gz" > "$RUN/raw/job-${SLURM_JOB_ID}.tar.gz.sha256"
exit "$RC"
