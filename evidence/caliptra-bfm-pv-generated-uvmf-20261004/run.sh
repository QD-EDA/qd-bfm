#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PYTHON_BIN=${PYTHON_BIN:-python3}
exec "$PYTHON_BIN" "$script_dir/run.py" "$@"
