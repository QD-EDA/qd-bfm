#!/usr/bin/env bash
#SBATCH --job-name=bfm-m7-fw-compat
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:30:00
#SBATCH --array=1-6%2
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-fw-compat-d1529c9-20261014-02/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-fw-compat-d1529c9-20261014-02/logs/%x-%A_%a.out

set -Eeuo pipefail

ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-fw-compat-d1529c9-20261014-02
QD=/home/dsell/toolchains/qd-bfm-d1529c922da402943148a0fb22648f347e30eed9
BUILT=/home/dsell/toolchains/iverilog-c339
RTL=$BUILT/firmware/caliptra-rtl
ENV=$BUILT/deps
OPENSSL=$BUILT/openssl
GCC_DIR=$BUILT/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
GCC=$GCC_DIR/riscv-none-elf-
GCC_PREFIX=riscv-none-elf
PYTHON=$ENV/bin/python3.12
RUNNER=$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py
TASK_ID=${SLURM_ARRAY_TASK_ID:?}

IFS=$'\t' read -r task_id test_case mode < <(sed -n "$((TASK_ID + 1))p" "$ROOT/firmware-build-tasks.tsv")
test "$task_id" = "$TASK_ID"
[[ "$mode" == pinned-only || "$mode" == with-overlay ]]
test "$(cat "$QD/qd-bfm.commit")" = d1529c922da402943148a0fb22648f347e30eed9
test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -x "${GCC}gcc" && test -x "${GCC}cpp" && test -x "$PYTHON"

TASK_ROOT=$ROOT/tasks/${TASK_ID}-${test_case}-${mode}
OUTPUT=$TASK_ROOT/build
mkdir -p "$OUTPUT"
test ! -e "$TASK_ROOT/firmware.log"
export PYTHONPYCACHEPREFIX="$TASK_ROOT/pycache"

export PATH="$ENV/bin:$GCC_DIR:$OPENSSL/bin:$PATH"
export LD_LIBRARY_PATH="$ENV/lib:$OPENSSL/lib"
export CALIPTRA_MBEDTLS_ROOT="$ENV"
export CALIPTRA_RTL="$RTL"
export CALIPTRA_ROOT="$RTL"
export CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
export CALIPTRA_AXI4PC_DIR="$RTL/src/integration/tb"
export CALIPTRA_GCC_PREFIX="$GCC"

"$PYTHON" - "$RUNNER" "$RTL" "$test_case" "$mode" "$OUTPUT" > "$TASK_ROOT/setup.log" <<'PY'
import importlib.util
import sys
from pathlib import Path

runner_path, rtl_root, case, mode, output = sys.argv[1:]
spec = importlib.util.spec_from_file_location("firmware_runner", runner_path)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)
case_yaml, seed, _, testname = runner.load_case(Path(rtl_root), case)
compat = ""
if mode == "with-overlay":
    compat = runner.prepare_firmware_compat_overlay(
        case, Path(output) / "caliptra_firmware_compat.h", rtl_root=rtl_root,
    )
print(f"case={case}\nmode={mode}\nyaml={case_yaml}\ntestname={testname}\nseed={seed}\noverlay={compat}")
PY

seed=$(sed -n 's/^seed=//p' "$TASK_ROOT/setup.log")
overlay=$(sed -n 's/^overlay=//p' "$TASK_ROOT/setup.log")
test -n "$seed"
BUILD_CFLAGS="-std=gnu11 -O2"
if [ "$mode" = with-overlay ]; then
  test -f "$overlay"
  BUILD_CFLAGS="$BUILD_CFLAGS -include $overlay"
fi

printf 'host=%s\nslurm_job_id=%s\narray_task_id=%s\ncase=%s\nmode=%s\nrtl_sha=%s\nqd_sha=%s\nriscv_gcc=%s\n' \
  "$(hostname)" "$SLURM_JOB_ID" "$TASK_ID" "$test_case" "$mode" \
  "$(git -C "$RTL" rev-parse HEAD)" "$(cat "$QD/qd-bfm.commit")" "$("${GCC}gcc" -dumpfullversion)" \
  > "$TASK_ROOT/provenance.txt"
"${GCC}gcc" --version | head -n 1 >> "$TASK_ROOT/provenance.txt"
sha256sum "${GCC}gcc" > "$TASK_ROOT/gcc-sha256.txt"

set +e
cd "$OUTPUT"
/usr/bin/time -v -o "$TASK_ROOT/resource.log" timeout --signal=TERM --kill-after=30s 600s \
  make -f "$RTL/tools/scripts/Makefile" "TESTNAME=$test_case" "GCC_PREFIX=$GCC_PREFIX" \
    CALIPTRA_INTERNAL_TRNG=1 "PLAYBOOK_RANDOM_SEED=$seed" \
    "BUILD_CFLAGS=$BUILD_CFLAGS" program.hex \
    > "$TASK_ROOT/firmware.log" 2>&1
build_exit=$?
set -e

if [ "$build_exit" -eq 124 ]; then
  outcome=TIMEOUT
elif [ "$build_exit" -eq 0 ] && \
     test -s "$OUTPUT/program.hex" && test -s "$OUTPUT/dccm.hex" && \
     test -s "$OUTPUT/iccm.hex" && test -s "$OUTPUT/mailbox.hex"; then
  outcome=BUILD_PASS
  sha256sum "$OUTPUT/program.hex" "$OUTPUT/dccm.hex" "$OUTPUT/iccm.hex" "$OUTPUT/mailbox.hex" \
    > "$TASK_ROOT/image-sha256.txt"
else
  outcome=BUILD_FAIL
fi
diagnostic=$(rg -m 1 -o 'error:.*|undefined reference to .*' "$TASK_ROOT/firmware.log" || true)
printf 'outcome=%s\nbuild_exit=%s\nseed=%s\nprimary_diagnostic=%s\n' \
  "$outcome" "$build_exit" "$seed" "$diagnostic" > "$TASK_ROOT/result.txt"
grep 'Maximum resident set size' "$TASK_ROOT/resource.log" >> "$TASK_ROOT/result.txt" || true

# Keep the result, hashes and logs; remove generated firmware images and build files now.
rm -rf "$OUTPUT" "$TASK_ROOT/pycache"
exit 0
