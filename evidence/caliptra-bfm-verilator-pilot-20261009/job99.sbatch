#!/bin/bash
#SBATCH --job-name=caliptra-verilator-pilot-final
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5500M
#SBATCH --time=00:20:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-verilator-pilot-c8ce915-20261009-05
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-verilator-pilot-c8ce915-20261009-05/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-complex-verilator-pilot-c8ce915-20261009-05
QD="$RUN/source/qd-bfm"
RTL=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/source/caliptra-rtl
VERILATOR_BIN=/usr/bin/verilator
QD_SHA=e88c8809b01c59ff0147f9232124444ce820c7f0
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
(cd "$RUN/source" && sha256sum --check qd-bfm.tar.gz.sha256)
(cd "$QD/dv/caliptra_bfm/axi/tests" && sha256sum --check "$RUN/source/qd-bfm-runner.sha256")
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
mkdir -p "$RUN/logs" "$RUN/build"
printf 'QD=%s\nCaliptra=%s\n' "$QD_SHA" "$RTL_SHA" > "$RUN/logs/source-commits.txt"
find "$QD/dv/caliptra_bfm/axi" "$QD/scripts" -type f -print0 | sort -z | xargs -0 sha256sum > "$RUN/logs/qd-source-files.sha256"
verilator --version > "$RUN/logs/verilator-version.txt" 2>&1
sha256sum "$(readlink -f "$VERILATOR_BIN")" "$(readlink -f /usr/bin/g++)" > "$RUN/logs/tool-hashes.txt"
g++ --version > "$RUN/logs/g++-version.txt" 2>&1 || true
export TMPDIR="$RUN/build"
export CALIPTRA_RTL="$RTL" VERILATOR_BIN
export CALIPTRA_BFM_MAX_PROCESS_BYTES=5200000000
export CALIPTRA_BFM_MIN_AVAILABLE_BYTES=6000000000
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=600
set +e
/usr/bin/time -v -o "$RUN/logs/resource.log" sh "$QD/dv/caliptra_bfm/axi/tests/run_verilator_caliptra_axi_complex_bfm.sh" > "$RUN/logs/runner.out" 2>&1
status=$?
set -e
if [ "$status" -eq 0 ]; then
  printf 'PASS\n' > "$RUN/logs/result.txt"
else
  printf 'FAIL_EXIT=%s\n' "$status" > "$RUN/logs/result.txt"
fi
exit "$status"
