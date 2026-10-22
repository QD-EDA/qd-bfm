#!/usr/bin/env bash
#SBATCH --job-name=m21-row14-rerun
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=06:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-part-b-20261020-01/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-part-b-20261020-01/logs/%x-%j.out

set -Eeuo pipefail

ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-part-b-20261020-01
QD=$ROOT/source/qd-bfm
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
OLD=/home/dsell/toolchains/iverilog-c339
MAIN_ROOT=/home/dsell/toolchains/iverilog-uvm-main-cc25756d187314742d347267c2a513b3e640a7fb
IVERILOG=$MAIN_ROOT/bin
IVERILOG_SRC=/home/dsell/slurm-runs/caliptra-bfm/a2/m21-iverilog-main-cc25756d-20261020-01/source/iverilog-uvm
ENV=$OLD/deps
GCC_RUN=$OLD/firmware/xpack-riscv-none-elf-gcc-15.2.0-1
GCC_DIR=$GCC_RUN/bin
GCC=$GCC_DIR/riscv-none-elf-
OPENSSL=$OLD/openssl
JTAG_VPI=$OLD/firmware/jtagdpi/jtagdpi.vpi
IVERILOG_SHA=cc25756d187314742d347267c2a513b3e640a7fb
IVERILOG_BIN_SHA=87bb417df23d260bcfde3fb372b4a80eaad69e4fd2eea1ffb8b0eff10f7af08e
VVP_BIN_SHA=dfc193c466a70a0917a16ab4198a111de616657d6004de79456db2a4b603b437
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0
PYTHON=$ENV/bin/python3.12

TASK_ID=14
IFS=$'\t' read -r array_index m11_index test_id matrix_testname case_dir case_yaml yaml_testname verilator_outcome expected_mcycle timeout_s selection_basis \
  < <(sed -n "$((TASK_ID + 2))p" "$ROOT/retry-14/selection.tsv")
test "$array_index" = "$TASK_ID"
test "$matrix_testname" = "$yaml_testname"
test "$case_dir" = "${case_yaml%%/*}"
test -n "$test_id" && test -n "$case_dir" && test -n "$case_yaml"
case_file=$RTL/src/integration/test_suites/$case_yaml
test -f "$case_file"

RUN=$ROOT/retry-14-attempt02/run-$test_id-job$SLURM_JOB_ID
test ! -e "$RUN"
mkdir -p "$RUN/pycache"
sed -n "$((TASK_ID + 2))p" "$ROOT/retry-14/selection.tsv" > "$RUN/selection.tsv"
QD_SHA=$(cat "$ROOT/source/qd-bfm.commit")
RUNNER=$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py
RUNNER_SHA=$(cat "$ROOT/source/runner.sha256")
test "$(sha256sum "$RUNNER" | cut -d' ' -f1)" = "$RUNNER_SHA"
test -x "$IVERILOG/iverilog" && test -x "$IVERILOG/vvp" && test -x "$IVERILOG/iverilog-vpi"
test "$(sha256sum "$IVERILOG/iverilog" | cut -d' ' -f1)" = "$IVERILOG_BIN_SHA"
test "$(sha256sum "$IVERILOG/vvp" | cut -d' ' -f1)" = "$VVP_BIN_SHA"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -z "$(git -C "$RTL/submodules/adams-bridge" status --porcelain --untracked-files=all)"
test -x "$PYTHON" && test -x "${GCC}gcc" && test -x "$OPENSSL/bin/openssl" && test -f "$JTAG_VPI"
test -f "$RTL/src/integration/config/caliptra_top_tb.vf"

printf 'host=%s\narray_job_id=%s\narray_task_id=%s\nm11_index=%s\ntest_id=%s\ncase_dir=%s\ncase_yaml=%s\nyaml_testname=%s\nverilator_outcome=%s\nverilator_mcycle=%s\nper_test_timeout_s=%s\nselection_basis=%s\nqd_commit=%s\nrunner_sha256=%s\nIcarus_source=%s\niverilog_sha256=%s\nvvp_sha256=%s\nCaliptra=%s\nAdams_Bridge=%s\n' \
  "$(hostname)" "${SLURM_ARRAY_JOB_ID:-$SLURM_JOB_ID}" "$TASK_ID" "$m11_index" "$test_id" "$case_dir" \
  "$case_yaml" "$yaml_testname" "$verilator_outcome" "$expected_mcycle" "$timeout_s" \
  "$selection_basis" "$QD_SHA" "$RUNNER_SHA" "$IVERILOG_SHA" "$IVERILOG_BIN_SHA" \
  "$VVP_BIN_SHA" "$RTL_SHA" "$ADAMS_SHA" > "$RUN/provenance.txt"
sha256sum "$IVERILOG/iverilog" "$IVERILOG/vvp" "$IVERILOG/iverilog-vpi" "$JTAG_VPI" > "$RUN/tool-binaries.sha256"
sha256sum "$OPENSSL/bin/openssl" "$OPENSSL/lib/libcrypto.so" > "$RUN/openssl-binaries.sha256"
"$IVERILOG/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1
"$IVERILOG/vvp" -V > "$RUN/vvp-version.txt" 2>&1
"$PYTHON" --version > "$RUN/python-version.txt" 2>&1
"${GCC}gcc" --version > "$RUN/riscv-gcc-version.txt" 2>&1

