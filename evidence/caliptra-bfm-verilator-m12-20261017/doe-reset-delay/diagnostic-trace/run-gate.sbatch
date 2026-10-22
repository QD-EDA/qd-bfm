#!/usr/bin/env bash
#SBATCH --job-name=a2-m12-doe-trace-gate
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:12:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m12-doe-status-trace-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m12-doe-status-trace-20261017-01/logs/gate-%j.out

set -Eeuo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m12-doe-status-trace-20261017-01
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
openssl=/home/dsell/toolchains/iverilog-c339/openssl
model="$run/model/obj_dir/Vcaliptra_top_tb"

IFS=$'\t' read -r index test_id testname case_dir case_yaml timeout_s timeout_basis \
    c339_outcome c339_mcycle c339_elapsed < <(sed -n '2p' "$run/gate-selection.tsv")
test "$index" = 0
test "$test_id" = 8f9e58bda7a24230
test "$testname" = smoke_test_doe_scan
test "$case_yaml" = smoke_test_doe_scan/smoke_test_doe_scan.yml
test "$timeout_s" = 21600
test -x "$model"
test -f "$rtl/src/integration/test_suites/$case_yaml"
test -x "$deps/bin/python3.12"
test -x "$gcc_dir/riscv-none-elf-gcc"
test -x "$openssl/bin/openssl" && test -f "$openssl/lib/libcrypto.so"

export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"

{
    date -Is
    hostname
    uname -a
    printf 'slurm_job_id=%s\n' "$SLURM_JOB_ID"
    printf 'verilator='; /home/dsell/toolchains/verilator-5.052/bin/verilator --version
    printf 'gcc='; "$gcc_dir/riscv-none-elf-gcc" --version | sed -n '1p'
    printf 'python='; "$deps/bin/python3.12" --version
    cat "$run/axi_if.overlay.sha256" "$run/soc_bfm.overlay.sha256" "$run/doe.overlay.sha256" "$run/model.sha256"
    printf 'outer_timeout_s=600\n'
} > "$run/gate-environment-${SLURM_JOB_ID}.txt"

out="$run/gate-results/$test_id"
resource="$run/resources/${test_id}-${SLURM_JOB_ID}.resource"
mkdir -p "$run/resources"
test ! -e "$out"
set +e
/usr/bin/time -v -o "$resource" timeout --signal=TERM --kill-after=10s 600s \
    "$deps/bin/python3.12" "$run/run-verilator-top-case.py" \
    --source "$run/source" --rtl "$rtl" --model "$model" --output "$out" \
    --case "$case_dir" --case-yaml "$case_yaml" --timeout "$timeout_s" \
    --c339-outcome "$c339_outcome" --c339-mcycle "$c339_mcycle" --c339-elapsed "$c339_elapsed"
rc=$?
set -e
if [ ! -f "$out/result.json" ]; then
    mkdir -p "$out"
    printf '{"test_id":"%s","testname":"%s","outcome":"DIAGNOSTIC_NO_RESULT","outer_timeout_s":600,"wrapper_exit":%d}\n' \
        "$test_id" "$testname" "$rc" > "$out/result.json"
fi
cp "$resource" "$out/task.resource"
( cd "$out" && find . -maxdepth 2 -type f ! -name FILE-SHA256SUMS ! -name task-complete.txt ! -path './.work/*' -print0 | sort -z | xargs -0 -r sha256sum ) \
    > "$out/FILE-SHA256SUMS"
printf 'test_id=%s testname=%s wrapper_exit=%s outer_timeout_s=600 completed_at=%s\n' \
    "$test_id" "$testname" "$rc" "$(date -Is)" > "$out/task-complete.txt"
printf 'test_id=%s testname=%s wrapper_exit=%s timeout_basis=%s outer_timeout_s=600\n' \
    "$test_id" "$testname" "$rc" "$timeout_basis"
exit 0
