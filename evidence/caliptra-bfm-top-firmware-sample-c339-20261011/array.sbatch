#!/bin/bash
#SBATCH --job-name=bfm-top-sample
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=03:00:00
#SBATCH --array=0-9%6
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m4-top-sample-c339-20261011-01/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m4-top-sample-c339-20261011-01/logs/%x-%A_%a.out

set -Eeuo pipefail

ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m4-top-sample-c339-20261011-01
QD="$ROOT/source/qd-bfm"
RTL=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-11/source/caliptra-rtl
BUILT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
IVERILOG_SRC="$BUILT/source/iverilog-uvm"
IVERILOG="$BUILT/toolchain/iverilog/bin"
ENV="$BUILT/deps"
GCC_RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-10
GCC="$GCC_RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-"
JTAG_VPI="$GCC_RUN/jtagdpi/jtagdpi.vpi"
QD_SHA=a8664c7a8092ac8342dce2f47a6efe9a8a3e9af8
RUNNER_SHA=37e8197f66be466a6345ae0f863e7af3826b5d1ced21b3499f5d9a36ee38807d
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0

TASK_ID=${SLURM_ARRAY_TASK_ID:?}
IFS=$'\t' read -r sample_order test_id case_name expected_mcycle timeout_s selection_basis \
  < <(sed -n "$((TASK_ID + 2))p" "$ROOT/selection.tsv")
test -n "$case_name"
RUN="$ROOT/runs/$case_name"
mkdir -p "$RUN/pycache" "$RUN/output"
test "$(sha256sum "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" | cut -d' ' -f1)" = "$RUNNER_SHA"

test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp" && test -x "$IVERILOG/iverilog-vpi"
test -x "${GCC}gcc" && test -x "$ENV/bin/python3.12" && test -f "$JTAG_VPI"

printf 'host=%s\nqd_commit=%s\narray_task_id=%s\nsample_order=%s\ntest_id=%s\ntestname=%s\nexpected_mcycle=%s\nper_test_timeout_s=%s\ntimeout_formula=ceil(3*expected_mcycle/7.31+1800)\nIcarus_source=%s\nCaliptra=%s\nAdams_Bridge=%s\n' \
  "$(hostname)" "$QD_SHA" "$TASK_ID" "$sample_order" "$test_id" "$case_name" \
  "$expected_mcycle" "$timeout_s" "$IVERILOG_SHA" "$RTL_SHA" "$ADAMS_SHA" \
  | tee "$RUN/provenance.txt"
sha256sum "$IVERILOG/iverilog" "$IVERILOG/vvp" "$JTAG_VPI" | tee "$RUN/tool-binaries.sha256"
"$IVERILOG/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1
"$ENV/bin/python3.12" --version > "$RUN/python-version.txt" 2>&1
"${GCC}gcc" --version > "$RUN/riscv-gcc-version.txt" 2>&1

export PATH="$ENV/bin:$IVERILOG:$GCC_RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin:$PATH"
export LD_LIBRARY_PATH="$BUILT/toolchain/iverilog/lib:$ENV/lib"
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
  --case "$case_name" --output "$RUN/output/$case_name" > "$RUN/runner.log" 2>&1
runner_exit=$?
set -e
printf 'runner_exit=%s\n' "$runner_exit" | tee "$RUN/runner-status.txt"

if [ "$runner_exit" -eq 124 ]; then
  outcome=TIMEOUT
elif [ -f "$RUN/output/$case_name/result.json" ]; then
  if python3.12 - "$RUN/output/$case_name/result.json" <<'PY'
import json,sys
raise SystemExit(0 if json.load(open(sys.argv[1]))['passed'] else 1)
PY
  then outcome=PASS; else outcome=FAIL; fi
else
  outcome=SETUP_BLOCKED
fi
printf 'sample_outcome=%s\n' "$outcome" | tee "$RUN/sample-outcome.txt"
grep 'Maximum resident set size' "$RUN/resource.log" || true
exit "$runner_exit"
