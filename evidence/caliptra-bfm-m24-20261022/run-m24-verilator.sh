#!/usr/bin/env bash
set -Eeuo pipefail

mode=${1:?usage: run-m24-verilator.sh build | test MODEL}
source_root=$(pwd -P)
run=${source_root%/source}
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
openssl=/home/dsell/toolchains/iverilog-c339/openssl
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
selection=$source_root/evidence/caliptra-bfm-m24-20261022/selection.tsv

if [[ $mode == build ]]; then
    model=$run/model
    overlay=$run/overlay
    test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
    test -x "$gcc_dir/riscv-none-elf-gcc" && test -x "$verilator"
    mkdir -p "$overlay/config" "$overlay/tb" "$model"
    ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
    ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"
    python3 "$source_root/evidence/caliptra-bfm-verilator-m9-20261016/prepare-verilator-filelist.py" \
        "$rtl" "$source_root" "$overlay/config/caliptra_top_tb.vf" > "$run/filelist-manifest.txt"
    export PATH="$gcc_dir:$PATH"
    export CALIPTRA_ROOT="$rtl"
    export CALIPTRA_AXI4PC_DIR="$rtl/src/integration/tb"
    export CALIPTRA_PRIM_ROOT="$rtl/src/caliptra_prim_generic"
    export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
    cd "$model"
    "$verilator" --version > "$run/verilator.version"
    /usr/bin/time -v -o "$run/build.resource" make -f "$rtl/tools/scripts/Makefile" \
        "CALIPTRA_ROOT=$rtl" CALIPTRA_INTERNAL_TRNG=1 "TBDIR=$overlay/tb" \
        "INCLUDES_DIR=$rtl/src/integration/test_suites/includes" "BUILD_DIR=$model" \
        "VERILATOR=$verilator --Wno-fatal" GCC_PREFIX=riscv-none-elf \
        "VERILATOR_DEBUG=" VERILATOR_MAKE_FLAGS=OPT_FAST=-Os \
        "CFLAGS=-std=c++20 -I$rtl/src/integration/test_suites/libs/jtagdpi -I$rtl/src/integration/test_suites/libs/tcp_server" \
        "TB_DEFS=+define+CALIPTRA_INTERNAL_TRNG +define+CALIPTRA_BFM_CHECKER" \
        verilator-build > "$run/build.log" 2>&1
    test -x "$model/obj_dir/Vcaliptra_top_tb"
    sha256sum "$model/obj_dir/Vcaliptra_top_tb" > "$run/model.sha256"
    du -sb "$model" > "$run/model.bytes"
    exit 0
fi

[[ $mode == test ]] || { echo "unknown mode: $mode" >&2; exit 2; }
model=${2:?usage: run-m24-verilator.sh test MODEL}
task=${SLURM_ARRAY_TASK_ID:?array task id is required}
test -x "$model"
IFS=$'\t' read -r array_index test_id source_repo area test_kind matrix_testname source_file case_dir case_yaml \
    timeout_s m9_outcome m9_wall last_icarus last_icarus_source execution_mode \
    < <(sed -n "$((task + 2))p" "$selection")
test "$array_index" = "$task"
summary="$run/summary/$test_id.tsv"
mkdir -p "$run/summary"
test ! -e "$summary"

if [[ $execution_mode == waitlist ]]; then
    reason="non-firmware $test_kind row; the M24 full-top firmware runner only accepts stock-firmware-test-suite YAML; see docs/E-VERILOG-WAITLIST.md"
    printf 'test_id\ttestname\ttest_kind\toutcome\twall_s\ttimeout_s\tdiagnostic\n%s\t%s\t%s\tWAITLIST\t0\tNA\t%s\n' \
        "$test_id" "$matrix_testname" "$test_kind" "$reason" > "$summary"
    echo "$test_id $matrix_testname: WAITLIST (non-firmware test kind $test_kind)"
    exit 0
fi

