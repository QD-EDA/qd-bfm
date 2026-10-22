#!/usr/bin/env bash
#SBATCH --job-name=a2-m13b-hmac-gate
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G
#SBATCH --time=00:25:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m13b-109-icarus-20261017-gate01/logs/slurm-%j.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m13b-109-icarus-20261017-gate01
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
printf 'host=%s\njob_id=%s\nstart_utc=%s\ncommand=timeout 1200s run_generated_hmac_runtime.sh\n' "$(hostname)" "$SLURM_JOB_ID" "$(date -u +%FT%TZ)" > "$RUN/records/hmac_random_test/run-metadata.txt"
printf 'source_commit=%s\niverilog_source=9b5fad2afb4104caa816b257d5bccc40f01b8c66\ncaliptra_rtl=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e\n' "$(git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD)" >> "$RUN/records/hmac_random_test/run-metadata.txt"
sha256sum "$IVL/iverilog" "$IVL/vvp" > "$RUN/records/hmac_random_test/tool-binaries.sha256"
"$IVL/iverilog" -V > "$RUN/records/hmac_random_test/iverilog-version.txt" 2>&1
"$IVL/vvp" -V > "$RUN/records/hmac_random_test/vvp-version.txt" 2>&1
set +e
/usr/bin/time -v -o "$RUN/records/hmac_random_test/resource.txt" timeout --signal=TERM --kill-after=30s 1200s env \
  CALIPTRA_ROOT="$RTL" \
  IVERILOG_BIN="$IVL/iverilog" \
  VVP_BIN="$IVL/vvp" \
  CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=900 \
  /bin/sh "$RUN/source/dv/caliptra_bfm/uvmf_lite/tests/run_generated_hmac_runtime.sh" \
  > "$RUN/records/hmac_random_test/runner.log" 2>&1
rc=$?
set -e
printf 'runner_exit=%s\nend_utc=%s\n' "$rc" "$(date -u +%FT%TZ)" > "$RUN/records/hmac_random_test/result.txt"
cat "$RUN/records/hmac_random_test/result.txt"
exit "$rc"
