#!/bin/bash
#SBATCH --job-name=m16-socifc-ahb
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G
#SBATCH --time=00:30:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-socifc-open-ahb-20261018-02/logs/%x-%j.out
set -euo pipefail
RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-socifc-open-ahb-20261018-02
SOURCE_ROOT="$RUN_DIR/source"
IVERILOG_BIN=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP_BIN=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT" status --porcelain
  "$IVERILOG_BIN" -V | head -n 1
  "$VVP_BIN" -V | head -n 1
  sha256sum "$IVERILOG_BIN" "$VVP_BIN"
  sha256sum "$RUN_DIR/source-snapshot.tar.gz"
  sha256sum "$SOURCE_ROOT/dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f"
} > "$RUN_DIR/job-meta.txt"
export IVERILOG_BIN VVP_BIN
export CALIPTRA_BFM_RUNTIME_LOG="$RUN_DIR/vvp.log"
export CALIPTRA_BFM_RUNTIME_HEARTBEAT_LOG="$RUN_DIR/progress.log"
export CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=600
set +e
/usr/bin/time -v -o "$RUN_DIR/runner.resource" python3 "$SOURCE_ROOT/evidence/caliptra-bfm-soc-ifc-hostpkgs-20261004/run_soc_ifc_env_compile.py" \
  --caliptra-root "$CALIPTRA_ROOT" \
  --iverilog "$IVERILOG_BIN" \
  --generated-environment-runtime \
  --generated-axi-user-init \
  --generated-ahb-mbox-payload \
  --generated-axi-user-reject-probe \
  > "$RUN_DIR/runner.log" 2>&1
runner_rc=$?
printf '%s\n' "$runner_rc" > "$RUN_DIR/runner.exit"
exit "$runner_rc"