export PATH="$ENV/bin:$IVERILOG:$GCC_DIR:$OPENSSL/bin:$PATH"
export LD_LIBRARY_PATH="$MAIN_ROOT/lib:$ENV/lib:$OPENSSL/lib"
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

"$PYTHON" -m py_compile "$RUNNER"
set +e
start_seconds=$SECONDS
/usr/bin/time -v -o "$RUN/resource.log" timeout --signal=TERM --kill-after=30s "$timeout_s" \
  "$PYTHON" "$RUNNER" --case "$case_dir" --case-yaml "$case_yaml" --output "$RUN/output" \
  > "$RUN/runner.log" 2>&1
runner_exit=$?
runner_elapsed=$((SECONDS - start_seconds))
set -e

result=$RUN/output/result.json
sim_log=$RUN/output/$case_dir/sim.log
last_heartbeat_wall=
last_heartbeat_mcycle=
if [ -f "$sim_log" ]; then
  heartbeat=$("$PYTHON" - "$sim_log" <<'PY'
import re,sys
pattern=re.compile(r"CALIPTRA_PROGRESS_HEARTBEAT wall_s=(\d+) mcycle=(\d+)")
last=None
with open(sys.argv[1],errors="replace") as stream:
    for line in stream:
        match=pattern.search(line)
        if match:
            last=match.groups()
if last:
    print(*last)
PY
)
  if [ -n "$heartbeat" ]; then
    read -r last_heartbeat_wall last_heartbeat_mcycle <<< "$heartbeat"
  fi
fi

result_testname=
result_passed=
finish_mcycle=
if [ -f "$result" ]; then
  metadata=$("$PYTHON" - "$result" <<'PY'
import json,sys
data=json.load(open(sys.argv[1]))
finish=data.get("finish") or []
print(data.get("testname",""),str(data.get("passed",False)).lower(),finish[1] if len(finish)>1 else "")
PY
)
  read -r result_testname result_passed finish_mcycle <<< "$metadata"
fi

if [ "$runner_exit" -eq 124 ] || { [ "$runner_exit" -eq 137 ] || [ "$runner_exit" -eq 143 ]; } && [ "$runner_elapsed" -ge "$((timeout_s - 5))" ]; then
  outcome=TIMEOUT
  reason=per_test_timeout
elif [ -f "$result" ] && [ "$result_testname" = "$yaml_testname" ] && [ "$result_passed" = true ]; then
  outcome=PASS
  reason=terminal_result_passed
elif [ -f "$result" ]; then
  outcome=FAIL
  reason=terminal_result_failed_or_yaml_name_mismatch
else
  outcome=FAIL
  reason=runner_or_firmware_failure_without_result_json
fi
mcycle_at_end=$finish_mcycle
mcycle_source=firmware_finish
if [ -z "$mcycle_at_end" ]; then
  mcycle_at_end=$last_heartbeat_mcycle
  mcycle_source=last_progress_heartbeat
fi
printf 'outcome=%s\nreason=%s\nrunner_exit=%s\nrunner_elapsed_s=%s\nresult_testname=%s\nverilator_outcome=%s\nverilator_mcycle=%s\nmcycle_at_end=%s\nmcycle_source=%s\nlast_heartbeat_wall_s=%s\nlast_heartbeat_mcycle=%s\nper_test_timeout_s=%s\n' \
  "$outcome" "$reason" "$runner_exit" "$runner_elapsed" "$result_testname" \
  "$verilator_outcome" "$expected_mcycle" "$mcycle_at_end" "$mcycle_source" \
  "$last_heartbeat_wall" "$last_heartbeat_mcycle" "$timeout_s" | tee "$RUN/status.txt"
grep 'Maximum resident set size' "$RUN/resource.log" || true

job_id=$SLURM_JOB_ID
archive=$ROOT/raw/job-${job_id}_retry14_${test_id}.tar.gz
{
  for f in provenance.txt selection.tsv tool-binaries.sha256 openssl-binaries.sha256 iverilog-version.txt vvp-version.txt python-version.txt riscv-gcc-version.txt resource.log runner.log status.txt output/result.json output/compile.log output/caliptra_firmware_compat.h output/open_caliptra_top.vf output/caliptra_top_sva_icarus.sv output/caliptra_top_tb_soc_bfm_icarus.sv output/caliptra_top_tb_ephemeral_jtag.sv output/caliptra_top_tb_services_icarus.sv output/dma_testcase_generator_icarus.sv output/aes_pkg_icarus.sv output/axi_if_icarus.sv output/trace_vpi/compile.log output/trace_vpi/sim-axi-trace-vpi.vpi output/$case_dir/firmware.log output/$case_dir/sim.log; do
    if [ -f "$RUN/$f" ]; then printf '%s\0' "$f"; fi
  done
} | tar --null -czf "$archive" -C "$RUN" --files-from=-
(cd "$ROOT/raw" && sha256sum "$(basename "$archive")" > "$(basename "$archive").sha256")
archive_sha=$(sha256sum "$archive" | cut -d' ' -f1)
printf 'archive=%s\narchive_sha256=%s\n' "$archive" "$archive_sha" >> "$RUN/status.txt"
