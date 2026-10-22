#!/bin/bash
#SBATCH --job-name=a2-m16-ahb32
#SBATCH -p verilog
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=1G
#SBATCH --time=00:15:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-qvip-env-32-20261018-01/logs/slurm-%j.out

set -Eeuo pipefail
run_root=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-ahb-qvip-env-32-20261018-01/source
cd "$run_root"
export IVERILOG_BIN=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
export VVP_BIN=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
export AHB_PROFILE=32
printf 'HOST=%s\n' "$(hostname)"
date -u +"START_UTC=%Y-%m-%dT%H:%M:%SZ"
set +e
python3 - <<'PY'
import os
import signal
import subprocess
import sys

proc = subprocess.Popen(
    ["sh", "dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh"],
    start_new_session=True,
)
try:
    status = proc.wait(timeout=600)
except subprocess.TimeoutExpired:
    try:
        os.killpg(proc.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        status = proc.wait(timeout=10)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        status = proc.wait()
    sys.exit(124)
sys.exit(status)
PY
rc=$?
set -e
date -u +"END_UTC=%Y-%m-%dT%H:%M:%SZ"
exit "$rc"
