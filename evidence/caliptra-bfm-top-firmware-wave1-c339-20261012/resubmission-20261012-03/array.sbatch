#!/usr/bin/env bash
#SBATCH --job-name=bfm-top-wave1
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=06:10:00
#SBATCH --array=8-51%6
#SBATCH --dependency=afterany:591:606,afterok:609
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-03/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-03/logs/%x-%A_%a.out

set -Eeuo pipefail

ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-03
QD="$ROOT/source/qd-bfm"
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
BUILT=/home/dsell/toolchains/iverilog-c339
IVERILOG_SRC="$BUILT/source/iverilog-uvm"
IVERILOG="$BUILT/iverilog/bin"
ENV="$BUILT/deps"
GCC_RUN=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1
GCC_DIR="$GCC_RUN/bin"
GCC="$GCC_DIR/riscv-none-elf-"
JTAG_VPI="$BUILT/firmware/jtagdpi/jtagdpi.vpi"
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0

TASK_ID=${SLURM_ARRAY_TASK_ID:?}
IFS=$'\t' read -r array_index test_id matrix_testname case_dir case_yaml yaml_testname expected_mcycle timeout_s selection_basis \
  < <(sed -n "$((TASK_ID + 2))p" "$ROOT/selection.tsv")
test "$array_index" = "$TASK_ID"
test -n "$test_id" && test -n "$case_dir" && test -n "$case_yaml"
case_file="$RTL/src/integration/test_suites/$case_yaml"
test -f "$case_file"
RUN="$ROOT/runs/${test_id}-${TASK_ID}"
mkdir -p "$RUN/pycache"
test ! -e "$RUN/output"
QD_SHA=$(cat "$ROOT/source/qd-bfm.commit")
RUNNER_SHA=$(cat "$ROOT/source/runner.sha256")
test "$(sha256sum "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" | cut -d' ' -f1)" = "$RUNNER_SHA"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp" && test -x "$IVERILOG/iverilog-vpi"
test -x "${GCC}gcc" && test -x "$ENV/bin/python3.12" && test -f "$JTAG_VPI"

printf 'host=%s\nqd_commit=%s\narray_task_id=%s\ntest_id=%s\nmatrix_testname=%s\ncase_dir=%s\ncase_yaml=%s\nyaml_testname=%s\nexpected_mcycle_estimate=%s\nper_test_timeout_s=%s\ntimeout_formula=min(21600,ceil(3*expected_mcycle/7.31+1800))\nselection_basis=%s\nIcarus_source=%s\nCaliptra=%s\nAdams_Bridge=%s\n' \
  "$(hostname)" "$QD_SHA" "$TASK_ID" "$test_id" "$matrix_testname" "$case_dir" \
  "$case_yaml" "$yaml_testname" "$expected_mcycle" "$timeout_s" "$selection_basis" \
  "$IVERILOG_SHA" "$RTL_SHA" "$ADAMS_SHA" | tee "$RUN/provenance.txt"
sha256sum "$IVERILOG/iverilog" "$IVERILOG/vvp" "$JTAG_VPI" | tee "$RUN/tool-binaries.sha256"
"$IVERILOG/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1
"$ENV/bin/python3.12" --version > "$RUN/python-version.txt" 2>&1
"${GCC}gcc" --version > "$RUN/riscv-gcc-version.txt" 2>&1

export PATH="$ENV/bin:$IVERILOG:$GCC_DIR:$PATH"
export LD_LIBRARY_PATH="/home/dsell/toolchains/iverilog-c339/iverilog/lib:$ENV/lib"
export CALIPTRA_MBEDTLS_ROOT="$ENV"
export CALIPTRA_RTL="$RTL"
export IVERILOG_BIN="$IVERILOG/iverilog"
export VVP_BIN="$IVERILOG/vvp"
export IVERILOG_SOURCE_ROOT="$IVERILOG_SRC"
export IVERILOG_VPI_BIN="$IVERILOG/iverilog-vpi"
export CALIPTRA_BFM_PROFILE="$RTL/src/integration/config/caliptra_top_tb.vf"
export CALIPTRA_GCC_PREFIX="$GCC"
export CALIPTRA_JTAGDPI_VPI="$JTAG_VPI"
export PYTHONPYCACHEPREFIX="$RUN/pycache"

python3.12 -m py_compile "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
set +e
/usr/bin/time -v -o "$RUN/resource.log" timeout --signal=TERM --kill-after=30s "$timeout_s" \
  python3.12 "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" \
  --case "$case_dir" --case-yaml "$case_yaml" --output "$RUN/output" > "$RUN/runner.log" 2>&1
runner_exit=$?
set -e

result="$RUN/output/$case_dir/result.json"
result_testname=
if [ "$runner_exit" -eq 124 ]; then
  outcome=TIMEOUT
  reason=per_test_timeout
elif [ "$runner_exit" -eq 137 ] || [ "$runner_exit" -eq 143 ]; then
  outcome=INFRA_ERROR
  reason=runner_terminated_by_signal
elif [ -f "$result" ]; then
  result_testname=$(python3.12 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("testname", ""))' "$result")
  if python3.12 - "$result" "$yaml_testname" <<'PY'
import json,sys
result=json.load(open(sys.argv[1]))
raise SystemExit(0 if result.get('passed') is True and result.get('testname') == sys.argv[2] else 1)
PY
  then
    outcome=PASS
    reason=terminal_result_passed
  else
    outcome=FAIL
    reason=terminal_result_failed_or_yaml_name_mismatch
  fi
else
  outcome=FAIL
  reason=no_result_json_runner_or_firmware_failure
fi
printf 'outcome=%s\nreason=%s\nrunner_exit=%s\nresult_testname=%s\n' \
  "$outcome" "$reason" "$runner_exit" "$result_testname" | tee "$RUN/status.txt"
grep 'Maximum resident set size' "$RUN/resource.log" || true
# Firmware verdicts are in status.txt; reserve scheduler failure for preflight or infrastructure errors.
exit 0
