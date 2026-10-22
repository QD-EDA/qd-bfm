#!/bin/bash
#SBATCH --job-name=m20-socifc-wildcard-rest-r4-fix2
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --array=0-3,43-45%1
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-socifc-wildcard-rest-r4-array-20261020-06/source
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-socifc-wildcard-rest-r4-array-20261020-06/logs/%x-%A_%a.out

set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m20-socifc-wildcard-rest-r4-array-20261020-06
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4/bin/vvp
ROW="$SLURM_ARRAY_TASK_ID"
TASK="$RUN/tasks/row-$ROW"
OUT="$TASK/output"

mkdir -p "$OUT" "$RUN/raw"
case "$ROW" in 0|1|2|3|43|44|45) ;; *) exit 64 ;; esac
test "$(sha256sum "$RUN/source-snapshot.tar.gz" | cut -d' ' -f1)" = cd6247481031ceb4c0355aa622f24f11e1d5c05d809383d60878c535916728ae
tar -xzf "$RUN/source-snapshot.tar.gz" -C "$SOURCE"
test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test -z "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" status --porcelain --untracked-files=normal)"
test "$(sha256sum "$IVL" | cut -d' ' -f1)" = 6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330
test "$(sha256sum "$VVP" | cut -d' ' -f1)" = 979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309
test "$(sha256sum "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" | cut -d' ' -f1)" = ed0a50d745b315194728c5d8687ab0363f10d55acb5cbc1fbf5e1685da3eeb89
test "$(sha256sum "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/test_run_m15_test.py" | cut -d' ' -f1)" = 38ae2d3df618be6320e0e2ea89d725cf08401a1111ab163e522050dbe2f7972c
test "$(sha256sum "$SOURCE/docs/conformance/release_overlays/caliptra/soc_ifc_generated_case_selector_overlay.py" | cut -d' ' -f1)" = 80d32c49e75130fd92af399a77dad3cd35834708ca38eb9c961c53ea9c302375

{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" \
    "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
    "$SOURCE/dv/caliptra_bfm/uvmf_lite/tests/test_run_m15_test.py" \
    "$SOURCE/docs/conformance/release_overlays/caliptra/soc_ifc_generated_case_selector_overlay.py"
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
