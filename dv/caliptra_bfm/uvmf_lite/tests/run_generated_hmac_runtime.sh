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
hmac_testname=${CALIPTRA_BFM_HMAC_TESTNAME:-HMAC_random_test}
case "$hmac_testname" in
  HMAC_random_test|HMAC_otf_reset_test) ;;
  *) echo "Unsupported generated HMAC test: $hmac_testname" >&2; exit 2 ;;
esac
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

if [ -n "${CALIPTRA_BFM_HMAC_RUN_DIR:-}" ]; then
  tmpdir=$CALIPTRA_BFM_HMAC_RUN_DIR
  mkdir -p "$tmpdir"
else
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM
fi
python3 - "$repo_root" "$caliptra_root" "$tmpdir" "$expected_test_gen_sha" <<'PY'
import hashlib
import json
import shutil
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
overlay = tmp / "compat-overlay"
overlay_out_pkg = overlay / "HMAC_out_pkg"
overlay_env_pkg = overlay / "HMAC_env_pkg"

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

compatibility = [
    (
        out_pkg / "src/HMAC_out_transaction_coverage.svh",
        "b54c5d26a1f97eb4fbd9c3648c1a46b971c3b2cbdd8e5f5a9bb1d77b5c2ebbb0",
        "result: coverpoint coverage_trans.result;",
        "result: coverpoint 1'b0;",
    ),
    (
        env_pkg / "src/HMAC_env_configuration.svh",
        "99de7feaf5d50dd77354111b16eafb063343ae6c7e005066654e38ae90858e1d",
        "HMAC_in_agent_config.convert2string,\n     \"\\n\", HMAC_out_agent_config.convert2string",
        "HMAC_in_agent_config.convert2string(),\n     \"\\n\", HMAC_out_agent_config.convert2string()",
    ),
    (
        env_pkg / "src/HMAC_env_sequence_base.svh",
        "8addb7a926397c55e0c1784120cf2c301a61809d90b4352d8c8227676ca8feeb",
        """  virtual task body();

    if ( configuration.HMAC_in_agent_config.sequencer != null )
       repeat (10) HMAC_in_agent_rand_seq.start(configuration.HMAC_in_agent_config.sequencer);


  endtask""",
        """  virtual task body();
    HMAC_env_configuration hmac_env_config;
    HMAC_in_configuration hmac_in_config;
    hmac_env_config = configuration;
    hmac_in_config = hmac_env_config.HMAC_in_agent_config;
    if (hmac_in_config.sequencer != null)
      repeat (10) HMAC_in_agent_rand_seq.start(hmac_in_config.sequencer);
  endtask""",
    ),
]
shutil.copytree(out_pkg, overlay_out_pkg)
shutil.copytree(env_pkg, overlay_env_pkg)
overlay_records = []
for source, expected, old_text, new_text in compatibility:
    original = source.read_bytes()
    actual = hashlib.sha256(original).hexdigest()
    if actual != expected:
        raise SystemExit(f"Refusing unreviewed HMAC source {source}: {actual}")
    if original.decode().count(old_text) != 1:
        raise SystemExit(f"HMAC source anchor changed: {source}")
    relative = source.relative_to(source.parents[1])
    target = (overlay_out_pkg if source.is_relative_to(out_pkg) else overlay_env_pkg) / relative
    target.write_text(original.decode().replace(old_text, new_text, 1))
    overlay_records.append({
        "source": str(source), "source_sha256": actual,
        "overlay": str(target), "overlay_sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
        "change": "Icarus-only testbench compatibility; no RTL, firmware, or pass criteria changed.",
    })
(tmp / "compat-overlay-manifest.json").write_text(json.dumps(overlay_records, indent=2) + "\n")

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
    f"+incdir+{overlay_out_pkg}", f"+incdir+{overlay_out_pkg / 'src'}",
    f"+incdir+{overlay_env_pkg}", f"+incdir+{bench / 'parameters'}",
    f"+incdir+{bench / 'sequences'}", f"+incdir+{bench / 'tests'}",
    f"+incdir+{bench / 'testbench'}",
]
generated_sources = [
    repo / "dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg_hdl.sv",
    repo / "dv/caliptra_bfm/uvmf_lite/uvmf_base_pkg.sv",
    in_pkg / "HMAC_in_pkg_hdl.sv", in_pkg / "HMAC_in_pkg.sv",
    in_pkg / "src/HMAC_in_driver_bfm.sv", in_pkg / "src/HMAC_in_if.sv",
    in_pkg / "src/HMAC_in_monitor_bfm.sv",
    overlay_out_pkg / "HMAC_out_pkg_hdl.sv", overlay_out_pkg / "HMAC_out_pkg.sv",
    overlay_out_pkg / "src/HMAC_out_driver_bfm.sv", overlay_out_pkg / "src/HMAC_out_if.sv",
    out_pkg / "src/HMAC_out_monitor_bfm.sv",
    overlay_env_pkg / "HMAC_env_pkg.sv", bench / "parameters/HMAC_parameters_pkg.sv",
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
  --output-dir "$tmpdir/monitor-overlay" \
  --manifest "$tmpdir/monitor-overlay-manifest.json"

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
      "$vvp_bin" "$image" "+UVM_TESTNAME=$hmac_testname" \
      "+ntb_random_seed=${CALIPTRA_BFM_HMAC_SEED:-1}" \
      +UVM_VERBOSITY=UVM_NONE +UVM_NO_RELNOTES) >"$run_log" 2>&1; then
  cat "$run_log" >&2
  echo "Generated HMAC runtime failed." >&2
  exit 1
fi

if ! grep -Fq '* TESTCASE PASSED' "$run_log" ||
   ! grep -Fq 'UVM_ERROR :    0' "$run_log" ||
   ! grep -Fq 'UVM_FATAL :    0' "$run_log" ||
   grep -Eq 'UVMF_SB_(MISMATCH|LEFTOVER)|\* TESTCASE FAILED' "$run_log" ||
   { [ "$hmac_testname" = HMAC_random_test ] &&
     { [ "$(grep -Fc '**HMAC_predictor** t.op=' "$run_log" || true)" -ne 17 ] ||
       ! grep -Fq 'UVM_WARNING :    0' "$run_log"; }; }; then
  cat "$run_log" >&2
  echo "Generated HMAC test $hmac_testname did not satisfy its pass checks." >&2
  exit 1
fi

simulator_id=$("$iverilog_bin" -V 2>&1 | sed -n '1p')
printf '%s\n' "$simulator_id"
case "$simulator_id" in
  *-dirty*) echo "DIAGNOSTIC: dirty Icarus build; this run is not qualification evidence." ;;
  *) echo "Check that this Icarus revision is clean and published before treating this as qualification evidence." ;;
esac
if [ "$hmac_testname" = HMAC_random_test ]; then
  echo "HMAC predictor transactions: 17; scoreboard mismatches/leftovers: 0"
fi
grep -E 'UVM_WARNING :|UVM_ERROR :|UVM_FATAL :' "$run_log"
echo "PASS: generated HMAC test $hmac_testname completed with zero UVM errors/fatals."
