#!/usr/bin/env bash
#SBATCH --job-name=a2-c339-quoted-axi
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=03:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-08
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-08/logs/%x-%A_%a.out

set -Eeuo pipefail
ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-08
BASE=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-06
QD=$ROOT/source
BUILT=/home/dsell/toolchains/iverilog-c339
RTL=$BUILT/firmware/caliptra-rtl
IVERILOG_SRC=$BUILT/source/iverilog-uvm
IVERILOG=$BUILT/iverilog/bin
ENV=$BUILT/deps
GCC_DIR=$BUILT/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
GCC=$GCC_DIR/riscv-none-elf-
OPENSSL=$BUILT/openssl
JTAG_VPI=$BUILT/firmware/jtagdpi/jtagdpi.vpi
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0
QD_COMMIT=d0d728d7a4aea66ce1962a418d6403d017b72157
RUNNER_SHA=22420e3a99b181ec730b45bd388febde22f401478b85c85bbd84cff2d6f35584

TASK_ID=${SLURM_ARRAY_TASK_ID:?}
IFS=$'\t' read -r task_index source_row test_id matrix_testname case_dir case_yaml yaml_testname expected_mcycle timeout_s selection_basis \
  < <(sed -n "$((TASK_ID + 1))p" "$ROOT/selection.tsv")
test "$task_index" = "$TASK_ID"
test -f "$RTL/src/integration/test_suites/$case_yaml"
RUN=$ROOT/runs/${source_row}-${test_id}-${TASK_ID}
mkdir -p "$RUN/pycache"
test ! -e "$RUN/output"
test "$(cat "$BASE/source.commit")" = "$QD_COMMIT"
test "$(sha256sum "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" | cut -d' ' -f1)" = "$RUNNER_SHA"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_SHA"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp" && test -x "$IVERILOG/iverilog-vpi"
test -x "${GCC}gcc" && test -x "$ENV/bin/python3.12" && test -f "$JTAG_VPI"
test -x "$OPENSSL/bin/openssl" && test -f "$OPENSSL/lib/libcrypto.so" && test -f "$OPENSSL/include/openssl/evp.h"
RUNNER=$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py
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
printf 'host=%s\nsource_commit=%s\nrunner_sha256=%s\nrunner_overlay=dd6d43d\nsource_row=%s\ntest_id=%s\ncase=%s\ncase_yaml=%s\nexpected_mcycle=%s\ntimeout_s=%s\nselection_basis=%s\niverilog_source=%s\ncaliptra=%s\nadams_bridge=%s\n' \
  "$(hostname)" "$QD_COMMIT" "$RUNNER_SHA" "$source_row" "$test_id" "$case_dir" "$case_yaml" "$expected_mcycle" "$timeout_s" "$selection_basis" "$IVERILOG_SHA" "$RTL_SHA" "$ADAMS_SHA" | tee "$RUN/provenance.txt"
sha256sum "$IVERILOG/iverilog" "$IVERILOG/vvp" "$IVERILOG/iverilog-vpi" "$JTAG_VPI" | tee "$RUN/tool-binaries.sha256"
"$IVERILOG/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1
"$IVERILOG/vvp" -V > "$RUN/vvp-version.txt" 2>&1
"$ENV/bin/python3.12" --version > "$RUN/python-version.txt" 2>&1
"${GCC}gcc" --version > "$RUN/riscv-gcc-version.txt" 2>&1
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
