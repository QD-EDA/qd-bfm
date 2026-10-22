#!/usr/bin/env bash
#SBATCH --job-name=a2-m12-sha512-zeroize
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=07:00:00
#SBATCH --array=1-3%3
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m12-sha512-zeroize-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m12-sha512-zeroize-20261017-01/logs/%x-%A_%a.out

set -Eeuo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m12-sha512-zeroize-20261017-01
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
openssl=/home/dsell/toolchains/iverilog-c339/openssl
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
model="$run/model/obj_dir/Vcaliptra_top_tb"
overlay_file="$run/overlay/rtl/src/sha512/rtl/sha512.sv"
expected_overlay_sha256=07cf9768b17b394ec492ed2272d95440509813a902a39927bf364f3b61a25f39
task=${SLURM_ARRAY_TASK_ID:?}

IFS=$'\t' read -r index test_id testname case_dir case_yaml timeout_s timeout_basis \
    c339_outcome c339_mcycle c339_elapsed \
    < <(sed -n "$((task + 2))p" "$run/run-selection.tsv")
test "$index" = "$task"
test -x "$model"
test -f "$rtl/src/integration/test_suites/$case_yaml"
test -x "$deps/bin/python3.12"
test -x "$gcc_dir/riscv-none-elf-gcc"
test -x "$openssl/bin/openssl" && test -f "$openssl/lib/libcrypto.so"
overlay_sha256=$(sha256sum "$overlay_file" | cut -d' ' -f1)
test "$overlay_sha256" = "$expected_overlay_sha256"
outer_timeout_s=$((timeout_s + 1800))

export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"

out="$run/results/$test_id"
resource="$run/resources/${test_id}-${SLURM_ARRAY_JOB_ID}-${task}.resource"
mkdir -p "$run/resources"
test ! -e "$out"
set +e
/usr/bin/time -v -o "$resource" timeout --signal=TERM --kill-after=30s "${outer_timeout_s}s" \
    "$deps/bin/python3.12" "$run/run-verilator-top-case.py" \
    --source "$run/source" --rtl "$rtl" --model "$model" --output "$out" \
    --case "$case_dir" --case-yaml "$case_yaml" --timeout "$timeout_s" \
    --c339-outcome "$c339_outcome" --c339-mcycle "$c339_mcycle" --c339-elapsed "$c339_elapsed"
rc=$?
set -e
if [ ! -f "$out/result.json" ]; then
    mkdir -p "$out"
    printf '{"test_id":"%s","testname":"%s","outcome":"HARNESS_TIMEOUT_OR_CRASH","outer_timeout_s":%d,"wrapper_exit":%d}\n' \
        "$test_id" "$testname" "$outer_timeout_s" "$rc" > "$out/result.json"
fi
cp "$resource" "$out/task.resource"
{
    date -Is
    hostname
    uname -a
    printf 'slurm_job_id=%s\n' "$SLURM_JOB_ID"
    printf 'array_job_id=%s\n' "$SLURM_ARRAY_JOB_ID"
    printf 'array_task_id=%s\n' "$task"
    printf 'test_id=%s testname=%s\n' "$test_id" "$testname"
    printf 'verilator='; "$verilator" --version
    printf 'gcc='; "$gcc_dir/riscv-none-elf-gcc" --version | sed -n '1p'
    printf 'python='; "$deps/bin/python3.12" --version
    cat "$run/axi_if.overlay.sha256" "$run/soc_bfm.overlay.sha256" "$run/sha512.overlay.sha256" "$run/model.sha256"
    printf 'outer_timeout_s=%s\n' "$outer_timeout_s"
} > "$out/environment.txt"
( cd "$out" && find . -maxdepth 2 -type f ! -name FILE-SHA256SUMS ! -name task-complete.txt ! -path './.work/*' -print0 | sort -z | xargs -0 -r sha256sum ) \
    > "$out/FILE-SHA256SUMS"
printf 'test_id=%s testname=%s wrapper_exit=%s outer_timeout_s=%s completed_at=%s\n' \
    "$test_id" "$testname" "$rc" "$outer_timeout_s" "$(date -Is)" > "$out/task-complete.txt"
printf 'test_id=%s testname=%s wrapper_exit=%s timeout_basis=%s outer_timeout_s=%s\n' \
    "$test_id" "$testname" "$rc" "$timeout_basis" "$outer_timeout_s"
