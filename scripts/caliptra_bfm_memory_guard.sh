# Source this from Caliptra BFM test runners under dv/caliptra_bfm/*/tests.
# The runner is re-executed inside the guard; this child marker prevents recursion.
if [ "${CALIPTRA_BFM_MEMORY_GUARD_CHILD:-0}" != 1 ]; then
  bfm_guard_repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
  bfm_guard_timeout=${CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS:-300}
  exec python3 "$bfm_guard_repo_root/scripts/run_with_memory_pressure_guard.py" \
    --timeout-seconds "$bfm_guard_timeout" -- \
    env CALIPTRA_BFM_MEMORY_GUARD_CHILD=1 "$0" "$@"
fi
