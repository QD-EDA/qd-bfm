#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

if [ -z "${CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS:-}" ]; then
  CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=900
  export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS
fi
repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../../" && pwd)
. "$repo_root/scripts/caliptra_bfm_memory_guard.sh"
test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
caliptra_root=${CALIPTRA_ROOT:-"$repo_root/../caliptra-rtl"}
iverilog_bin=${IVERILOG_BIN:-iverilog}
vvp_bin=${VVP_BIN:-vvp}
expected_caliptra_commit=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
expected_test_gen_sha=ea91ed5f5b481e69c8840e3b4f3ac8bfeed37ab0552d070f9ddf7e0d3501399b

if [ "$(git -C "$caliptra_root" rev-parse HEAD)" != "$expected_caliptra_commit" ]; then
  echo "Caliptra checkout is not the pinned v2.1.2 commit $expected_caliptra_commit" >&2
  exit 2
fi
if [ -n "$(git -C "$caliptra_root" status --porcelain --untracked-files=normal)" ]; then
  echo "Caliptra checkout must be clean; this runner never modifies it." >&2
  exit 2
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM
python3 - "$repo_root" "$caliptra_root" "$tmpdir" "$expected_test_gen_sha" <<'PY'
import hashlib
import sys
from pathlib import Path

repo = Path(sys.argv[1])
caliptra = Path(sys.argv[2])
tmp = Path(sys.argv[3])
expected_sha = sys.argv[4]
hmac_root = caliptra / "src/hmac"
uvmf = hmac_root / "uvmf_2022/uvmf_template_output"
bench = uvmf / "project_benches/HMAC/tb"
in_pkg = uvmf / "verification_ip/interface_packages/HMAC_in_pkg"
out_pkg = uvmf / "verification_ip/interface_packages/HMAC_out_pkg"
env_pkg = uvmf / "verification_ip/environment_packages/HMAC_env_pkg"

test_gen = hmac_root / "tb/test_gen.py"
source = test_gen.read_bytes()
actual_sha = hashlib.sha256(source).hexdigest()
if actual_sha != expected_sha:
    raise SystemExit(f"Refusing unreviewed test_gen.py source: {actual_sha}")
old = """    tag = subprocess.check_output(command, shell=True)
    tag_str = str(tag)

    #Chomp extra chars at beginning and end if python 3.6.8 is loaded
    if tag_str[1] == "'":
        tag_str = tag_str[11:-3]
    else:
        tag_str = tag_str.rstrip()
        tag_str = tag_str[9:]"""
new = """    tag = subprocess.check_output(command, shell=True)
    tag_str = tag.decode("ascii").strip().rsplit("=", 1)[-1].strip()"""
text = source.decode()
if text.count(old) != 2:
    raise SystemExit("test_gen.py parser differs from the reviewed source")
(tmp / "test_gen.py").write_text(text.replace(old, new))

hdl = bench / "testbench/hdl_top.sv"
(tmp / "hdl_top_timescale_overlay.sv").write_text(
    "`timescale 1ns/1ps\n" + hdl.read_text()
)
(tmp / "hmac_generated_top.sv").write_text(
    "module hmac_generated_top;\n  hdl_top hdl();\n  hvl_top hvl();\nendmodule\n"
)

vf = (hmac_root / "config/hmac_ctrl_tb.vf").read_text()
for key, value in {
    "${CALIPTRA_ROOT}": str(caliptra),
    "${CALIPTRA_PRIM_ROOT}": str(caliptra / "src/caliptra_prim_generic"),
    "${CALIPTRA_PRIM_MODULE_PREFIX}": "caliptra_prim_generic",
}.items():
    vf = vf.replace(key, value)
if "${" in vf:
    raise SystemExit("unexpanded variable remains in hmac_ctrl_tb.vf")
