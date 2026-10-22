#!/usr/bin/env bash
#SBATCH --job-name=bfm-m13-539-probe
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-issue539-current-main-20261017-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-issue539-current-main-20261017-01/logs/%x-%j.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13-issue539-current-main-20261017-01
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install
export LD_LIBRARY_PATH="$IVL/lib:$IVL/lib64:/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
mkdir -p "$RUN/build" "$RUN/results"

{
  printf 'host=%s\nslurm_job_id=%s\niverilog_source=9b5fad2afb4104caa816b257d5bccc40f01b8c66\n' \
    "$(hostname)" "$SLURM_JOB_ID"
  "$IVL/bin/iverilog" -V
  "$IVL/bin/vvp" -V
} > "$RUN/results/provenance.txt" 2>&1
sha256sum "$RUN/self-contained.sv" "$IVL/bin/iverilog" "$IVL/bin/vvp" > "$RUN/results/hashes.txt"

set +e
/usr/bin/time -v -o "$RUN/results/compile.resource" timeout --signal=TERM --kill-after=30s 600s \
  "$IVL/bin/iverilog" -g2017 -s tb -o "$RUN/build/repro.vvp" "$RUN/self-contained.sv" \
  > "$RUN/results/compile.log" 2>&1
compile_rc=$?
sim_rc=NOT_RUN
if [[ $compile_rc == 0 ]]; then
  /usr/bin/time -v -o "$RUN/results/sim.resource" timeout --signal=TERM --kill-after=30s 600s \
    "$IVL/bin/vvp" -n "$RUN/build/repro.vvp" > "$RUN/results/sim.log" 2>&1
  sim_rc=$?
fi
set -e
result=NO_RESULT
if [[ $compile_rc == 0 && $sim_rc == 0 ]] && grep -Fq 'RESULT bad=4002 bad_en=01' "$RUN/results/sim.log"; then
  result=FIXED_ON_CURRENT_MAIN
elif [[ $compile_rc == 0 && $sim_rc == 0 ]] && grep -Fq 'RESULT bad=0002 bad_en=00' "$RUN/results/sim.log"; then
  result=REPRODUCED_ON_CURRENT_MAIN
elif [[ $compile_rc == 124 || $sim_rc == 124 ]]; then
  result=TIMEOUT
fi
printf 'compile_exit=%s\nsim_exit=%s\nresult=%s\n' "$compile_rc" "$sim_rc" "$result" > "$RUN/results/result.txt"
cat "$RUN/results/result.txt"
