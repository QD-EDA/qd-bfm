#!/usr/bin/env bash
#SBATCH --job-name=a2-m13b-overlay-reruns
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=02:00:00
#SBATCH --array=0-2%3
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m13b-overlay-reruns-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13b-overlay-reruns-20261017-01/logs/slurm-%A_%a.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13b-overlay-reruns-20261017-01
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL_ROOT=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
IVL_SRC=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source
IVERILOG=$IVL_ROOT/bin/iverilog
VVP=$IVL_ROOT/bin/vvp

IFS=$'\t' read -r ENV_ID TOP SOURCE_REPO FILELIST < <(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$RUN/overlay-tasks.tsv")
case "$SOURCE_REPO" in
  caliptra_v2.1.2)
    ROOT="$RTL"
    EXTRA_INCLUDES=()
    ;;
  adams_bridge_v2.0.3)
    ROOT="$RTL/submodules/adams-bridge"
    EXTRA_INCLUDES=(-I "$ROOT/src/abr_prim/rtl" -I "$ROOT/src/abr_libs/rtl")
    ;;
  *) echo "unknown source repo: $SOURCE_REPO" >&2; exit 2 ;;
esac

TASK_DIR="$RUN/tasks/$ENV_ID"
mkdir -p "$TASK_DIR/runtime" "$TASK_DIR/overlay"
export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export ADAMSBRIDGE_ROOT="$RTL/submodules/adams-bridge"
export PATH="$IVL_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$IVL_ROOT/lib:$IVL_ROOT/lib64:/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

FILE="$ROOT/$FILELIST"
test -f "$FILE"
test -x "$IVERILOG" && test -x "$VVP"
test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = b77e3d899e828d626cfc2a0d26a6b5704cc121e0
test "$(git -C "$IVL_SRC" rev-parse HEAD)" = 9b5fad2afb4104caa816b257d5bccc40f01b8c66

TOP_FILE=$(find "$ROOT/src" -type f -path "*/tb/$TOP.sv" -print -quit)
test -n "$TOP_FILE"
SOURCE_CWD=$(dirname "$TOP_FILE")
cp -a "$SOURCE_CWD/." "$TASK_DIR/runtime/"
COMPILE_FILE="$FILE"
SIM_ARGS=()
if [[ "$TOP" == pkdecode_tb ]]; then
  PACKAGE="$ROOT/src/abr_top/rtl/abr_params_pkg.sv"
  OVERLAY_PACKAGE="$TASK_DIR/overlay/abr_params_pkg.sv"
  cp "$PACKAGE" "$OVERLAY_PACKAGE"
  python3 - "$OVERLAY_PACKAGE" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
pattern = re.compile(r"(?m)^(\s*parameter\s+ABR_MEM_ADDR_WIDTH\s*=[^;]+;[^\n]*)$")
match = pattern.search(text)
if len(pattern.findall(text)) != 1:
    raise SystemExit("expected one ABR_MEM_ADDR_WIDTH declaration")
text = text[:match.end()] + "\n  parameter MLDSA_MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH;" + text[match.end():]
path.write_text(text)
PY
  COMPILE_FILE="$TASK_DIR/overlay/pkdecode_tb_icarus.vf"
  python3 - "$FILE" "$COMPILE_FILE" "$OVERLAY_PACKAGE" <<'PY'
import sys
from pathlib import Path

source, output, package = map(Path, sys.argv[1:])
text = source.read_text()
anchor = "${ADAMSBRIDGE_ROOT}/src/abr_top/rtl/abr_params_pkg.sv"
if text.count(anchor) != 1:
    raise SystemExit("expected exactly one abr_params_pkg source in pkdecode filelist")
output.write_text(text.replace(anchor, str(package), 1))
PY
  diff -u "$ROOT/src/abr_top/rtl/abr_params_pkg.sv" "$OVERLAY_PACKAGE" > "$TASK_DIR/overlay/abr_params_pkg.patch" || [[ $? -eq 1 ]]
elif [[ "$TOP" == ecc_montgomerymultiplier_tb ]]; then
  VECTOR="$SOURCE_CWD/test_vectors/mm_test_vectors_5_key_16_word_4.hex"
  test -s "$VECTOR"
  cp "$VECTOR" "$TASK_DIR/runtime/mm_test_vectors_5_key_16_word_4.hex"
elif [[ "$TOP" == ecc_top_tb ]]; then
  VECTOR="$TASK_DIR/runtime/test_vectors/ecc_drbg_mbedtls.hex"
  test -s "$VECTOR"
  SIM_ARGS=("+ECC_TEST_VECTOR_FILE=$VECTOR")
fi

