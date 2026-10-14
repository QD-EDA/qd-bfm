#!/usr/bin/env bash
#SBATCH --job-name=a2-c339-finalize
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:30:00
#SBATCH --dependency=afterany:612
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/toolchain-recovery-20261012-01/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/toolchain-recovery-20261012-01/logs/%x-%j.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/toolchain-recovery-20261012-01
P=/home/dsell/toolchains/iverilog-c339
IVL_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0
IVL_SRC="$P/source/iverilog-uvm"
IVL="$P/iverilog"
RTL="$P/firmware/caliptra-rtl"
GCC="$P/firmware/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-gcc"
ENV="$P/deps"
JTAG_BUILD="$P/firmware/jtagdpi"

exec > >(tee -a "$RUN/logs/finalize.log") 2>&1
printf 'started=%s\nhost=%s\nslurm_job_id=%s\n' "$(date -Is)" "$(hostname)" "$SLURM_JOB_ID"
test "$(git -C "$IVL_SRC" rev-parse HEAD)" = "$IVL_SHA"
test -z "$(git -C "$IVL_SRC" status --porcelain --untracked-files=all)"
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"
test -x "$IVL/bin/iverilog" && test -x "$IVL/bin/vvp" && test -x "$IVL/bin/iverilog-vpi"
test -x "$GCC" && test -x "$ENV/bin/python3.12"
"$ENV/bin/python3.12" -c 'import cryptography, yaml'
test -f /usr/include/mbedtls/version.h
test -f "$P/downloads/xpack-riscv-none-elf-gcc-15.2.0-1-linux-x64.tar.gz"
test -f "$P/downloads/Python-3.12.15.tgz"

mkdir -p "$JTAG_BUILD"
cd "$JTAG_BUILD"
"$IVL/bin/iverilog-vpi" \
  -I"$RTL/src/integration/test_suites/libs/tcp_server" \
  "$RTL/src/integration/test_suites/libs/jtagdpi/jtagdpi.c" \
  "$RTL/src/integration/test_suites/libs/tcp_server/tcp_server.c" \
  > "$JTAG_BUILD/build.log" 2>&1
test -s "$JTAG_BUILD/jtagdpi.vpi"

"$IVL/bin/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1
"$IVL/bin/vvp" -V > "$RUN/vvp-version.txt" 2>&1
"$ENV/bin/python3.12" --version > "$RUN/python-version.txt" 2>&1
"$GCC" --version > "$RUN/riscv-gcc-version.txt" 2>&1
openssl version > "$RUN/openssl-version.txt"

{
  printf 'completed=%s\nhost=%s\nslurm_job_id=%s\n' "$(date -Is)" "$(hostname)" "$SLURM_JOB_ID"
  printf 'original_rebuild_job=609\noriginal_rebuild_exit_code=1:0\noriginal_rebuild_stop=JTAG artifact was generated outside its protected output directory\n'
  printf 'prior_finalize_job=612\nprior_finalize_exit_code=1:0\nprior_finalize_stop=version.h has no VERSION_STRING macro; package version is recorded below\n'
  printf 'iverilog_source_commit=%s\ncaliptra_rtl_commit=%s\nadams_bridge_commit=%s\n' "$IVL_SHA" "$RTL_SHA" "$ADAMS_SHA"
  printf 'source_clean=yes\n'
  printf 'old_iverilog_sha256=%s\nold_vvp_sha256=%s\n' \
    '737049ca0342dd7e258d0d021f4b3b6aa750dcb6d79a6cd9871988954da898b2' \
    '5f0bc4d0b98eb7438c8d0446d62fcf59c68a24e3f9d1041ac69e5d439de1f24a'
  sha256sum "$IVL/bin/iverilog" "$IVL/bin/vvp" "$JTAG_BUILD/jtagdpi.vpi" \
    "$P/downloads/xpack-riscv-none-elf-gcc-15.2.0-1-linux-x64.tar.gz" \
    "$P/downloads/Python-3.12.15.tgz"
  printf '\nIcarus version:\n'; sed -n '1,2p' "$RUN/iverilog-version.txt"
  printf '\nVVP version:\n'; sed -n '1,2p' "$RUN/vvp-version.txt"
  printf '\nRISC-V GCC:\n'; sed -n '1p' "$RUN/riscv-gcc-version.txt"
  printf '\nPython:\n'; cat "$RUN/python-version.txt"
  "$ENV/bin/python3.12" -m pip freeze
  printf '\nOpenSSL:\n'; cat "$RUN/openssl-version.txt"
  printf '\nRelevant system packages:\n'
  dpkg-query -W -f='${binary:Package}=${Version}\n' libmbedtls-dev libssl-dev libz3-dev libffi-dev
} | tee "$P/BUILD-MANIFEST.txt"
