#!/usr/bin/env bash
#SBATCH --job-name=a2-m10-awtrace
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:40:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-02
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-02/logs/awtrace-%j.out

set -Eeuo pipefail

root=/home/dsell/slurm-runs/caliptra-bfm/a2/m10-verilator-asserts-20261016-02
diag="$root/diagnostics/aw-handshake"
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
openssl=/home/dsell/toolchains/iverilog-c339/openssl
model="$diag/model/obj_dir/Vcaliptra_top_tb"
task=17

IFS=$'\t' read -r index test_id testname case_dir case_yaml timeout_s timeout_basis \
    c339_outcome c339_mcycle c339_elapsed \
    < <(sed -n "$((task + 2))p" "$root/run-selection.tsv")
test "$index" = "$task"
test "$testname" = smoke_test_sha256
test "$c339_outcome" = PASS
test -x "$model"
test -f "$rtl/src/integration/test_suites/$case_yaml"

export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"

out="$diag/results-sampled/$test_id"
resource="$diag/$test_id-sampled.resource"
mkdir -p "$diag/results-sampled"
test ! -e "$out"
set +e
/usr/bin/time -v -o "$resource" timeout --signal=TERM --kill-after=30s "$((timeout_s + 1800))" \
    "$deps/bin/python3.12" "$root/run-verilator-top-case.py" \
    --source "$root/source" --rtl "$rtl" --model "$model" --output "$out" \
    --case "$case_dir" --case-yaml "$case_yaml" --timeout "$timeout_s" \
    --c339-outcome "$c339_outcome" --c339-mcycle "$c339_mcycle" --c339-elapsed "$c339_elapsed"
rc=$?
set -e
if [ ! -f "$out/result.json" ]; then
    mkdir -p "$out"
    printf '{"test_id":"%s","testname":"%s","outcome":"HARNESS_TIMEOUT_OR_CRASH","wrapper_exit":%d}\n' \
        "$test_id" "$testname" "$rc" > "$out/result.json"
fi
cp "$resource" "$out/task.resource"
( cd "$out" && find . -maxdepth 2 -type f ! -name FILE-SHA256SUMS ! -name task-complete.txt ! -path './.work/*' -print0 | sort -z | xargs -0 -r sha256sum ) \
    > "$out/FILE-SHA256SUMS"
printf 'test_id=%s testname=%s wrapper_exit=%s completed_at=%s\n' \
    "$test_id" "$testname" "$rc" "$(date -Is)" > "$out/task-complete.txt"
printf 'test_id=%s testname=%s wrapper_exit=%s timeout_basis=%s\n' \
    "$test_id" "$testname" "$rc" "$timeout_basis"
