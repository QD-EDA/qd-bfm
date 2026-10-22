#!/bin/bash
#SBATCH --job-name=m19-row57-numpy
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:20:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m19-row57-current-c339-numpy-20261019-01/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m19-row57-current-c339-numpy-20261019-01/logs/%x-%j.out
set -euo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m19-row57-current-c339-numpy-20261019-01
SOURCE="$RUN/source"
PYDEPS="$RUN/python-deps"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/vvp
ROW=57
TASK="$RUN/tasks/row-$ROW"
OUT="$TASK/output"
WHEEL="$RUN/numpy-2.5.4-cp314-cp314-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl"
mkdir -p "$PYDEPS" "$OUT" "$RUN/raw"

test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330
test "$(sha256sum "$VVP" | cut -d' ' -f1)" = 979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309
test "$(sha256sum "$RUN/source-snapshot.tar.gz" | cut -d' ' -f1)" = ce5ba73163820aea5c9c065f81bbd5758365f8fb0d78c5a2ca9949f300c2c284
test "$(sha256sum "$WHEEL" | cut -d' ' -f1)" = d549420b8858885cea8838a727842249218b9c1da24dd517e25c9c7a948310a3

tar -xzf "$RUN/source-snapshot.tar.gz" -C "$SOURCE"
python3 -m zipfile -e "$WHEEL" "$PYDEPS"
export PYTHONPATH="$PYDEPS${PYTHONPATH:+:$PYTHONPATH}"
{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  python3 -c 'import numpy; print("NumPy", numpy.__version__)'
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$WHEEL" "$RUN/source-snapshot.tar.gz"
} > "$TASK/job-meta.txt"

set +e
/usr/bin/time -v -o "$TASK/runner.resource" python3 "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$SOURCE" \
  --manifest "$SOURCE/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id "$ROW" --output-dir "$OUT" --timeout 600 > "$TASK/runner.log" 2>&1
RC=$?
printf 'runner_exit=%s\n' "$RC" >> "$TASK/job-meta.txt"
set -e

ARCHIVE="$RUN/raw/job-${SLURM_JOB_ID}_${ROW}.tar.gz"
tar -C "$RUN" -czf "$ARCHIVE" "tasks/row-$ROW"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
exit "$RC"
