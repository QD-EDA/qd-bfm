#!/bin/bash
set -euo pipefail

attempt=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d /tmp/m20-row93-width.XXXXXX)
trap 'rm -rf "$work"' EXIT
tar -xzf "$attempt/source-snapshot.tar.gz" -C "$work"

runner="$work/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py"
iverilog_hash=$(shasum -a 256 "$IVERILOG_BIN" | awk '{print $1}')
iverilog_version=$("$IVERILOG_BIN" -V 2>&1 | sed -n '1p')
python3 - "$runner" "$iverilog_hash" "$iverilog_version" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old_pin = 'IVERILOG_PIN = "cae035642e056644274a01e98d4422ce286685b4"'
old_hash = 'IVERILOG_SHA256 = "6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330"'
if text.count(old_pin) != 1 or text.count(old_hash) != 1:
    raise SystemExit("expected the pinned Icarus version and hash exactly once")
text = text.replace(old_pin, f'IVERILOG_PIN = "local {sys.argv[3]} sha256={sys.argv[2]}"')
text = text.replace(old_hash, f'IVERILOG_SHA256 = "{sys.argv[2]}"')
path.write_text(text)
PY

python3 "$runner" \
  --repo-root "$work" \
  --manifest "$work/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id 93 \
  --output-dir "$attempt/output" \
  --timeout 1800
