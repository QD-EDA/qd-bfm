#!/usr/bin/env bash
#SBATCH --job-name=a2-m9-seed-fix
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=07:00:00
#SBATCH --dependency=afterok:1430
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m9-verilator-seed-fix-20261016-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m9-verilator-seed-fix-20261016-01/logs/%x-%j.out

set -Eeuo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m9-verilator-seed-fix-20261016-01
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
openssl=/home/dsell/toolchains/iverilog-c339/openssl
model=/home/dsell/slurm-runs/caliptra-bfm/a2/m9-verilator-top-20261016-01/model/obj_dir/Vcaliptra_top_tb
test_id=758d1f7d83680ac0
case=smoke_test_mldsa_keygen_standalone_sign_vfy_rand
case_yaml="$case/$case.yml"
out="$run/results/$test_id"
resource="$run/resources/$test_id.resource"

test -x "$model"
test "$(sha256sum "$model" | cut -d' ' -f1)" = ce2d0e5012cfbedb46c01a24acf948fae4f0948b140e482348407677bf9b79de
test -f "$rtl/src/integration/test_suites/$case_yaml"
export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"
mkdir -p "$run/resources"

set +e
/usr/bin/time -v -o "$resource" timeout --signal=TERM --kill-after=30s 23400 \
    "$deps/bin/python3.12" "$run/run-verilator-top-case.py" \
    --source "$run/source" --rtl "$rtl" --model "$model" \
    --output "$out" --case "$case" --case-yaml "$case_yaml" --timeout 21600 \
    --c339-outcome UNVERIFIED --c339-mcycle NA --c339-elapsed NA
rc=$?
set -e

test -f "$out/result.json"
cp "$resource" "$out/task.resource"
python3 -c 'import shutil,sys; shutil.rmtree(sys.argv[1], ignore_errors=True)' "$out/.work"
( cd "$out" && find . -maxdepth 2 -type f ! -name FILE-SHA256SUMS ! -name task-complete.txt -print0 | sort -z | xargs -0 -r sha256sum ) > "$out/FILE-SHA256SUMS"
printf 'test_id=%s testname=%s wrapper_exit=%s completed_at=%s\n' \
    "$test_id" "$case" "$rc" "$(date -Is)" > "$out/task-complete.txt"
printf 'wrapper_exit=%s result=%s\n' "$rc" "$out/result.json"
