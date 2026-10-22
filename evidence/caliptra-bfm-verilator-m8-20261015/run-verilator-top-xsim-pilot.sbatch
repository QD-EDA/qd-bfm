#!/usr/bin/env bash
#SBATCH --job-name=a2-vlt-xsim-pilot
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:45:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-06
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-06/logs/%x-%A_%a.out

set -Eeuo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-top-20261015-06
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
openssl=/home/dsell/toolchains/iverilog-c339/openssl
model="$run/model-xsim/obj_dir/Vcaliptra_top_tb"
cohort=${COHORT:?submit with COHORT=<tsv filename>}
task=${SLURM_ARRAY_TASK_ID:?}
IFS=$'\t' read -r index case timeout_s c339_outcome c339_mcycle c339_elapsed \
    < <(sed -n "$((task + 1))p" "$run/$cohort")
test "$index" = "$task"
test -x "$model"
test -f "$rtl/src/integration/test_suites/$case/$case.yml"
test -x "$deps/bin/python3.12"
test -x "$gcc_dir/riscv-none-elf-gcc"
test -x "$openssl/bin/openssl" && test -f "$openssl/lib/libcrypto.so"

export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"

out="$run/results-xsim/$case"
resource="$run/resources-xsim/${case}-${SLURM_ARRAY_JOB_ID}-${task}.task.resource"
mkdir -p "$run/resources-xsim"
test ! -e "$out"
set +e
/usr/bin/time -v -o "$resource" timeout --signal=TERM --kill-after=30s "$((timeout_s + 1800))" \
    "$deps/bin/python3.12" "$run/run-verilator-top-case.py" \
    --source "$run/source" --rtl "$rtl" --model "$model" --output "$out" \
    --case "$case" --timeout "$timeout_s" --c339-outcome "$c339_outcome" \
    --c339-mcycle "$c339_mcycle" --c339-elapsed "$c339_elapsed"
rc=$?
set -e
if [ ! -f "$out/result.json" ]; then
    mkdir -p "$out"
    printf '{"case":"%s","outcome":"HARNESS_TIMEOUT_OR_CRASH","wrapper_exit":%d}\n' \
        "$case" "$rc" > "$out/result.json"
fi
printf 'case=%s wrapper_exit=%s\n' "$case" "$rc"
exit 0
