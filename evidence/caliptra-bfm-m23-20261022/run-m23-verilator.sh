#!/usr/bin/env bash
set -Eeuo pipefail

mode=${1:?usage: run-m23-verilator.sh build | test MODEL}
source_root=$(pwd -P)
run=${source_root%/source}
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
deps=/home/dsell/toolchains/iverilog-c339/deps
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
openssl=/home/dsell/toolchains/iverilog-c339/openssl
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
selection=$source_root/evidence/caliptra-bfm-m23-20261022/selection.tsv

if [[ $mode == build ]]; then
    model=$run/model
    overlay=$run/overlay
    test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
    test -x "$gcc_dir/riscv-none-elf-gcc"
    test -x "$verilator"
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
model=${2:?usage: run-m23-verilator.sh test MODEL}
task=${SLURM_ARRAY_TASK_ID:?array task id is required}
test -x "$model"
test -x "$deps/bin/python3.12" && test -x "$gcc_dir/riscv-none-elf-gcc"
test -x "$openssl/bin/openssl" && test -f "$openssl/lib/libcrypto.so"

IFS=$'\t' read -r array_index m11_index test_id case_dir case_yaml yaml_testname \
    m21_icarus_outcome m21_icarus_wall_s m11_verilator_outcome m11_verilator_mcycle timeout_s \
    < <(sed -n "$((task + 2))p" "$selection")
test "$array_index" = "$task"
test -n "$test_id" && test -n "$case_dir" && test -n "$case_yaml"
test -f "$rtl/src/integration/test_suites/$case_yaml"

out=$run/results/$test_id
mkdir -p "$out"
sed -n "$((task + 2))p" "$selection" > "$out/selection.tsv"
export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"

run_started=$SECONDS
set +e
/usr/bin/time -v -o "$out/task.resource" timeout --signal=TERM --kill-after=30s 14300 \
    "$deps/bin/python3.12" "$source_root/evidence/caliptra-bfm-verilator-m9-20261016/run-verilator-top-case.py" \
    --source "$source_root" --rtl "$rtl" --model "$model" --output "$out/output" \
    --case "$case_dir" --case-yaml "$case_yaml" --timeout "$timeout_s" \
    --c339-outcome UNVERIFIED --c339-mcycle NA --c339-elapsed NA
runner_exit=$?
set -e
runner_elapsed=$((SECONDS - run_started))

python3 - "$out/output/result.json" "$out/status.tsv" "$test_id" "$case_dir" "$runner_exit" "$runner_elapsed" <<'PY'
import json,sys
from pathlib import Path
result_path,status_path=map(Path,sys.argv[1:3])
test_id,case,rc,elapsed=sys.argv[3],sys.argv[4],int(sys.argv[5]),int(sys.argv[6])
if result_path.is_file():
    try:
        result=json.loads(result_path.read_text())
    except Exception as error:
        result={'test_id':test_id,'case':case,'outcome':'FAIL','elapsed_s':elapsed,
                'runner_exit':rc,'error':f'unreadable result: {error}'}
else:
    outcome='TIMEOUT' if rc in (124,137,143) else 'FAIL'
    result={'test_id':test_id,'case':case,'outcome':outcome,'elapsed_s':elapsed,'runner_exit':rc,
            'error':'runner ended without a terminal result'}
    result_path.parent.mkdir(parents=True,exist_ok=True)
    result_path.write_text(json.dumps(result,indent=2)+'\n')
outcome=result.get('outcome','FAIL')
wall=result.get('elapsed_s',elapsed)
reason=result.get('reason') or result.get('error','')
reason=str(reason).replace('\t',' ').replace('\n',' ')
status_path.write_text(f'test_id\tcase\toutcome\twall_s\trunner_exit\treason\n'
                       f'{test_id}\t{case}\t{outcome}\t{wall}\t{rc}\t{reason}\n')
print(f'{test_id} {case}: {outcome} wall_s={wall} runner_exit={rc}')
PY

exit 0
