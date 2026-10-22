#!/usr/bin/env bash
#SBATCH --job-name=a2-xsim-probe
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:05:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-pr7176-20261015-01/fourstate-probe-timescale
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-pr7176-20261015-01/logs/a2-xsim-probe-%j.out

set -u
run=/home/dsell/slurm-runs/caliptra-bfm/a2/m8-verilator-pr7176-20261015-01/fourstate-probe-timescale
verilator=/home/dsell/toolchains/verilator-pr7176-27d3c20/bin/verilator
cd "$run"

set +e
/usr/bin/time -v -o "$run/compile.resource" "$verilator" --x-sim --timing --binary --Wno-fatal \
    --top-module fourstate_xsim_timescale_probe fourstate-xsim-timescale-probe.sv > "$run/compile.log" 2>&1
compile_exit=$?
if [ "$compile_exit" -eq 0 ]; then
    timeout --signal=TERM --kill-after=2s 20s "$run/obj_dir/Vfourstate_xsim_timescale_probe" > "$run/sim.log" 2>&1
    sim_exit=$?
else
    sim_exit=NA
fi
printf 'compile_exit=%s\nsim_exit=%s\n' "$compile_exit" "$sim_exit" > "$run/result.txt"
exit 0
