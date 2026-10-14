#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
if [ "${CALIPTRA_BFM_MEMORY_GUARD_CHILD:-0}" != 1 ]; then
  timeout=${CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS:-300}
  exec python3 "$repo_root/scripts/run_with_memory_pressure_guard.py" \
    --timeout-seconds "$timeout" -- \
    env CALIPTRA_BFM_MEMORY_GUARD_CHILD=1 sh "$0" "$@"
fi
caliptra_root=${CALIPTRA_ROOT:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
PYTHON_BIN=${PYTHON_BIN:-python3}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

status_pkg="$caliptra_root/src/soc_ifc/uvmf_soc_ifc/uvmf_template_output/verification_ip/interface_packages/cptra_status_pkg"
overlay_helper="$repo_root/docs/conformance/release_overlays/caliptra/cptra_status_psprintf_empty_arg_overlay.py"
"$PYTHON_BIN" "$overlay_helper" "$status_pkg" "$tmpdir/overlay"

cat >"$tmpdir/caliptra_macro_preamble.sv" <<'EOF'
module caliptra_macro_preamble;
  `include "caliptra_macros.svh"
endmodule
EOF

for edition in 2017 2023; do
  compile_log="$tmpdir/compile-$edition.log"
  run_log="$tmpdir/run-$edition.log"
  image="$tmpdir/status-full-snapshot-$edition.vvp"
  if ! "$IVERILOG_BIN" -uvm -g"$edition" -s tb_generated_status_full_snapshot \
    -I"$tmpdir/overlay" -I"$status_pkg" -I"$caliptra_root/src/libs/rtl" \
    -o "$image" \
    "$tmpdir/caliptra_macro_preamble.sv" \
    "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv" \
    "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv" \
    "$caliptra_root/src/keyvault/rtl/kv_defines_pkg.sv" \
    "$status_pkg/cptra_status_pkg_hdl.sv" "$status_pkg/cptra_status_pkg.sv" \
    "$tmpdir/overlay/src/cptra_status_driver_bfm.sv" \
    "$status_pkg/src/cptra_status_if.sv" \
    "$tmpdir/overlay/src/cptra_status_monitor_bfm.sv" \
    "$repo_root/evidence/caliptra-bfm-generated-status-full-snapshot-20261004/full_snapshot_probe.sv" \
    >"$compile_log" 2>&1; then
    cat "$compile_log" >&2
    echo "Generated status full-snapshot probe did not compile under IEEE $edition." >&2
    exit 1
  fi
  if grep -q 'error:' "$compile_log"; then
    cat "$compile_log" >&2
    echo "Generated status full-snapshot probe reported errors under IEEE $edition." >&2
    exit 1
  fi

  if ! "$VVP_BIN" "$image" >"$run_log" 2>&1; then
    cat "$run_log" >&2
    echo "Generated status full-snapshot probe failed under IEEE $edition." >&2
    exit 1
  fi
  if ! grep -Fq 'PASS: generated passive monitor preserved all status fields and the generated coverage subscriber received all three snapshots' "$run_log" \
    || ! grep -Fq 'UVM_WARNING :    0' "$run_log" \
    || ! grep -Fq 'UVM_ERROR :    0' "$run_log" \
    || ! grep -Fq 'UVM_FATAL :    0' "$run_log"; then
    cat "$run_log" >&2
    echo "Generated status full-field snapshot checks did not pass under IEEE $edition." >&2
    exit 1
  fi

  warning_count=$(grep -c 'warning:' "$compile_log" || true)
  echo "PASS: generated status monitor preserved all 17 fields and delivered all three snapshots to its coverage subscriber under IEEE $edition ($warning_count compile warnings)."
  grep -E 'STATUS_SNAPSHOT|UVM_WARNING :|UVM_ERROR :|UVM_FATAL :' "$run_log"
done