incdirs = [line for line in vf.splitlines() if line.startswith("+incdir+")]
rtl_sources = [line for line in vf.splitlines() if line and not line.startswith("+incdir+")]
incdirs += [
    f"+incdir+{repo / 'dv/caliptra_bfm/uvmf_lite'}",
    f"+incdir+{in_pkg}", f"+incdir+{in_pkg / 'src'}",
    f"+incdir+{out_pkg}", f"+incdir+{out_pkg / 'src'}",
    f"+incdir+{env_pkg}", f"+incdir+{bench / 'parameters'}",
    f"+incdir+{bench / 'sequences'}", f"+incdir+{bench / 'tests'}",
    f"+incdir+{bench / 'testbench'}",
]
generated_sources = [
    repo / "dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv",
    repo / "dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv",
    in_pkg / "HMAC_in_pkg_hdl.sv", in_pkg / "HMAC_in_pkg.sv",
    in_pkg / "src/HMAC_in_driver_bfm.sv", in_pkg / "src/HMAC_in_if.sv",
    in_pkg / "src/HMAC_in_monitor_bfm.sv",
    out_pkg / "HMAC_out_pkg_hdl.sv", out_pkg / "HMAC_out_pkg.sv",
    out_pkg / "src/HMAC_out_driver_bfm.sv", out_pkg / "src/HMAC_out_if.sv",
    out_pkg / "src/HMAC_out_monitor_bfm.sv",
    env_pkg / "HMAC_env_pkg.sv", bench / "parameters/HMAC_parameters_pkg.sv",
    bench / "sequences/HMAC_sequences_pkg.sv", bench / "tests/HMAC_tests_pkg.sv",
    tmp / "hdl_top_timescale_overlay.sv", bench / "testbench/hvl_top.sv",
    tmp / "hmac_generated_top.sv",
]
(tmp / "hmac_generated_full.f").write_text(
    "\n".join(incdirs + rtl_sources + [str(path) for path in generated_sources]) + "\n"
)
PY

python3 "$repo_root/docs/conformance/release_overlays/caliptra/hmac_out_monitor_reset_event_overlay.py" \
  --caliptra-root "$caliptra_root" \
  --filelist "$tmpdir/hmac_generated_full.f" \
  --output-dir "$tmpdir/monitor-overlay"

image="$tmpdir/hmac-generated.vvp"
compile_log="$tmpdir/compile.log"
if ! "$iverilog_bin" -uvm -g2017 -s hmac_generated_top \
     -f "$tmpdir/monitor-overlay/hmac_generated_overlay.f" \
     -o "$image" >"$compile_log" 2>&1; then
  cat "$compile_log" >&2
  echo "Generated HMAC runtime did not compile." >&2
  exit 1
fi

mkdir -p "$tmpdir/run/bin"
ln -s "$(command -v python3)" "$tmpdir/run/bin/python"
cp "$tmpdir/test_gen.py" "$tmpdir/run/test_gen.py"
run_log="$tmpdir/run.log"
if ! (cd "$tmpdir/run" && PATH="$tmpdir/run/bin:$PATH" \
      "$vvp_bin" "$image" +UVM_TESTNAME=HMAC_random_test \
      +UVM_VERBOSITY=UVM_NONE +UVM_NO_RELNOTES) >"$run_log" 2>&1; then
  cat "$run_log" >&2
  echo "Generated HMAC runtime failed." >&2
  exit 1
fi

if [ "$(grep -Fc '**HMAC_predictor** t.op=' "$run_log" || true)" -ne 17 ] ||
   ! grep -Fq '* TESTCASE PASSED' "$run_log" ||
   ! grep -Fq 'UVM_WARNING :    0' "$run_log" ||
   ! grep -Fq 'UVM_ERROR :    0' "$run_log" ||
   ! grep -Fq 'UVM_FATAL :    0' "$run_log" ||
   grep -Eq 'UVMF_SB_(MISMATCH|LEFTOVER)' "$run_log"; then
  cat "$run_log" >&2
  echo "Generated HMAC scoreboard did not pass all 17 transactions." >&2
  exit 1
fi

simulator_id=$("$iverilog_bin" -V 2>&1 | sed -n '1p')
printf '%s\n' "$simulator_id"
case "$simulator_id" in
  *-dirty*) echo "DIAGNOSTIC: dirty Icarus build; this run is not qualification evidence." ;;
  *) echo "Check that this Icarus revision is clean and published before treating this as qualification evidence." ;;
esac
echo "HMAC predictor transactions: 17; scoreboard mismatches/leftovers: 0"
grep -E 'UVM_WARNING :|UVM_ERROR :|UVM_FATAL :' "$run_log"
echo "PASS: generated HMAC runtime matched 17 transactions."
