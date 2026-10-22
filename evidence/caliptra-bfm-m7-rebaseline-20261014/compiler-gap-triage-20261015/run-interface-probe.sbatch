#!/usr/bin/env bash
#SBATCH --job-name=a2-ivl-interface-mre
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/ivl-interface-probe-20261015-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/ivl-interface-probe-20261015-01/logs/%x-%j.out

set -Eeuo pipefail
ulimit -c 0
run=/home/dsell/slurm-runs/caliptra-bfm/a2/ivl-interface-probe-20261015-01
src="$run/input/interface-variable-assign.sv"
mkdir -p "$run/results" "$run/logs" "$run/build"

run_iverilog() {
  local name=$1 compiler=$2 runtime=$3 result="$run/results/$1"
  mkdir -p "$result"
  "$compiler" -V >"$result/version.log" 2>&1 || true
  sha256sum "$compiler" "$runtime" >"$result/binaries.sha256"
  set +e
  /usr/bin/time -v -o "$result/compile.resource" timeout --signal=TERM --kill-after=2s 30s \
    "$compiler" -g2017 -s interface_variable_assign "$src" -o "$run/build/$name.vvp" \
    >"$result/compile.log" 2>&1
  local compile_rc=$?
  set -e
  printf 'compile_exit=%d\n' "$compile_rc" >"$result/status.txt"
  if [ "$compile_rc" -ne 0 ]; then return 0; fi
  set +e
  /usr/bin/time -v -o "$result/sim.resource" timeout --signal=TERM --kill-after=2s 10s \
    "$runtime" "$run/build/$name.vvp" >"$result/sim.log" 2>&1
  local sim_rc=$?
  set -e
  printf 'sim_exit=%d\n' "$sim_rc" >>"$result/status.txt"
}

run_iverilog main \
  /home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf/install/bin/iverilog \
  /home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf/install/bin/vvp
run_iverilog c339 \
  /home/dsell/toolchains/iverilog-c339/iverilog/bin/iverilog \
  /home/dsell/toolchains/iverilog-c339/iverilog/bin/vvp

verilator=/home/dsell/toolchains/verilator-5.052/bin/verilator
verilator_result="$run/results/verilator-5.052"
mkdir -p "$verilator_result"
"$verilator" --version >"$verilator_result/version.log" 2>&1
sha256sum "$verilator" >"$verilator_result/binary.sha256"
set +e
/usr/bin/time -v -o "$verilator_result/compile.resource" timeout --signal=TERM --kill-after=2s 300s \
  "$verilator" --binary --timing -Wno-fatal --top-module interface_variable_assign \
  --Mdir "$run/build/verilator" "$src" >"$verilator_result/compile.log" 2>&1
compile_rc=$?
set -e
printf 'compile_exit=%d\n' "$compile_rc" >"$verilator_result/status.txt"
if [ "$compile_rc" -eq 0 ]; then
  set +e
  /usr/bin/time -v -o "$verilator_result/sim.resource" timeout --signal=TERM --kill-after=2s 10s \
    "$run/build/verilator/Vinterface_variable_assign" >"$verilator_result/sim.log" 2>&1
  sim_rc=$?
  set -e
  printf 'sim_exit=%d\n' "$sim_rc" >>"$verilator_result/status.txt"
fi
