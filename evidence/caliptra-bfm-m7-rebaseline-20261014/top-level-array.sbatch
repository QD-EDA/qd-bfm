#!/usr/bin/env bash
#SBATCH --job-name=bfm-m7-top-main
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=06:10:00
#SBATCH --array=1-16%6
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-top-main-3335fe7-20261014/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-top-main-3335fe7-20261014/logs/%x-%A_%a.out

set -Eeuo pipefail

ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-top-main-3335fe7-20261014
QD=/home/dsell/toolchains/qd-bfm-d1529c922da402943148a0fb22648f347e30eed9
C339=/home/dsell/toolchains/iverilog-c339
RTL=$C339/firmware/caliptra-rtl
ENV=$C339/deps
OPENSSL=$C339/openssl
GCC_DIR=$C339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
GCC=$GCC_DIR/riscv-none-elf-
IVERILOG_ROOT=/home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf
IVERILOG_SRC=$IVERILOG_ROOT/source
IVERILOG=$IVERILOG_ROOT/install/bin
JTAG_VPI=$IVERILOG_ROOT/caliptra-jtagdpi/jtagdpi.vpi
IVERILOG_SHA=3335fe7ec1495956c8adc5788e9a53b0f1756ecf
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0

TASK_ID=${SLURM_ARRAY_TASK_ID:?}
IFS=$'\t' read -r m7_index source_row original_799_task test_id matrix_testname case_dir case_yaml yaml_testname \
  expected_mcycle timeout_s selection_basis c339_outcome c339_elapsed_s c339_cycles_per_s \
  c339_last_heartbeat_mcycle c339_mcycle_source \
  < <(sed -n "$((TASK_ID + 1))p" "$ROOT/selection.tsv")
test "$m7_index" = "$TASK_ID"
test -n "$test_id" && test -n "$case_dir" && test -n "$case_yaml"
test -f "$RTL/src/integration/test_suites/$case_yaml"
RUN=$ROOT/runs/${source_row}-${test_id}-${TASK_ID}
mkdir -p "$RUN/pycache"
test ! -e "$RUN/output"
QD_SHA=$(cat "$QD/qd-bfm.commit")
test "$QD_SHA" = d1529c922da402943148a0fb22648f347e30eed9
(cd "$QD" && sha256sum -c m7-source-files.sha256 >/dev/null)
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp" && test -x "$IVERILOG/iverilog-vpi"
test -x "${GCC}gcc" && test -x "$ENV/bin/python3.12" && test -f "$JTAG_VPI"
test -x "$OPENSSL/bin/openssl" && test -f "$OPENSSL/lib/libcrypto.so" && test -f "$OPENSSL/include/openssl/evp.h"

RUNNER=$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py
RUNNER_SHA=$(sha256sum "$RUNNER" | awk '{print $1}')
printf 'host=%s\nqd_commit=%s\nm7_index=%s\noriginal_799_task=%s\nsource_row=%s\ntest_id=%s\nmatrix_testname=%s\ncase_dir=%s\ncase_yaml=%s\nyaml_testname=%s\nc339_mcycle=%s\nc339_mcycle_source=%s\nc339_last_heartbeat_mcycle=%s\nper_test_timeout_s=%s\nselection_basis=%s\nc339_outcome=%s\nc339_elapsed_s=%s\nc339_cycles_per_s=%s\nIcarus_source=%s\nCaliptra=%s\nAdams_Bridge=%s\nrunner_sha256=%s\n' \
  "$(hostname)" "$QD_SHA" "$TASK_ID" "$original_799_task" "$source_row" "$test_id" "$matrix_testname" "$case_dir" \
  "$case_yaml" "$yaml_testname" "$expected_mcycle" "$c339_mcycle_source" "$c339_last_heartbeat_mcycle" "$timeout_s" "$selection_basis" \
  "$c339_outcome" "$c339_elapsed_s" "$c339_cycles_per_s" \
  "$IVERILOG_SHA" "$RTL_SHA" "$ADAMS_SHA" "$RUNNER_SHA" | tee "$RUN/provenance.txt"
sha256sum "$IVERILOG/iverilog" "$IVERILOG/vvp" "$IVERILOG/iverilog-vpi" "$JTAG_VPI" | tee "$RUN/tool-binaries.sha256"
sha256sum "$OPENSSL/bin/openssl" "$OPENSSL/lib/libcrypto.so" | tee "$RUN/openssl-binaries.sha256"
"$IVERILOG/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1
"$IVERILOG/vvp" -V > "$RUN/vvp-version.txt" 2>&1
"$ENV/bin/python3.12" --version > "$RUN/python-version.txt" 2>&1
"${GCC}gcc" --version > "$RUN/riscv-gcc-version.txt" 2>&1

export PATH="$ENV/bin:$IVERILOG:$GCC_DIR:$OPENSSL/bin:$PATH"
export LD_LIBRARY_PATH="$IVERILOG_ROOT/install/lib:$ENV/lib:$OPENSSL/lib"
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
  python3.12 "$RUNNER" --case "$case_dir" --case-yaml "$case_yaml" --output "$RUN/output" > "$RUN/runner.log" 2>&1
runner_exit=$?
set -e

RESULT=$RUN/output/result.json
SIM_LOG=$RUN/output/$case_dir/sim.log
progress_count=0
last_progress=
if [ -f "$SIM_LOG" ]; then
  progress_count=$(grep -c '^CALIPTRA_PROGRESS_HEARTBEAT ' "$SIM_LOG" || true)
  last_progress=$(grep '^CALIPTRA_PROGRESS_HEARTBEAT ' "$SIM_LOG" | tail -n 1 || true)
fi
if [ "$runner_exit" -eq 124 ]; then
  outcome=TIMEOUT
  reason=per_test_timeout
elif [ "$runner_exit" -eq 130 ] || [ "$runner_exit" -eq 137 ] || [ "$runner_exit" -eq 143 ]; then
  outcome=INFRA_ERROR
  reason=runner_terminated_by_signal
elif [ -f "$RESULT" ] && python3.12 -c 'import json,sys; r=json.load(open(sys.argv[1])); sys.exit(0 if r.get("passed") is True and r.get("testname") == sys.argv[2] else 1)' "$RESULT" "$yaml_testname"; then
  outcome=PASS
  reason=terminal_result_passed
elif [ -f "$RESULT" ]; then
  outcome=FAIL
  reason=terminal_result_failed_or_yaml_name_mismatch
else
  outcome=FAIL
  reason=no_result_json_runner_or_firmware_failure
fi
printf 'outcome=%s\nreason=%s\nrunner_exit=%s\nprogress_heartbeat_count=%s\nlast_heartbeat=%s\nresult_testname=%s\n' \
  "$outcome" "$reason" "$runner_exit" "$progress_count" "$last_progress" \
  "$(python3.12 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("testname", ""))' "$RESULT" 2>/dev/null || true)" | tee "$RUN/status.txt"
grep 'Maximum resident set size' "$RUN/resource.log" || true
exit 0
