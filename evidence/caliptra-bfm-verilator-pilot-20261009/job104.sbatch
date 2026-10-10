#!/bin/bash
#SBATCH --job-name=caliptra-checker-verilator-last
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-checker-verilator-pilot-e88c880-20261009-05
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-checker-verilator-pilot-e88c880-20261009-05/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/axi-checker-verilator-pilot-e88c880-20261009-05
QD="$RUN/source/qd-bfm"
VERILATOR_BIN=/usr/bin/verilator
QD_SHA=e88c8809b01c59ff0147f9232124444ce820c7f0
(cd "$RUN/source" && sha256sum --check qd-bfm.tar.gz.sha256)
(cd "$QD/dv/caliptra_bfm/axi/tests" && sha256sum --check "$RUN/source/qd-bfm-runner.sha256")
mkdir -p "$RUN/logs" "$RUN/build"
printf 'QD=%s\n' "$QD_SHA" > "$RUN/logs/source-commits.txt"
find "$QD/dv/caliptra_bfm/axi" "$QD/scripts" -type f -print0 | sort -z | xargs -0 sha256sum > "$RUN/logs/qd-source-files.sha256"
verilator --version > "$RUN/logs/verilator-version.txt" 2>&1
sha256sum "$(readlink -f "$VERILATOR_BIN")" "$(readlink -f /usr/bin/g++)" > "$RUN/logs/tool-hashes.txt"
g++ --version > "$RUN/logs/g++-version.txt" 2>&1 || true
export TMPDIR="$RUN/build" VERILATOR_BIN
export CALIPTRA_BFM_MAX_PROCESS_BYTES=4000000000
export CALIPTRA_BFM_MIN_AVAILABLE_BYTES=6000000000
set +e
python3 "$QD/scripts/run_with_memory_pressure_guard.py" \
  --max-process-bytes "$CALIPTRA_BFM_MAX_PROCESS_BYTES" \
  --min-available-bytes "$CALIPTRA_BFM_MIN_AVAILABLE_BYTES" \
  --timeout-seconds 600 --log "$RUN/logs/guarded-output.log" -- \
  env CALIPTRA_BFM_MEMORY_GUARD_CHILD=1 sh "$QD/dv/caliptra_bfm/axi/tests/run_verilator_caliptra_checker.sh" \
  > "$RUN/logs/guard-status.log" 2>&1
status=$?
set -e
if [ "$status" -eq 0 ]; then
  printf 'PASS\n' > "$RUN/logs/result.txt"
else
  printf 'FAIL_EXIT=%s\n' "$status" > "$RUN/logs/result.txt"
fi
exit "$status"
