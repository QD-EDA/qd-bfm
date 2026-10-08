#!/bin/sh
set -eu

guard_timeout_default=1800
case " $* " in
    *" --force-first-rand-dma-reset "*) guard_timeout_default=5400 ;;
esac
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=${CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS:-$guard_timeout_default}
. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
exec python3 "$repo_root/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" "$@"
