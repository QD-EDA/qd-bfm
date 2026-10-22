#!/usr/bin/env bash
#SBATCH --job-name=a2-m9-mbox-diag
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m9-mbox-resp-user-overlay-20261016-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m9-mbox-resp-user-overlay-20261016-01/logs/%x-%j.out

set -Eeuo pipefail

run=/home/dsell/slurm-runs/caliptra-bfm/a2/m9-mbox-resp-user-overlay-20261016-01
base=/home/dsell/slurm-runs/caliptra-bfm/a2/m9-verilator-top-20261016-01
rtl=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
repo="$run/source"
overlay="$run/overlay"
model="$run/model"
diagnostic="$run/diagnostic"
verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
gcc_dir=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
deps=/home/dsell/toolchains/iverilog-c339/deps
openssl=/home/dsell/toolchains/iverilog-c339/openssl

test "$(git -C "$rtl" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -x "$gcc_dir/riscv-none-elf-gcc"
mkdir -p "$diagnostic" "$overlay/config" "$overlay/tb" "$model" "$run/results"
cp -a "$base/source" "$repo"
cp -a "$base/overlay/." "$overlay/"
cp "$base/prepare-verilator-filelist.py" "$base/run-verilator-top-case.py" "$run/"
ln -sf "$rtl/src/integration/tb/test_caliptra_top_tb.cpp" "$overlay/tb/test_caliptra_top_tb.cpp"
ln -sf "$rtl/src/integration/config/caliptra_top_tb.vlt" "$overlay/config/caliptra_top_tb.vlt"

cp "$rtl/src/axi/rtl/axi_if.sv" "$diagnostic/axi_if.sv"
sha256sum "$rtl/src/axi/rtl/axi_if.sv" > "$diagnostic/axi_if.upstream.sha256"
python3 - "$diagnostic/axi_if.sv" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
before = "            data = new[len+1];\n            resp = new[len+1];"
after = "            data = new[len+1];\n            resp_user = new[len+1];\n            resp = new[len+1];"
if text.count(before) != 1:
    raise SystemExit("expected exactly one AXI read output-array allocation site")
path.write_text(text.replace(before, after, 1))
PY
diff -u "$rtl/src/axi/rtl/axi_if.sv" "$diagnostic/axi_if.sv" > "$diagnostic/axi_if.patch" || test "$?" -eq 1
sha256sum "$diagnostic/axi_if.sv" > "$diagnostic/axi_if.overlay.sha256"

python3 "$run/prepare-verilator-filelist.py" "$rtl" "$repo" "$overlay/config/caliptra_top_tb.vf" > "$run/filelist-manifest.txt"
python3 - "$overlay/config/caliptra_top_tb.vf" "$diagnostic/axi_if.sv" <<'PY'
from pathlib import Path
import sys

filelist, overlay = map(Path, sys.argv[1:])
text = filelist.read_text()
before = "${CALIPTRA_ROOT}/src/axi/rtl/axi_if.sv"
if text.splitlines().count(before) != 1:
    raise SystemExit("expected exactly one pinned axi_if.sv filelist entry")
filelist.write_text(text.replace(before, str(overlay.resolve()), 1))
PY
sha256sum "$overlay/config/caliptra_top_tb.vf" > "$diagnostic/filelist.sha256"

export PATH="$gcc_dir:$PATH"
export CALIPTRA_ROOT="$rtl"
export CALIPTRA_AXI4PC_DIR="$rtl/src/integration/tb"
export CALIPTRA_PRIM_ROOT="$rtl/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic
cd "$model"
"$verilator" --version > "$diagnostic/verilator.version"
/usr/bin/time -v -o "$diagnostic/build.resource" make -f "$rtl/tools/scripts/Makefile" \
    "CALIPTRA_ROOT=$rtl" \
    CALIPTRA_INTERNAL_TRNG=1 \
    "TBDIR=$overlay/tb" \
    "INCLUDES_DIR=$rtl/src/integration/test_suites/includes" \
    "BUILD_DIR=$model" \
    "VERILATOR=$verilator --Wno-fatal" \
    GCC_PREFIX=riscv-none-elf \
    "VERILATOR_DEBUG=" \
    VERILATOR_MAKE_FLAGS=OPT_FAST=-Os \
    "CFLAGS=-std=c++20 -I$rtl/src/integration/test_suites/libs/jtagdpi -I$rtl/src/integration/test_suites/libs/tcp_server" \
    "TB_DEFS=+define+CALIPTRA_INTERNAL_TRNG +define+CALIPTRA_BFM_CHECKER" \
    verilator-build > "$diagnostic/build.log" 2>&1
test -x "$model/obj_dir/Vcaliptra_top_tb"
sha256sum "$model/obj_dir/Vcaliptra_top_tb" > "$diagnostic/model.sha256"

export PATH="$openssl/bin:$deps/bin:$gcc_dir:$PATH"
export LD_LIBRARY_PATH="$deps/lib:$openssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export CALIPTRA_MBEDTLS_ROOT="$deps"
export CALIPTRA_GCC_PREFIX="$gcc_dir/riscv-none-elf-"
set +e
/usr/bin/time -v -o "$diagnostic/test.resource" timeout --signal=TERM --kill-after=30s 600s \
    "$deps/bin/python3.12" "$run/run-verilator-top-case.py" \
    --source "$repo" --rtl "$rtl" --model "$model/obj_dir/Vcaliptra_top_tb" \
    --output "$run/results/smoke_test_mbox" \
    --case smoke_test_mbox --case-yaml smoke_test_mbox/smoke_test_mbox.yml \
    --timeout 10714 --c339-outcome PASS --c339-mcycle NA --c339-elapsed NA \
    > "$diagnostic/harness.stdout" 2>&1
rc=$?
set -e
printf 'wrapper_exit=%s completed_at=%s\n' "$rc" "$(date -Is)" > "$diagnostic/wrapper-exit.txt"
exit 0
