#!/usr/bin/env bash
#SBATCH --job-name=bfm-m7-vvp-mre
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-butterfly-vvp-mre-20261014
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-butterfly-vvp-mre-20261014/logs/%x-%j.out

set -Eeuo pipefail
ulimit -c 0
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-butterfly-vvp-mre-20261014
{ printf 'host=%s\nslurm_job_id=%s\n' "$(hostname)" "$SLURM_JOB_ID"; uname -a; date -Is; } > "$RUN/host.txt"
C339=/home/dsell/toolchains/iverilog-c339/iverilog/bin
MAIN=/home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf/install/bin
MAIN_LIB=/home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf/install/lib
cp "$RUN/fork-join.sv" "$RUN/source.sv"
sha256sum "$RUN/source.sv" > "$RUN/source.sha256"
for version in c339 main; do
  if [[ $version == c339 ]]; then IVL=$C339/iverilog; VVP=$C339/vvp; export LD_LIBRARY_PATH=/home/dsell/toolchains/iverilog-c339/iverilog/lib; else IVL=$MAIN/iverilog; VVP=$MAIN/vvp; export LD_LIBRARY_PATH=$MAIN_LIB; fi
  "$IVL" -V > "$RUN/$version-iverilog-version.txt" 2>&1
  "$VVP" -V > "$RUN/$version-vvp-version.txt" 2>&1
  sha256sum "$IVL" "$VVP" > "$RUN/$version-binary-sha256.txt"
  "$IVL" -g2012 -s tb "$RUN/source.sv" -o "$RUN/$version.vvp" > "$RUN/$version-compile.log" 2>&1
  set +e
  /usr/bin/time -v -o "$RUN/$version-resource.log" timeout --signal=INT --kill-after=2s 60s "$VVP" -n "$RUN/$version.vvp" > "$RUN/$version-sim.log" 2>&1
  rc=$?
  set -e
  printf 'version=%s\nsim_exit=%s\n' "$version" "$rc" > "$RUN/$version-status.txt"
done
