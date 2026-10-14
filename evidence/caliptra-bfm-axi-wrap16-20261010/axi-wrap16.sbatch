#!/bin/bash
#SBATCH --job-name=axi-wrap16b
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=256M
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-wrap16-04051d8b-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-wrap16-04051d8b-20261010-01/logs/%x-%j.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-wrap16-04051d8b-20261010-01
BUILT=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
QD=$RUN/source/qd-bfm
ENV=$BUILT/deps
IVERILOG=$BUILT/toolchain/iverilog/bin
export PATH=$ENV/bin:$IVERILOG:$PATH
export LD_LIBRARY_PATH=$BUILT/toolchain/iverilog/lib:$ENV/lib
export IVERILOG_BIN=$IVERILOG/iverilog
export VVP_BIN=$IVERILOG/vvp
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=120
sha256sum "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_subordinate.sv" | tee "$RUN/testbench.sha256"
"$IVERILOG/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1
"$IVERILOG/vvp" -V > "$RUN/vvp-version.txt" 2>&1
sha256sum "$IVERILOG/iverilog" "$IVERILOG/vvp" > "$RUN/simulator-sha256.txt"
/usr/bin/time -v -o "$RUN/logs/resource.log" sh "$QD/dv/caliptra_bfm/axi/tests/run_subordinate.sh" > "$RUN/logs/subordinate.log" 2>&1
grep -Fq 'PASS: AXI memory subordinate' "$RUN/logs/subordinate.log"
echo AXI_16_BEAT_WRAP_ROUNDTRIP=PASS
