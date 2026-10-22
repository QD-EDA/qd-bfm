#!/bin/bash
#SBATCH --job-name=m16-kv-pinned-gate
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:30:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-kv-current-pinned-20261018-01/logs/%x-%j.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-kv-current-pinned-20261018-01
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
mkdir -p "$SOURCE" "$RUN/prepared-overlay"
tar -xzf "$RUN/source.tar.gz" -C "$SOURCE"
{
  hostname
  date -u +%FT%TZ
  python3 --version
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  git -C /home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/source rev-parse HEAD
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  sha256sum "$RUN/source.tar.gz" "$IVL" "$VVP" \
    "$SOURCE/docs/conformance/release_overlays/caliptra/keyvault_generated_bfm_iverilog_overlay.py" \
    "$SOURCE/evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.py" \
    "$CALIPTRA_ROOT/src/keyvault/uvmf_kv/config/uvmf_kv.vf" \
    "$CALIPTRA_ROOT/src/keyvault/uvmf_kv/uvmf_template_output/verification_ip/environment_packages/kv_env_pkg/src/kv_env_configuration.svh"
} > "$RUN/job-meta.txt"
find "$SOURCE" -type f -print0 | sort -z | xargs -0 sha256sum > "$RUN/source.sha256"
python3 "$SOURCE/docs/conformance/release_overlays/caliptra/keyvault_generated_bfm_iverilog_overlay.py" \
  "$CALIPTRA_ROOT/src/keyvault/uvmf_kv/uvmf_template_output" "$RUN/prepared-overlay" --ahb-burst-smoke \
  > "$RUN/overlay-generation.log" 2>&1
find "$RUN/prepared-overlay" -type f -print0 | sort -z | xargs -0 sha256sum > "$RUN/prepared-overlay.sha256"
set +e
/usr/bin/time -v -o "$RUN/runner.resource" timeout --signal=TERM --kill-after=5s 900s \
  env CALIPTRA_ROOT="$CALIPTRA_ROOT" IVERILOG_BIN="$IVL" VVP_BIN="$VVP" \
    CALIPTRA_BFM_RUNTIME_TIMEOUT_SECONDS=600 \
    CALIPTRA_BFM_SUMMARY_LOG="$RUN/summary.log" \
    CALIPTRA_UVM_TRACE_LOG="$RUN/sim.log" \
    python3 "$SOURCE/evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.py" \
      --runtime-ahb-burst-smoke > "$RUN/runner.out" 2>&1
runner_exit=$?
set -e
cat > "$RUN/result.txt" <<RESULT
runner_exit_code=$runner_exit
RESULT
find "$RUN" -type f ! -name run-files.sha256 -print0 | sort -z | xargs -0 sha256sum > "$RUN/run-files.sha256"
cat "$RUN/result.txt"
