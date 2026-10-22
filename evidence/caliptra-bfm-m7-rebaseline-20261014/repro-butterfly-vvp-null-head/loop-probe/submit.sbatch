#!/usr/bin/env bash
#SBATCH --job-name=bfm-m7-vvp-loop-mre
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-butterfly-loop-probe-20261014
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-butterfly-loop-probe-20261014/logs/%x-%j.out
set -Eeuo pipefail
ulimit -c 0
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-butterfly-loop-probe-20261014
C339=/home/dsell/toolchains/iverilog-c339/iverilog/bin
MAIN=/home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf/install/bin
for variant in loop-static-init loop-auto-task loop-assignment; do
  for version in c339 main; do
    if [[ $version == c339 ]]; then IVL=$C339/iverilog; VVP=$C339/vvp; export LD_LIBRARY_PATH=/home/dsell/toolchains/iverilog-c339/iverilog/lib; else IVL=$MAIN/iverilog; VVP=$MAIN/vvp; export LD_LIBRARY_PATH=/home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf/install/lib; fi
    name=$version-$variant
    "$IVL" -V > "$RUN/$name-iverilog.txt" 2>&1
    set +e
    "$IVL" -g2017 -s tb "$RUN/source/$variant.sv" -o "$RUN/build/$name.vvp" > "$RUN/$name-compile.log" 2>&1
    compile_rc=$?
    sim_rc=NOT_RUN
    if [[ $compile_rc == 0 ]]; then
      /usr/bin/time -v -o "$RUN/$name-resource.log" timeout --signal=INT --kill-after=2s 60s "$VVP" -n "$RUN/build/$name.vvp" > "$RUN/$name-sim.log" 2>&1
      sim_rc=$?
    fi
    set -e
    printf 'variant=%s\nversion=%s\ncompile_exit=%s\nsim_exit=%s\n' "$variant" "$version" "$compile_rc" "$sim_rc" > "$RUN/$name-status.txt"
    printf '%s %s compile=%s sim=%s\n' "$variant" "$version" "$compile_rc" "$sim_rc"
  done
done
bytes=$(du -cb "$RUN"/build/*.vvp 2>/dev/null | awk 'END {print $1+0}')
rm -f "$RUN"/build/*.vvp
printf 'compiled_vvp_bytes_removed=%s\n' "$bytes" > "$RUN/cleanup.txt"
