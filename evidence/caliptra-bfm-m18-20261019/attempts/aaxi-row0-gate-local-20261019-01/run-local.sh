#!/bin/bash
set -euo pipefail

ATTEMPT="$(cd "$(dirname "$0")" && pwd)"
REPO=/Users/danielellerbrock/projects/bfm-work/qd-bfm
CALIPTRA_ROOT=/tmp/a2-m18-aaxi-row0-local-01/caliptra-rtl
TOOL=/tmp/a2-m18-iverilog-cae035642e056644274a01e98d4422ce286685b4-local-02/tool
IVL="$TOOL/bin/iverilog"
VVP="$TOOL/bin/vvp"
OUT="$ATTEMPT/raw/output"

mkdir -p "$OUT"
test "$(git -C "$CALIPTRA_ROOT" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$CALIPTRA_ROOT" status --porcelain --untracked-files=normal)"
test "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test -z "$(git -C "$CALIPTRA_ROOT/submodules/adams-bridge" status --porcelain --untracked-files=normal)"
IVL_SHA256="$(shasum -a 256 "$IVL" | awk '{print $1}')"

{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT/submodules/adams-bridge" rev-parse HEAD
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  shasum -a 256 "$IVL" "$VVP"
  shasum -a 256 "$REPO/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
    "$REPO/dv/caliptra_bfm/uvmf_lite/tests/test_run_m15_test.py" \
    "$REPO/dv/caliptra_bfm/uvm/avery_defines.svh" \
    "$REPO/dv/caliptra_bfm/uvm/caliptra_bfm_aaxi_compat.f" \
    "$REPO/docs/conformance/release_overlays/caliptra/soc_ifc_aaxi_compat_overlay.py" \
    "$REPO/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv"
} > "$ATTEMPT/raw/run-info.txt"

(cd "$REPO" && shasum -a 256 \
  dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py \
  dv/caliptra_bfm/uvmf_lite/tests/test_run_m15_test.py \
  dv/caliptra_bfm/uvm/avery_defines.svh \
  dv/caliptra_bfm/uvm/caliptra_bfm_aaxi_compat.f \
  docs/conformance/release_overlays/caliptra/soc_ifc_aaxi_compat_overlay.py \
  evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv) > "$ATTEMPT/source-files.sha256"

env M18_REPO_ROOT="$REPO" M18_IVL_SHA256="$IVL_SHA256" \
    CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" \
    python3 "$ATTEMPT/run-local-gate.py" \
      --repo-root "$REPO" \
      --manifest "$REPO/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
      --row-id 0 --output-dir "$OUT" --timeout 600 \
      > "$ATTEMPT/raw/runner.log" 2>&1

tar -C "$ATTEMPT/raw" -czf "$ATTEMPT/raw/job-local.tar.gz" output run-info.txt runner.log
shasum -a 256 "$ATTEMPT/raw/job-local.tar.gz" > "$ATTEMPT/raw/job-local.tar.gz.sha256"
