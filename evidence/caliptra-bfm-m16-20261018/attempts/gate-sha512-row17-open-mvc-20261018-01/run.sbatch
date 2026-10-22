#!/usr/bin/env bash
set -euo pipefail
RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-sha512-row17-open-mvc-20261018-01
SOURCE_ROOT="$RUN_DIR/source"
OUTPUT_DIR="$RUN_DIR/output"
mkdir -p "$SOURCE_ROOT" "$OUTPUT_DIR"
tar -xzf "$RUN_DIR/source.tar.gz" -C "$SOURCE_ROOT"
export CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
printf 'host=%s\n' "$(hostname)"
printf 'row=17\nname=SHA512_random_test\n'
python3 "$SOURCE_ROOT/dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py" \
  --repo-root "$SOURCE_ROOT" \
  --manifest "$SOURCE_ROOT/evidence/caliptra-bfm-m15-20261017/m15-test-to-environment.tsv" \
  --row-id 17 --output-dir "$OUTPUT_DIR/row-17" --timeout 600
python3 - "$OUTPUT_DIR/row-17/result.json" <<'PYRESULT'
import json, sys
result = json.load(open(sys.argv[1]))
print(json.dumps(result, indent=2, sort_keys=True))
sys.exit(0 if result.get('status') == 'PASS' else 2)
PYRESULT
