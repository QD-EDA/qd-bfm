#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../../" && pwd)
caliptra_root=${CALIPTRA_ROOT:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ecc_root="$caliptra_root/src/ecc/uvmf_ecc/uvmf_template_output/verification_ip"
in_pkg="$ecc_root/interface_packages/ECC_in_pkg"
out_pkg="$ecc_root/interface_packages/ECC_out_pkg"
env_pkg="$ecc_root/environment_packages/ECC_env_pkg"
bench_root="$caliptra_root/src/ecc/uvmf_ecc/uvmf_template_output/project_benches/ECC/tb"
parameters_pkg="$bench_root/parameters/ECC_parameters_pkg.sv"
sequences_pkg="$bench_root/sequences/ECC_sequences_pkg.sv"
tests_pkg="$bench_root/tests/ECC_tests_pkg.sv"
in_driver_bfm="$in_pkg/src/ECC_in_driver_bfm.sv"
in_if="$in_pkg/src/ECC_in_if.sv"
in_monitor_bfm="$in_pkg/src/ECC_in_monitor_bfm.sv"
out_driver_bfm="$out_pkg/src/ECC_out_driver_bfm.sv"
out_if="$out_pkg/src/ECC_out_if.sv"
out_monitor_bfm="$out_pkg/src/ECC_out_monitor_bfm.sv"
for path in \
  "$in_pkg/ECC_in_pkg.sv" "$out_pkg/ECC_out_pkg.sv" "$env_pkg/ECC_env_pkg.sv" \
  "$in_driver_bfm" "$in_if" "$in_monitor_bfm" \
  "$out_driver_bfm" "$out_if" "$out_monitor_bfm" \
  "$parameters_pkg" "$sequences_pkg" "$tests_pkg"; do
  if [ ! -f "$path" ]; then
    echo "Missing generated ECC package: $path" >&2
    exit 2
  fi
done

cat >"$tmpdir/top.sv" <<'EOF'
module actual_ecc_bfm_elab_top;
  bit clk;
  bit rst_n;
  ECC_in_if in_bus(.clk(clk), .rst_n(rst_n));
  ECC_out_if out_bus(.clk(clk), .rst_n(rst_n));
  ECC_in_driver_bfm in_driver(in_bus);
  ECC_in_monitor_bfm in_monitor(in_bus);
  ECC_out_driver_bfm out_driver(out_bus);
  ECC_out_monitor_bfm out_monitor(out_bus);
endmodule
EOF

for edition in 2017 2023; do
  log="$tmpdir/ecc_actual_packages_$edition.log"
  set +e
  "$IVERILOG_BIN" -uvm -g"$edition" -tnull -s actual_ecc_bfm_elab_top \
    -I"$in_pkg" -I"$out_pkg" -I"$env_pkg" \
    -I"$bench_root/parameters" -I"$bench_root/sequences" -I"$bench_root/tests" \
    "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv" \
    "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv" \
    "$in_pkg/ECC_in_pkg_hdl.sv" "$in_pkg/ECC_in_pkg.sv" \
    "$in_driver_bfm" "$in_if" "$in_monitor_bfm" \
    "$out_pkg/ECC_out_pkg_hdl.sv" "$out_pkg/ECC_out_pkg.sv" \
    "$out_driver_bfm" "$out_if" "$out_monitor_bfm" \
    "$env_pkg/ECC_env_pkg.sv" "$parameters_pkg" "$sequences_pkg" "$tests_pkg" \
    "$tmpdir/top.sv" >"$log" 2>&1
  status=$?
  set -e

  if grep -Eq 'Unable to bind .*`(ACTIVE|PASSIVE|INITIATOR|RESPONDER)`' "$log"; then
    cat "$log" >&2
    echo "Generated ECC base enum lookup failed under IEEE $edition." >&2
    exit 1
  fi

  error_count=$(grep -c 'error:' "$log" || true)
  warning_count=$(grep -c 'warning:' "$log" || true)
  if [ "$status" -eq 0 ] && [ "$error_count" -eq 0 ]; then
    echo "PASS: actual generated ECC BFM/interface instances and environment/parameter/sequence/test packages elaborate under IEEE $edition ($warning_count compiler warnings)."
  else
    cat "$log" >&2
    echo "Generated ECC source-order probe failed under IEEE $edition (status $status, errors $error_count)." >&2
    exit 1
  fi
done
