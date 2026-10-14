#!/bin/bash
#SBATCH --job-name=caliptra-rand-dma-5945-current
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-rand-dma-notrace-5945efe-20261010-04
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-rand-dma-notrace-5945efe-20261010-04/logs/%x-%j.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-rand-dma-notrace-5945efe-20261010-04
BUILT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
PRIOR=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-11
GCC_RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-fw-smoke-20261009-10
QD="$RUN/source/qd-bfm"
IVERILOG_SRC="$BUILT/source/iverilog-uvm"
RTL="$PRIOR/source/caliptra-rtl"
ENV="$BUILT/deps"
IVERILOG="$BUILT/toolchain/iverilog/bin"
GCC="$GCC_RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-"
JTAG_VPI="$GCC_RUN/jtagdpi/jtagdpi.vpi"
QD_SHA=5945efeae78580cc8a5bd7a4050ee4dfec39d7be
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
UVM_SHA=78c06547a2a0a29b3dc9dcafae62b75b2ff61544
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_BRIDGE_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0
JTAG_VPI_SHA=34bb301fe6ec5e6b50fba076d433310c8168a628aa3a4f8f81837324823d0d07
RUNNER_SHA=ea57294b045c7cae66a8aa6b93692a4c1ae8b343160624e0f137b71d855c6cb0

test "$(sha256sum "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py" | cut -d' ' -f1)" = "$RUNNER_SHA"
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test "$(git -C "$IVERILOG_SRC/uvm-core" rev-parse HEAD)" = "$UVM_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_BRIDGE_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -x "$IVERILOG/iverilog"
test -x "$IVERILOG/vvp"
test -x "${GCC}gcc"
test -x "$ENV/bin/python3.12"
test -f "$ENV/include/mbedtls/version.h"
test -f "$JTAG_VPI"
printf 'QD=%s\nrunner-sha256=%s\nIcarus=%s\nUVM=%s\nCaliptra=%s\nAdams-Bridge=%s\nJTAG-VPI-SHA=%s\n' \
  "$QD_SHA" "$RUNNER_SHA" "$IVERILOG_SHA" "$UVM_SHA" "$RTL_SHA" "$ADAMS_BRIDGE_SHA" "$JTAG_VPI_SHA" | tee "$RUN/source-revisions.txt"
sha256sum "$JTAG_VPI" "$IVERILOG/iverilog" "$IVERILOG/vvp" | tee "$RUN/tool-binaries.sha256"
grep -q "$JTAG_VPI_SHA" "$RUN/tool-binaries.sha256"
export PATH="$ENV/bin:$IVERILOG:$GCC_RUN/xpack/xpack-riscv-none-elf-gcc-15.2.0-1/bin:$PATH"
export LD_LIBRARY_PATH="$BUILT/toolchain/iverilog/lib:$ENV/lib"
export CALIPTRA_MBEDTLS_ROOT="$ENV"
export CALIPTRA_RTL="$RTL"
export IVERILOG_BIN="$IVERILOG/iverilog"
export VVP_BIN="$IVERILOG/vvp"
export IVERILOG_SOURCE_ROOT="$IVERILOG_SRC"
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=5400
export PYTHONPYCACHEPREFIX="$RUN/pycache"
export CALIPTRA_BFM_PROFILE="$RTL/src/integration/config/caliptra_top_tb.vf"
export CALIPTRA_GCC_PREFIX="$GCC"
export CALIPTRA_JTAGDPI_VPI="$JTAG_VPI"
python3.12 -m py_compile "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
python3.12 "$QD/scripts/run_with_memory_pressure_guard.py" --interval 0.1 --timeout-seconds 30 -- /usr/bin/true
/usr/bin/time -v -o "$RUN/logs/rand-dma-resource.log" \
  sh "$QD/dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh" \
  --case rand_test_dma --rand-dma-iterations 1 --fast-trng \
  --fast-boot-data-preload --quiet-firmware \
  --output "$RUN/output/rand-dma-one" \
  > "$RUN/logs/rand-dma.out" 2>&1
python3.12 -c 'import json,sys; r=json.load(open(sys.argv[1])); assert r["passed"], r; print("NO_TRACE_ONE_ITERATION_RAND_DMA=PASS; Icarus=" + r["simulator_provenance"]["iverilog"]["version"])' "$RUN/output/rand-dma-one/result.json"
grep 'Maximum resident set size' "$RUN/logs/rand-dma-resource.log"
