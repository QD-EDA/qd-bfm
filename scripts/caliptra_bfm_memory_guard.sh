# Source this from Caliptra BFM test runners under dv/caliptra_bfm/*/tests.
# The runner is re-executed inside the guard; this child marker prevents recursion.
if [ "${CALIPTRA_BFM_MEMORY_GUARD_CHILD:-0}" != 1 ]; then
  case "$0" in
    */*) bfm_guard_script=$0 ;;
    *)
      if [ -f "$0" ]; then
        bfm_guard_script=./$0
      else
        bfm_guard_script=$(command -v "$0") || exit 127
      fi
      ;;
  esac
  bfm_guard_script_dir=$(CDPATH= cd -- "$(dirname "$bfm_guard_script")" && pwd)
  bfm_guard_script="$bfm_guard_script_dir/$(basename "$bfm_guard_script")"
  bfm_guard_repo_root=$(CDPATH= cd -- "$bfm_guard_script_dir/../../../.." && pwd)
  bfm_guard_timeout=${CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS:-300}
  exec python3 "$bfm_guard_repo_root/scripts/run_with_memory_pressure_guard.py" \
    --timeout-seconds "$bfm_guard_timeout" -- \
    env CALIPTRA_BFM_MEMORY_GUARD_CHILD=1 "$bfm_guard_script" "$@"
fi
