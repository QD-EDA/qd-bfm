#!/bin/bash
#SBATCH --job-name=bfm-aes7-fulltop
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/bfm-fulltop-aes-case7-20261010-03
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/bfm-fulltop-aes-case7-20261010-03/logs/%x-%j.out

set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/bfm-fulltop-aes-case7-20261010-03
QD="$RUN/source/qd-bfm"
IVERILOG_SRC="$RUN/source/iverilog-uvm"
RTL="$RUN/source/caliptra-rtl"
ENV="$RUN/deps-readonly"
IVERILOG="$RUN/toolchain/iverilog/bin/iverilog"
VVP="$RUN/toolchain/iverilog/bin/vvp"
IVERILOG_VPI="$RUN/toolchain/iverilog/bin/iverilog-vpi"
GCC_ARCHIVE="$RUN/toolchain/riscv-gcc.tar.gz"
QD_SHA=53c44cf9fcffe4cde4f47e2d89accaae099ffbcf
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
UVM_SHA=78c06547a2a0a29b3dc9dcafae62b75b2ff61544
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e

test "$(git -C "$QD" rev-parse HEAD)" = "$QD_SHA"
test -z "$(git -C "$QD" status --porcelain --untracked-files=all)"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test "$(git -C "$IVERILOG_SRC/uvm-core" rev-parse HEAD)" = "$UVM_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -x "$IVERILOG" && test -x "$VVP" && test -x "$IVERILOG_VPI"
test -f "$ENV/include/z3.h" && test -f "$ENV/include/mbedtls/ssl.h"
test "$(sha256sum "$GCC_ARCHIVE" | cut -d' ' -f1)" = aaaa8060c914851a3e5ee1ba82cc3d6f80972f90638a05c6e823a37557a33758
printf 'QD=%s\nIcarus=%s\nUVM=%s\nCaliptra=%s\n' "$QD_SHA" "$IVERILOG_SHA" "$UVM_SHA" "$RTL_SHA" | tee "$RUN/source-commits.txt"
"$IVERILOG" -V > "$RUN/toolchain/iverilog-version.txt" 2>&1
sha256sum "$IVERILOG" "$VVP" > "$RUN/toolchain/iverilog-binaries.sha256"
g++ --version | head -n 1 > "$RUN/toolchain/host-cxx-version.txt"
export PATH="$ENV/bin:$PATH"
export LD_LIBRARY_PATH="$ENV/lib"
export CALIPTRA_MBEDTLS_ROOT="$ENV"
export PYTHONPYCACHEPREFIX="$RUN/pycache"
mkdir -p "$RUN/xpack" "$RUN/jtagdpi"
tar -xzf "$GCC_ARCHIVE" -C "$RUN/xpack"
GCC_PREFIX="$RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-"
test -x "$GCC_PREFIX"gcc
(
  cd "$RUN/jtagdpi"
  /usr/bin/time -v -o "$RUN/logs/jtagdpi-resource.log" \
    "$IVERILOG_VPI" \
    -I"$RTL/src/integration/test_suites/libs/tcp_server" \
    "$RTL/src/integration/test_suites/libs/jtagdpi/jtagdpi.c" \
    "$RTL/src/integration/test_suites/libs/tcp_server/tcp_server.c"
)
export IVERILOG_BIN="$IVERILOG"
export VVP_BIN="$VVP"
export IVERILOG_SOURCE_ROOT="$IVERILOG_SRC"
export IVERILOG_VPI_BIN="$IVERILOG_VPI"
export CALIPTRA_RTL="$RTL"
export PATH="$RUN/toolchain/iverilog/bin:$RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin:$PATH"
export CALIPTRA_BFM_PROFILE="$RTL/src/integration/config/caliptra_top_tb.vf"
export CALIPTRA_GCC_PREFIX="$GCC_PREFIX"
export CALIPTRA_JTAGDPI_VPI="$RUN/jtagdpi/jtagdpi.vpi"
python3 -m py_compile "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
command -v timeout
# Slurm bounds memory; invoke the Python entry point because the shell guard is macOS-only.
set +e
/usr/bin/time -v -o "$RUN/logs/firmware-smoke-resource.log" timeout --signal=TERM --kill-after=30s 5400s python3 "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" \
  --case smoke_test_dma_aes_gcm_short_1_dword \
  --limit-aes-cases 1 --start-aes-case 6 --fast-trng --trace-axi \
  --output "$RUN/output/case7" \
  > "$RUN/logs/firmware-smoke.out" 2>&1
runner_status=$?
set -e
printf 'runner_exit=%s\n' "$runner_status" | tee "$RUN/runner-status.txt"
test -z "$(git -C "$QD" status --porcelain --untracked-files=all)"
printf 'Peak RSS records (kB):\n'
for resource in "$RUN"/logs/*resource.log; do
  printf '%s: ' "$(basename "$resource")"
  grep 'Maximum resident set size' "$resource" || true
done
exit "$runner_status"
