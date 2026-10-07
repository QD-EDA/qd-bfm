#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../../" && pwd)
. "$repo_root/scripts/caliptra_bfm_memory_guard.sh"
caliptra_root=${CALIPTRA_ROOT:-"$repo_root/../caliptra-rtl"}
iverilog_bin=${IVERILOG_BIN:-iverilog}
expected_caliptra_commit=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
expected_hdl_top_sha=23e3f134c7403c4604f6067096809c8a154881b1fbc1f37502dd7b29d7833827

if [ "$(git -C "$caliptra_root" rev-parse HEAD)" != "$expected_caliptra_commit" ]; then
  echo "Caliptra checkout is not the pinned v2.1.2 commit $expected_caliptra_commit" >&2
  exit 2
fi
if [ -n "$(git -C "$caliptra_root" status --porcelain --untracked-files=normal)" ]; then
  echo "Caliptra checkout must be clean; this probe never modifies it." >&2
  exit 2
fi

ecc_root="$caliptra_root/src/ecc"
ip_root="$ecc_root/uvmf_ecc/uvmf_template_output/verification_ip"
in_pkg="$ip_root/interface_packages/ECC_in_pkg"
out_pkg="$ip_root/interface_packages/ECC_out_pkg"
env_pkg="$ip_root/environment_packages/ECC_env_pkg"
bench="$ecc_root/uvmf_ecc/uvmf_template_output/project_benches/ECC/tb"
hdl_src="$bench/testbench/hdl_top.sv"
hdl_probe="$(dirname "$0")/tb_generated_ecc_hdl_top.sv"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

actual_hdl_sha=$(shasum -a 256 "$hdl_src" | awk '{print $1}')
if [ "$actual_hdl_sha" != "$expected_hdl_top_sha" ]; then
  echo "Generated hdl_top.sv hash changed: $actual_hdl_sha" >&2
  exit 2
fi
for selector in \
  'ECC_in_agent_bus.monitor_port' \
  'ECC_out_agent_bus.monitor_port' \
  'ECC_in_agent_bus.initiator_port'; do
  if [ "$(grep -Fc "$selector" "$hdl_src")" -ne 1 ]; then
    echo "Expected exactly one generated hdl_top connection using $selector" >&2
    exit 2
  fi
done

{
  printf '`timescale 1ns/1ps\n'
  sed \
    -e 's/ECC_in_agent_bus\.monitor_port/ECC_in_agent_bus/g' \
    -e 's/ECC_out_agent_bus\.monitor_port/ECC_out_agent_bus/g' \
    -e 's/ECC_in_agent_bus\.initiator_port/ECC_in_agent_bus/g' \
    "$hdl_src"
} > "$tmpdir/hdl_top_icarus.sv"

for edition in 2017 2023; do
  original_log="$tmpdir/original-$edition.log"
  overlay_log="$tmpdir/overlay-$edition.log"
  original_image="$tmpdir/original-$edition.vvp"
  image="$tmpdir/hdl-$edition.vvp"

  if CALIPTRA_ROOT="$caliptra_root" \
     CALIPTRA_PRIM_ROOT="$caliptra_root/src/caliptra_prim_generic" \
     CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic \
     "$iverilog_bin" -uvm -g"$edition" -s actual_ecc_generated_hdl_elab_probe \
       -f "$ecc_root/config/ecc_top.vf" \
       -I"$in_pkg" -I"$out_pkg" -I"$env_pkg" \
       -I"$bench/parameters" -I"$bench/sequences" -I"$bench/tests" \
       -o "$original_image" \
       "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv" \
       "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv" \
       "$in_pkg/ECC_in_pkg_hdl.sv" "$in_pkg/ECC_in_pkg.sv" \
       "$in_pkg/src/ECC_in_driver_bfm.sv" "$in_pkg/src/ECC_in_if.sv" \
       "$in_pkg/src/ECC_in_monitor_bfm.sv" \
       "$out_pkg/ECC_out_pkg_hdl.sv" "$out_pkg/ECC_out_pkg.sv" \
       "$out_pkg/src/ECC_out_driver_bfm.sv" "$out_pkg/src/ECC_out_if.sv" \
       "$out_pkg/src/ECC_out_monitor_bfm.sv" \
       "$env_pkg/ECC_env_pkg.sv" "$bench/parameters/ECC_parameters_pkg.sv" \
       "$bench/sequences/ECC_sequences_pkg.sv" "$bench/tests/ECC_tests_pkg.sv" \
       "$caliptra_root/src/ecc/coverage/ecc_top_cov_bind.sv" \
       "$hdl_src" "$hdl_probe" > "$original_log" 2>&1; then
    echo "Unmodified generated hdl_top unexpectedly compiled under IEEE $edition." >&2
    exit 1
  fi

  modport_errors=$(grep -Ec "error: cannot write to '(hrdata|hreadyout)' through modport 'initiator_port'" "$original_log" || true)
  if [ "$modport_errors" -ne 2 ]; then
    cat "$original_log" >&2
    echo "Expected the two generated initiator-port direction errors under IEEE $edition; saw $modport_errors." >&2
    exit 1
  fi

  if ! CALIPTRA_ROOT="$caliptra_root" \
       CALIPTRA_PRIM_ROOT="$caliptra_root/src/caliptra_prim_generic" \
       CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic \
       "$iverilog_bin" -uvm -g"$edition" -s actual_ecc_generated_hdl_elab_probe \
         -f "$ecc_root/config/ecc_top.vf" \
         -I"$in_pkg" -I"$out_pkg" -I"$env_pkg" \
         -I"$bench/parameters" -I"$bench/sequences" -I"$bench/tests" \
         -o "$image" \
         "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv" \
         "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv" \
         "$in_pkg/ECC_in_pkg_hdl.sv" "$in_pkg/ECC_in_pkg.sv" \
         "$in_pkg/src/ECC_in_driver_bfm.sv" "$in_pkg/src/ECC_in_if.sv" \
         "$in_pkg/src/ECC_in_monitor_bfm.sv" \
         "$out_pkg/ECC_out_pkg_hdl.sv" "$out_pkg/ECC_out_pkg.sv" \
         "$out_pkg/src/ECC_out_driver_bfm.sv" "$out_pkg/src/ECC_out_if.sv" \
         "$out_pkg/src/ECC_out_monitor_bfm.sv" \
         "$env_pkg/ECC_env_pkg.sv" "$bench/parameters/ECC_parameters_pkg.sv" \
         "$bench/sequences/ECC_sequences_pkg.sv" "$bench/tests/ECC_tests_pkg.sv" \
         "$caliptra_root/src/ecc/coverage/ecc_top_cov_bind.sv" \
         "$tmpdir/hdl_top_icarus.sv" "$hdl_probe" > "$overlay_log" 2>&1; then
    cat "$overlay_log" >&2
    echo "Generated ECC hdl_top overlay failed under IEEE $edition." >&2
    exit 1
  fi

  warning_count=$(grep -c 'warning:' "$overlay_log" || true)
  echo "PASS: actual ECC RTL and generated UVMF hdl_top elaborate with three modport selectors removed and a 1ns/1ps timescale under IEEE $edition ($warning_count compile-progress warnings)."
  echo "REPRODUCED: unmodified hdl_top has exactly two initiator_port direction errors under IEEE $edition."
done
