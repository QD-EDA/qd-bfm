#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

edition_filter=${ECC_IEEE_EDITION:-both}
case "$edition_filter" in
  both|2017|2023) ;;
  *) echo "ECC_IEEE_EDITION must be both, 2017, or 2023" >&2; exit 2 ;;
esac

probe=${ECC_RUNTIME_PROBE:-reset}
case "$probe" in
  reset|key_sign) ;;
  *) echo "ECC_RUNTIME_PROBE must be reset or key_sign" >&2; exit 2 ;;
esac
if [ "$probe" = key_sign ] && [ -z "${CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS:-}" ]; then
  CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=1800
  export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS
fi

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../../" && pwd)
. "$repo_root/scripts/caliptra_bfm_memory_guard.sh"
test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
caliptra_root=${CALIPTRA_ROOT:-"$repo_root/../caliptra-rtl"}
iverilog_bin=${IVERILOG_BIN:-iverilog}
vvp_bin=${VVP_BIN:-vvp}
expected_caliptra_commit=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
expected_hdl_top_sha=23e3f134c7403c4604f6067096809c8a154881b1fbc1f37502dd7b29d7833827
case "$probe" in
  reset)
    test_name=ecc_reset_only_test
    pass_marker='PASS: generated reset scoreboard and ECC IRQ_EN AHB readback matched'
    log_prefix=${ECC_RESET_MONITOR_LOG_PREFIX:-reset_monitor_overlay}
    ;;
  key_sign)
    test_name=ecc_key_sign_only_test
    pass_marker='PASS: generated ECC key-sign transaction matched'
    log_prefix=${ECC_KEY_SIGN_LOG_PREFIX:-key_sign_overlay}
    ;;
esac

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
hdl_sha=$(shasum -a 256 "$hdl_src" | awk '{print $1}')
if [ "$hdl_sha" != "$expected_hdl_top_sha" ]; then
  echo "Generated hdl_top.sv hash changed: $hdl_sha" >&2
  exit 2
fi
if [ "$probe" = key_sign ] &&
   [ "$(grep -Fc '.cptra_pwrgood    (),' "$hdl_src")" -ne 1 ]; then
  echo "Expected the pinned ECC hdl_top to leave cptra_pwrgood unconnected." >&2
  exit 2
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM
python3 "$test_dir/generated_ecc_monitor_overlay.py" "$caliptra_root" "$tmpdir/monitors"
if [ "$probe" = key_sign ]; then
  brew_bin=${BREW:-brew}
  cc_bin=${CC:-clang}
  if ! mbedtls_root=$("$brew_bin" --prefix mbedtls@3); then
    echo "The key-sign probe needs the Homebrew mbedtls@3 package." >&2
    exit 2
  fi
  if ! "$cc_bin" -O2 -I"$mbedtls_root/include" \
       "$caliptra_root/src/ecc/tb/ecc_secp384r1.c" \
       -L"$mbedtls_root/lib" -lmbedtls -lmbedx509 -lmbedcrypto \
       -o "$tmpdir/ecc_secp384r1.exe"; then
    echo "Could not build the generated ECC native-vector helper." >&2
    exit 1
  fi
fi
{
  printf '`timescale 1ns/1ps\n'
  sed \
    -e 's/ECC_in_agent_bus\.monitor_port/ECC_in_agent_bus/g' \
    -e 's/ECC_out_agent_bus\.monitor_port/ECC_out_agent_bus/g' \
    -e 's/ECC_in_agent_bus\.initiator_port/ECC_in_agent_bus/g' \
    "$hdl_src"
} > "$tmpdir/hdl_top_icarus.sv"
if [ "$probe" = key_sign ]; then
  sed "s/\.cptra_pwrgood    (),/.cptra_pwrgood    (1'b1),/" \
    "$tmpdir/hdl_top_icarus.sv" > "$tmpdir/hdl_top_key_sign.sv"
  mv "$tmpdir/hdl_top_key_sign.sv" "$tmpdir/hdl_top_icarus.sv"
fi

for edition in 2017 2023; do
  if [ "$edition_filter" != both ] && [ "$edition_filter" != "$edition" ]; then
    continue
  fi
  compile_log="$tmpdir/compile-$edition.log"
  run_log_dir=${ECC_RESET_MONITOR_LOG_DIR:-"$tmpdir/logs"}
  mkdir -p "$run_log_dir"
  run_log_name=$(printf "%s_%s.log" "$log_prefix" "$edition")
  run_log="$run_log_dir/$run_log_name"
  image="$tmpdir/reset-monitor-$edition.vvp"
  if ! CALIPTRA_ROOT="$caliptra_root" \
       CALIPTRA_PRIM_ROOT="$caliptra_root/src/caliptra_prim_generic" \
       CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic \
       "$iverilog_bin" -uvm -g"$edition" -s ecc_generated_full_probe \
         -f "$ecc_root/config/ecc_top.vf" \
         -I"$in_pkg" -I"$out_pkg" -I"$env_pkg" \
         -I"$bench/parameters" -I"$bench/sequences" -I"$bench/tests" \
         -o "$image" \
         "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv" \
         "$repo_root/dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv" \
         "$in_pkg/ECC_in_pkg_hdl.sv" "$in_pkg/ECC_in_pkg.sv" \
         "$in_pkg/src/ECC_in_driver_bfm.sv" "$in_pkg/src/ECC_in_if.sv" \
         "$tmpdir/monitors/ECC_in_monitor_bfm.sv" \
         "$out_pkg/ECC_out_pkg_hdl.sv" "$out_pkg/ECC_out_pkg.sv" \
         "$out_pkg/src/ECC_out_driver_bfm.sv" "$out_pkg/src/ECC_out_if.sv" \
         "$tmpdir/monitors/ECC_out_monitor_bfm.sv" \
         "$env_pkg/ECC_env_pkg.sv" "$bench/parameters/ECC_parameters_pkg.sv" \
         "$bench/sequences/ECC_sequences_pkg.sv" "$bench/tests/ECC_tests_pkg.sv" \
         "$test_dir/tb_generated_ecc_reset_probe_pkg.sv" \
         "$caliptra_root/src/ecc/coverage/ecc_top_cov_bind.sv" \
         "$tmpdir/hdl_top_icarus.sv" "$bench/testbench/hvl_top.sv" \
         "$test_dir/tb_generated_ecc_full_probe.sv" > "$compile_log" 2>&1; then
    cat "$compile_log" >&2
    echo "Generated ECC reset-monitor probe did not compile under IEEE $edition." >&2
    exit 1
  fi

  if ! (cd "$tmpdir" && "$vvp_bin" "$image" "+UVM_TESTNAME=$test_name") > "$run_log" 2>&1; then
    cat "$run_log" >&2
    echo "Generated ECC $probe probe failed under IEEE $edition." >&2
    exit 1
  fi
  if ! grep -Fq "$pass_marker" "$run_log" \
    || ! grep -Fq 'UVM_ERROR :    0' "$run_log" \
    || ! grep -Fq 'UVM_FATAL :    0' "$run_log"; then
    cat "$run_log" >&2
    echo "Generated ECC $probe scoreboard did not pass under IEEE $edition." >&2
    exit 1
  fi
  grep -F "$pass_marker" "$run_log"
  grep -E 'UVM_ERROR :|UVM_FATAL :' "$run_log"
  echo "PASS: generated ECC $probe probe under IEEE $edition."
done
