#!/bin/sh
set -eu

export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=${CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS:-1800}
. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
exec python3 "$repo_root/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" "$@"
