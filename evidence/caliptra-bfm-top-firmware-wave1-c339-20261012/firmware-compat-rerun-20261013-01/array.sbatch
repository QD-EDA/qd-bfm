#!/usr/bin/env bash
#SBATCH --job-name=bfm-fw-compat
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=06:10:00
#SBATCH --array=1-3%3
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/firmware-compat-rerun-20261013-01/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/firmware-compat-rerun-20261013-01/logs/%x-%A_%a.out

set -Eeuo pipefail

ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/firmware-compat-rerun-20261013-01
QD=/home/dsell/toolchains/qd-bfm-0b5efd3
BUILT=/home/dsell/toolchains/iverilog-c339
RTL=$BUILT/firmware/caliptra-rtl
IVERILOG_SRC=$BUILT/source/iverilog-uvm
IVERILOG=$BUILT/iverilog/bin
ENV=$BUILT/deps
GCC_DIR=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
GCC=$GCC_DIR/riscv-none-elf-
OPENSSL=$BUILT/openssl
JTAG_VPI=$BUILT/firmware/jtagdpi/jtagdpi.vpi
QD_SHA=0b5efd3fa67ee7e68d62914c403128ba8f400948
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0
RUNNER_SHA=d4a819ed4e2fb38461a181b57a921ff9a2a3185d7ddbbb85c462b1834466b3d4

TASK_ID=${SLURM_ARRAY_TASK_ID:?}
IFS=$'\t' read -r array_index source_row test_id matrix_testname case_dir case_yaml yaml_testname expected_mcycle timeout_s compat_overlay selection_basis \
  < <(sed -n "$((TASK_ID + 1))p" "$ROOT/selection.tsv")
test "$array_index" = "$TASK_ID"
test -n "$test_id" && test -n "$case_dir" && test -n "$case_yaml" && test -n "$compat_overlay"
test -f "$RTL/src/integration/test_suites/$case_yaml"
RUN=$ROOT/runs/${source_row}-${test_id}-${TASK_ID}
mkdir -p "$RUN/pycache"
test ! -e "$RUN/output"
QD_COMMIT=$(cat "$QD/qd-bfm.commit")
test "$QD_COMMIT" = "$QD_SHA"
(cd "$QD" && sha256sum -c firmware-compat-source-files.sha256 >/dev/null)
test "$(sha256sum "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" | awk '{print $1}')" = "$RUNNER_SHA"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp" && test -x "$IVERILOG/iverilog-vpi"
test -x "${GCC}gcc" && test -x "$ENV/bin/python3.12" && test -f "$JTAG_VPI"
test -x "$OPENSSL/bin/openssl" && test -f "$OPENSSL/lib/libcrypto.so" && test -f "$OPENSSL/include/openssl/evp.h"

RUNNER=$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py
printf 'host=%s\nqd_commit=%s\narray_index=%s\nsource_row=%s\ntest_id=%s\nmatrix_testname=%s\ncase_dir=%s\ncase_yaml=%s\nyaml_testname=%s\nexpected_mcycle_estimate=%s\nper_test_timeout_s=%s\ncompat_overlay=%s\nselection_basis=%s\nIcarus_source=%s\nCaliptra=%s\nAdams_Bridge=%s\nrunner_sha256=%s\n' \
  "$(hostname)" "$QD_COMMIT" "$TASK_ID" "$source_row" "$test_id" "$matrix_testname" "$case_dir" \
  "$case_yaml" "$yaml_testname" "$expected_mcycle" "$timeout_s" "$compat_overlay" "$selection_basis" \
  "$IVERILOG_SHA" "$RTL_SHA" "$ADAMS_SHA" "$RUNNER_SHA" | tee "$RUN/provenance.txt"
sha256sum "$ROOT/array.sbatch" "$IVERILOG/iverilog" "$IVERILOG/vvp" "$IVERILOG/iverilog-vpi" "$JTAG_VPI" | tee "$RUN/tool-binaries.sha256"
sha256sum "$OPENSSL/bin/openssl" "$OPENSSL/lib/libcrypto.so" | tee "$RUN/openssl-binaries.sha256"
"$IVERILOG/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1
"$IVERILOG/vvp" -V > "$RUN/vvp-version.txt" 2>&1
"$ENV/bin/python3.12" --version > "$RUN/python-version.txt" 2>&1
"${GCC}gcc" --version > "$RUN/riscv-gcc-version.txt" 2>&1