{
  printf 'environment_id=%s\ntop=%s\nsource_repo=%s\nfilelist=%s\n' "$ENV_ID" "$TOP" "$SOURCE_REPO" "$FILELIST"
  printf 'host=%s\nslurm_job_id=%s\narray_task_id=%s\nruntime_cwd=%s\n' "$(hostname)" "$SLURM_JOB_ID" "$SLURM_ARRAY_TASK_ID" "$TASK_DIR/runtime"
  printf 'iverilog_source=9b5fad2afb4104caa816b257d5bccc40f01b8c66\ncaliptra_rtl=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e\nadams_bridge=b77e3d899e828d626cfc2a0d26a6b5704cc121e0\n'
  if [[ "$TOP" == pkdecode_tb ]]; then printf 'overlay=MLDSA_MEM_ADDR_WIDTH alias to ABR_MEM_ADDR_WIDTH\n'; fi
  if [[ "$TOP" == ecc_montgomerymultiplier_tb ]]; then printf 'vectors=%s\n' "$VECTOR"; fi
  if [[ "$TOP" == ecc_top_tb ]]; then printf 'vectors=%s\n' "$VECTOR"; fi
} > "$TASK_DIR/source-revisions.txt"
sha256sum "$FILE" "$COMPILE_FILE" "$IVERILOG" "$VVP" > "$TASK_DIR/input-hashes.txt"
if [[ -n "${VECTOR:-}" ]]; then sha256sum "$VECTOR" > "$TASK_DIR/vector.sha256"; fi
sha256sum "$IVERILOG" "$VVP" > "$TASK_DIR/tool-binaries.sha256"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1

start=$(date +%s)
set +e
/usr/bin/time -v -o "$TASK_DIR/compile.resource" timeout --signal=TERM --kill-after=30s 6900s \
  "$IVERILOG" -g2017 -gassertions -s "$TOP" "${EXTRA_INCLUDES[@]}" \
  -f "$COMPILE_FILE" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
compile_rc=$?
sim_rc=NOT_RUN
if [[ $compile_rc == 0 ]]; then
  elapsed_before_sim=$(( $(date +%s) - start ))
  remaining=$((6900 - elapsed_before_sim))
  if ((remaining > 0)); then
    cd "$TASK_DIR/runtime"
    /usr/bin/time -v -o "$TASK_DIR/sim.resource" timeout --signal=TERM --kill-after=30s "${remaining}s" \
      "$VVP" -n "$TASK_DIR/$TOP.vvp" "${SIM_ARGS[@]}" > "$TASK_DIR/sim.log" 2>&1
    sim_rc=$?
  else
    sim_rc=124
  fi
fi

pass_markers=$(grep -Fc '* TESTCASE PASSED' "$TASK_DIR/sim.log" 2>/dev/null || true)
fail_markers=$(grep -Ec '(\* TESTCASE FAILED|\*\*\* ERROR)' "$TASK_DIR/sim.log" 2>/dev/null || true)
mismatches=$(grep -Fc 'Error: Output mismatch at index' "$TASK_DIR/sim.log" 2>/dev/null || true)
completed=$(grep -Fc 'Test completed' "$TASK_DIR/sim.log" 2>/dev/null || true)
vector_summary=$(grep -E 'Read [0-9]+ test vectors' "$TASK_DIR/sim.log" 2>/dev/null | tr '\n' ';' || true)
if [[ $compile_rc == 124 || $sim_rc == 124 ]]; then result=TIMEOUT
elif [[ $compile_rc != 0 ]]; then result=BLOCKED_COMPILE
elif [[ "$TOP" == pkdecode_tb ]]; then
  if [[ $sim_rc == 0 && $completed == 2 && $mismatches == 0 ]]; then result=PASS; else result=FAIL; fi
elif [[ "$TOP" == ecc_montgomerymultiplier_tb ]]; then
  if [[ "$vector_summary" != *'Read 5 test vectors'* ]]; then result=BLOCKED_VECTOR
  elif [[ $sim_rc == 0 && $pass_markers == 1 && $fail_markers == 0 ]]; then result=PASS
  else result=FAIL; fi
else
  if [[ "$vector_summary" != *'Read 10 test vectors'* ]]; then result=BLOCKED_VECTOR
  elif [[ $sim_rc == 0 && $pass_markers == 1 && $fail_markers == 0 ]]; then result=PASS
  else result=FAIL; fi
fi
runner_rc=0
[[ $result == PASS ]] || runner_rc=1
end=$(date +%s)
printf 'result=%s\nenvironment_id=%s\ntop=%s\nrunner_exit=%s\ncompile_exit=%s\nsim_exit=%s\npass_markers=%s\nfailure_markers=%s\nmismatches=%s\ncompleted_sections=%s\nvector_summary=%s\nelapsed_seconds=%s\n' \
  "$result" "$ENV_ID" "$TOP" "$runner_rc" "$compile_rc" "$sim_rc" "$pass_markers" "$fail_markers" "$mismatches" "$completed" "$vector_summary" "$((end-start))" \
  > "$TASK_DIR/result.txt"
cat "$TASK_DIR/result.txt"
exit "$runner_rc"
