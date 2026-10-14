#!/usr/bin/env bash
#SBATCH --job-name=a2-openssl-preflight
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:30:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-04/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-04/logs/openssl-preflight-%j.out

set -Eeuo pipefail
ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-04
QD="$ROOT/source/qd-bfm"
RTL=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
BUILT=/home/dsell/toolchains/iverilog-c339
ENV="$BUILT/deps"
OPENSSL="$BUILT/openssl"
GCC_DIR=/home/dsell/toolchains/iverilog-c339/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin
mkdir -p "$ROOT/preflight"
export PATH="$ENV/bin:$BUILT/iverilog/bin:$GCC_DIR:$OPENSSL/bin:$PATH"
export LD_LIBRARY_PATH="$BUILT/iverilog/lib:$ENV/lib:$OPENSSL/lib"
export CALIPTRA_MBEDTLS_ROOT="$ENV"
python3.12 - "$QD" "$RTL" "$ROOT/preflight/native-vectors" <<'PY'
import importlib.util
import os
import sys
from pathlib import Path

qd, rtl, output = map(Path, sys.argv[1:])
runner_path = qd / "dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.py"
spec = importlib.util.spec_from_file_location("caliptra_runner", runner_path)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)
output.mkdir(parents=True)
files, hashes, commands, tools = runner.prepare_native_vectors(rtl, output, os.environ.copy())
print(f"runner={runner_path}")
print(f"openssl={tools['openssl']}")
print(f"openssl_root={Path(tools['openssl']).resolve().parent.parent}")
for name, digest in sorted(hashes.items()):
    print(f"{name}={digest}")
print(f"commands_completed={len(commands)}")
PY