test "$execution_mode" = full-top
test "$case_dir" = "${case_yaml%/*}"
test -f "$rtl/src/integration/test_suites/$case_yaml"
test -x "$deps/bin/python3.12" && test -x "$gcc_dir/riscv-none-elf-gcc"
test -x "$openssl/bin/openssl" && test -f "$openssl/lib/libcrypto.so"
export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"

out="$run/results/$test_id"
mkdir -p "$out"
preserve_images=()
[[ $test_id == 1b067d21081b705c ]] && preserve_images=(--keep-firmware-images)
start=$SECONDS
set +e
/usr/bin/time -v -o "$out/task.resource" timeout --signal=TERM --kill-after=30s 14300 \
    "$deps/bin/python3.12" "$source_root/evidence/caliptra-bfm-verilator-m9-20261016/run-verilator-top-case.py" \
    --source "$source_root" --rtl "$rtl" --model "$model" --output "$out/output" \
    --case "$case_dir" --case-yaml "$case_yaml" --timeout "$timeout_s" \
    --c339-outcome "$last_icarus" --c339-mcycle NA --c339-elapsed NA "${preserve_images[@]}"
runner_exit=$?
set -e
elapsed=$((SECONDS - start))

python3 - "$out/output/result.json" "$out/output/sim.log" "$out/output/firmware.log" \
    "$summary" "$test_id" "$matrix_testname" "$test_kind" "$timeout_s" "$runner_exit" "$elapsed" <<'PY'
import json,re,sys
from pathlib import Path
result_path,sim_path,firmware_path,summary_path=map(Path,sys.argv[1:5])
test_id,testname,kind,timeout_s,rc,elapsed=sys.argv[5],sys.argv[6],sys.argv[7],int(sys.argv[8]),int(sys.argv[9]),int(sys.argv[10])
result=json.loads(result_path.read_text()) if result_path.is_file() else {}
outcome=result.get('outcome','')
if not outcome:
    outcome='TIMEOUT' if rc in (124,137,143) else 'HARNESS_ERROR'
    result={'outcome':outcome,'elapsed_s':elapsed,'error':'runner ended without a terminal result'}
diagnostic=''
if outcome=='FIRMWARE_BUILD_FAIL' and firmware_path.is_file():
    candidates=[line.strip() for line in firmware_path.read_text(errors='replace').splitlines()
                if re.search(r'(?:fatal error:|error:|undefined reference|No rule to make target)',line,re.I)]
    diagnostic=candidates[0] if candidates else f"firmware build failed (exit {result.get('firmware_exit','unknown')}); no compiler diagnostic captured"
elif outcome=='FAIL' and sim_path.is_file():
    candidates=[line.strip() for line in sim_path.read_text(errors='replace').splitlines()
                if re.search(r'(?:SVA ERROR:|TESTCASE FAILED|(?:UVM_)?(?:ERROR|FATAL)\b|assert(?:ion)?[^\n]*\b(?:fail|error))',line,re.I)]
    diagnostic=candidates[0] if candidates else f"simulator returned {result.get('sim_exit','unknown')} without a clean terminal marker"
elif outcome=='TIMEOUT':
    diagnostic=f"no terminal result before the {timeout_s}-second per-case simulation limit"
elif outcome=='HARNESS_ERROR':
    diagnostic=str(result.get('error','harness ended without a terminal result')).splitlines()[0]
elif outcome=='PASS':
    diagnostic=''
else:
    diagnostic=str(result.get('reason') or result.get('error') or f"terminal outcome {outcome}").splitlines()[0]
diagnostic=diagnostic.replace('\t',' ').replace('\r',' ').replace('\n',' ')
wall=result.get('elapsed_s',elapsed)
summary_path.write_text('test_id\ttestname\ttest_kind\toutcome\twall_s\ttimeout_s\tdiagnostic\n'
                       f'{test_id}\t{testname}\t{kind}\t{outcome}\t{wall}\t{timeout_s}\t{diagnostic}\n')
print(f"{test_id} {testname}: {outcome} wall_s={wall} runner_exit={rc} {diagnostic}")
PY
exit 0