export PATH="$ENV/bin:$IVERILOG:$GCC_DIR:$OPENSSL/bin:$PATH"
export LD_LIBRARY_PATH="$BUILT/iverilog/lib:$ENV/lib:$OPENSSL/lib"
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

python3.12 -m py_compile "$RUNNER"
set +e
/usr/bin/time -v -o "$RUN/resource.log" timeout --signal=INT --kill-after=60s "$timeout_s" \
  python3.12 "$RUNNER" --case "$case_dir" --case-yaml "$case_yaml" --firmware-compat-overlay \
  --output "$RUN/output" > "$RUN/runner.log" 2>&1
runner_exit=$?
set -e

RESULT=$RUN/output/result.json
SIM_LOG=$RUN/output/$case_dir/sim.log
progress_count=0
last_progress=
last_mcycle=none
if [ -f "$SIM_LOG" ]; then
  progress_count=$(grep -c '^CALIPTRA_PROGRESS_HEARTBEAT ' "$SIM_LOG" || true)
  last_progress=$(grep '^CALIPTRA_PROGRESS_HEARTBEAT ' "$SIM_LOG" | tail -n 1 || true)
  last_mcycle=$(sed -n 's/.*mcycle=\([0-9][0-9]*\).*/\1/p' <<< "$last_progress")
  last_mcycle=${last_mcycle:-none}
fi
elapsed_text=$(awk -F': ' '/Elapsed \(wall clock\) time/ {print $NF; exit}' "$RUN/resource.log" || true)
elapsed_s=0
if [ -n "$elapsed_text" ]; then
  elapsed_s=$(python3.12 -c 'import sys; p=sys.argv[1].split(":"); print(round(float(p[-1]) + int(p[-2])*60 + (int(p[-3])*3600 if len(p)==3 else 0)))' "$elapsed_text")
fi
if [ "$runner_exit" -eq 124 ]; then
  outcome=TIMEOUT
  reason=per_test_timeout
elif [ "$runner_exit" -eq 137 ] && [ "$elapsed_s" -ge "$((timeout_s - 2))" ] && [ "$elapsed_s" -le "$((timeout_s + 120))" ]; then
  outcome=TIMEOUT
  reason=per_test_timeout_kill_after
elif [ "$runner_exit" -eq 130 ] || [ "$runner_exit" -eq 137 ] || [ "$runner_exit" -eq 143 ]; then
  outcome=INFRA_ERROR
  reason=runner_terminated_by_signal
elif [ -f "$RESULT" ] && python3.12 -c 'import json,sys; r=json.load(open(sys.argv[1])); sys.exit(0 if r.get("passed") is True and r.get("testname") == sys.argv[2] else 1)' "$RESULT" "$yaml_testname"; then
  outcome=PASS
  reason=terminal_result_passed
elif [ -f "$RESULT" ]; then
  outcome=FAIL
  reason=terminal_result_failed
elif grep -q 'firmware build failed' "$RUN/runner.log"; then
  outcome=FAIL
  reason=firmware_build_failed
else
  outcome=INFRA_ERROR
  reason=no_terminal_result_setup_or_top_compile_failure
fi
printf 'outcome=%s\nreason=%s\nrunner_exit=%s\nelapsed_s=%s\nprogress_heartbeat_count=%s\nlast_heartbeat=%s\nlast_mcycle=%s\nresult_testname=%s\n' \
  "$outcome" "$reason" "$runner_exit" "$elapsed_s" "$progress_count" "$last_progress" "$last_mcycle" \
  "$(python3.12 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("testname", ""))' "$RESULT" 2>/dev/null || true)" | tee "$RUN/status.txt"
grep 'Maximum resident set size' "$RUN/resource.log" || true
exit 0
