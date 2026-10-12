#!/usr/bin/env bash
#SBATCH --partition=verilog
#SBATCH --job-name=a2-545-clock
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/issue545-caliptra-clock-c339-vlt-20261012-01/logs/%x-%j.out
set -u
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/issue545-caliptra-clock-c339-vlt-20261012-01
SRC="$RUN/actual_caliptra_clock_generator.sv"
C339=/home/dsell/toolchains/iverilog-c339/iverilog/bin/iverilog
VLT=/usr/bin/verilator
mkdir -p "$RUN/build/verilator"
{
  printf 'host='; hostname
  printf 'uptime='; uptime
  printf 'caliptra_source_commit='; git -C /home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl rev-parse HEAD
  printf 'iverilog_source_commit='; git -C /home/dsell/toolchains/iverilog-c339/source/iverilog-uvm rev-parse HEAD
  printf 'source_has_timescale_or_timeunit='
  if grep -Eq 'timescale|timeunit|timeprecision' "$SRC"; then echo yes; else echo no; fi
} > "$RUN/host-and-provenance.txt"
sha256sum "$SRC" "$C339" "$VLT" > "$RUN/tool-and-source.sha256"
"$C339" -V > "$RUN/iverilog-version.txt" 2>&1
"$VLT" --version > "$RUN/verilator-version.txt" 2>&1
set +e
timeout --signal=TERM --kill-after=10s 120s "$C339" -g2017 -gassertions -s actual_caliptra_clock_generator "$SRC" -o "$RUN/build/actual.vvp" > "$RUN/iverilog.log" 2>&1
I_EXIT=$?
set -e
printf '%s\n' "$I_EXIT" > "$RUN/iverilog.exit"
if grep -Fq 'always process does not have any delay' "$RUN/iverilog.log"; then C339_MATCH=yes; else C339_MATCH=no; fi
set +e
timeout --signal=TERM --kill-after=10s 120s "$VLT" --binary --timing --build-jobs 1 --top-module actual_caliptra_clock_generator --Mdir "$RUN/build/verilator" "$SRC" > "$RUN/verilator-build.log" 2>&1
V_BUILD_EXIT=$?
set -e
printf '%s\n' "$V_BUILD_EXIT" > "$RUN/verilator-build.exit"
V_RUN_EXIT=not_run
if [ "$V_BUILD_EXIT" -eq 0 ]; then
  set +e
  timeout --signal=TERM --kill-after=10s 30s "$RUN/build/verilator/Vactual_caliptra_clock_generator" > "$RUN/verilator-run.log" 2>&1
  V_RUN_EXIT=$?
  set -e
  printf '%s\n' "$V_RUN_EXIT" > "$RUN/verilator-run.exit"
fi
if [ "$I_EXIT" -ne 0 ] && [ "$C339_MATCH" = yes ] && [ "$V_BUILD_EXIT" -eq 0 ] && [ "$V_RUN_EXIT" -eq 0 ] && grep -Fq 'PASS: Caliptra clock generator completed four transitions' "$RUN/verilator-run.log"; then
  printf 'result=PASS\nc339=expected_compile_rejection\nverilator=build_and_runtime_pass\n' > "$RUN/result.txt"
  exit 0
fi
printf 'result=FAIL\nc339_exit=%s\nc339_expected_diagnostic=%s\nverilator_build_exit=%s\nverilator_run_exit=%s\n' "$I_EXIT" "$C339_MATCH" "$V_BUILD_EXIT" "$V_RUN_EXIT" > "$RUN/result.txt"
exit 1
