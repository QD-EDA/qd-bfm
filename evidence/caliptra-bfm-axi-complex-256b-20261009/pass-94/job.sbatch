#!/bin/bash
#SBATCH --job-name=caliptra-axi-256b
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-256b-c8ce915-20261009-02
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-256b-c8ce915-20261009-02/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-256b-c8ce915-20261009-02
QD="$RUN/source/qd-bfm"
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
ICARUS_SOURCE="$BASE/source/iverilog-uvm"
RTL="$BASE/source/caliptra-rtl"
IVERILOG_BIN="$BASE/toolchain/iverilog/bin/iverilog"
VVP_BIN="$BASE/toolchain/iverilog/bin/vvp"
QD_SHA=c8ce91584088cbdaa8d8f517d5ecc923f1fa4390
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
(cd "$RUN/source" && sha256sum --check qd-bfm.tar.gz.sha256)
test "$(git -C "$ICARUS_SOURCE" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$ICARUS_SOURCE" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -x "$IVERILOG_BIN" && test -x "$VVP_BIN"
printf 'QD=%s\nIcarus=%s\nCaliptra=%s\n' "$QD_SHA" "$IVERILOG_SHA" "$RTL_SHA" > "$RUN/logs/source-commits.txt"
find "$QD/dv/caliptra_bfm/axi" "$QD/scripts" -type f -print0 | sort -z | xargs -0 sha256sum > "$RUN/logs/qd-source-files.sha256"
sha256sum "$IVERILOG_BIN" "$VVP_BIN" > "$RUN/logs/simulator-sha256.txt"
"$IVERILOG_BIN" -V > "$RUN/logs/iverilog-version.txt" 2>&1 || true
export CALIPTRA_RTL="$RTL" IVERILOG_BIN VVP_BIN
export LD_LIBRARY_PATH="$BASE/deps/lib"
set +e
/usr/bin/time -v -o "$RUN/logs/resource.log" sh "$QD/dv/caliptra_bfm/axi/tests/run_caliptra_axi_complex_bfm.sh" > "$RUN/logs/runner.out" 2>&1
status=$?
set -e
if [ "$status" -eq 0 ]; then
  printf 'PASS\n' > "$RUN/logs/result.txt"
else
  printf 'FAIL_EXIT=%s\n' "$status" > "$RUN/logs/result.txt"
fi
exit "$status"
