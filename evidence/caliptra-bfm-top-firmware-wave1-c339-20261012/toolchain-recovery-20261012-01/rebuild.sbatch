#!/usr/bin/env bash
#SBATCH --job-name=a2-c339-rebuild
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/toolchain-recovery-20261012-01/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/toolchain-recovery-20261012-01/logs/%x-%j.out

set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/toolchain-recovery-20261012-01
P=/home/dsell/toolchains/iverilog-c339
IVL_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
RTL_SHA=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
ADAMS_SHA=b77e3d899e828d626cfc2a0d26a6b5704cc121e0
GCC_VERSION=15.2.0-1
PYTHON_VERSION=3.12.15
IVL_SRC="$P/source/iverilog-uvm"
BUILD="$P/build/iverilog-$SLURM_JOB_ID"
IVL="$P/iverilog"
RTL="$P/firmware/caliptra-rtl"
GCC="$P/firmware/xpack-riscv-none-elf-gcc-$GCC_VERSION"
PYTHON="$P/python-$PYTHON_VERSION"
ENV="$P/deps"
JTAG_BUILD="$P/firmware/jtagdpi"

mkdir -p "$RUN/logs" "$P/source" "$P/build" "$P/firmware" "$P/downloads"
exec > >(tee -a "$RUN/logs/rebuild.log") 2>&1

printf 'started=%s\nhost=%s\nslurm_job_id=%s\n' "$(date -Is)" "$(hostname)" "$SLURM_JOB_ID"
sed -n '1,6p' /etc/os-release
gcc --version | sed -n '1p'
g++ --version | sed -n '1p'
autoconf --version | sed -n '1p'
bison --version | sed -n '1p'
flex --version | sed -n '1p'

if [ ! -d "$IVL_SRC/.git" ]; then
  git clone https://github.com/dsellerbrock/iverilog-uvm.git "$IVL_SRC"
fi
git -C "$IVL_SRC" fetch origin "$IVL_SHA"
git -C "$IVL_SRC" checkout --detach "$IVL_SHA"
test "$(git -C "$IVL_SRC" rev-parse HEAD)" = "$IVL_SHA"
test -z "$(git -C "$IVL_SRC" status --porcelain --untracked-files=all)"
mkdir -p "$BUILD"
git -C "$IVL_SRC" archive "$IVL_SHA" | tar -xf - -C "$BUILD"
(cd "$BUILD" && sh ./autoconf.sh && ./configure --prefix="$IVL" && make -j2 && make install)
test -x "$IVL/bin/iverilog" && test -x "$IVL/bin/vvp" && test -x "$IVL/bin/iverilog-vpi"

if [ ! -d "$RTL/.git" ]; then
  git clone https://github.com/chipsalliance/caliptra-rtl.git "$RTL"
fi
git -C "$RTL" fetch origin "$RTL_SHA"
git -C "$RTL" checkout --detach "$RTL_SHA"
git -C "$RTL" submodule update --init --recursive
test "$(git -C "$RTL" rev-parse HEAD)" = "$RTL_SHA"
test "$(git -C "$RTL/submodules/adams-bridge" rev-parse HEAD)" = "$ADAMS_SHA"
test -z "$(git -C "$RTL" status --porcelain --untracked-files=all)"

GCC_ARCHIVE="$P/downloads/xpack-riscv-none-elf-gcc-$GCC_VERSION-linux-x64.tar.gz"
if [ ! -f "$GCC_ARCHIVE" ]; then
  curl -fL --retry 3 --connect-timeout 20 \
    "https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v$GCC_VERSION/xpack-riscv-none-elf-gcc-$GCC_VERSION-linux-x64.tar.gz" \
    -o "$GCC_ARCHIVE"
fi
if [ ! -x "$GCC/bin/riscv-none-elf-gcc" ]; then
  mkdir -p "$GCC"
  tar -xzf "$GCC_ARCHIVE" --strip-components=1 -C "$GCC"
fi
"$GCC/bin/riscv-none-elf-gcc" --version | head -n 1

PY_ARCHIVE="$P/downloads/Python-$PYTHON_VERSION.tgz"
if [ ! -f "$PY_ARCHIVE" ]; then
  curl -fL --retry 3 --connect-timeout 20 \
    "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz" \
    -o "$PY_ARCHIVE"
fi
if [ ! -x "$PYTHON/bin/python3.12" ]; then
  PY_SRC="$P/source/Python-$PYTHON_VERSION"
  mkdir -p "$PY_SRC"
  tar -xzf "$PY_ARCHIVE" --strip-components=1 -C "$PY_SRC"
  (cd "$PY_SRC" && ./configure --prefix="$PYTHON" --with-ensurepip=install && make -j2 && make install)
fi
if [ ! -x "$ENV/bin/python3.12" ]; then
  "$PYTHON/bin/python3.12" -m venv "$ENV"
  "$ENV/bin/python3.12" -m pip install --only-binary=:all: 'cryptography==46.0.5' 'PyYAML==6.0.3'
fi

mkdir -p "$ENV/include" "$ENV/lib" "$JTAG_BUILD"
ln -sfn /usr/include/mbedtls "$ENV/include/mbedtls"
for lib in mbedtls mbedx509 mbedcrypto; do
  ln -sfn "/usr/lib/x86_64-linux-gnu/lib$lib.so" "$ENV/lib/lib$lib.so"
done
"$IVL/bin/iverilog-vpi" \
  -I"$RTL/src/integration/test_suites/libs/tcp_server" \
  "$RTL/src/integration/test_suites/libs/jtagdpi/jtagdpi.c" \
  "$RTL/src/integration/test_suites/libs/tcp_server/tcp_server.c" \
  > "$JTAG_BUILD/build.log" 2>&1
test -f "$JTAG_BUILD/jtagdpi.vpi"

{
  printf 'completed=%s\nhost=%s\nslurm_job_id=%s\n' "$(date -Is)" "$(hostname)" "$SLURM_JOB_ID"
  printf 'iverilog_source_commit=%s\ncaliptra_rtl_commit=%s\nadams_bridge_commit=%s\n' "$IVL_SHA" "$RTL_SHA" "$ADAMS_SHA"
  printf 'old_iverilog_sha256=%s\nold_vvp_sha256=%s\n' \
    '737049ca0342dd7e258d0d021f4b3b6aa750dcb6d79a6cd9871988954da898b2' \
    '5f0bc4d0b98eb7438c8d0446d62fcf59c68a24e3f9d1041ac69e5d439de1f24a'
  sha256sum "$IVL/bin/iverilog" "$IVL/bin/vvp" "$JTAG_BUILD/jtagdpi.vpi" "$GCC_ARCHIVE" "$PY_ARCHIVE"
  "$IVL/bin/iverilog" -V 2>&1 | sed -n '1,2p'
  "$IVL/bin/vvp" -V 2>&1 | sed -n '1,2p'
  "$GCC/bin/riscv-none-elf-gcc" --version | sed -n '1p'
  "$ENV/bin/python3.12" --version
  "$ENV/bin/python3.12" -m pip freeze
  grep -m1 '^#define MBEDTLS_VERSION_STRING' /usr/include/mbedtls/version.h
  git -C "$IVL_SRC" status --porcelain --untracked-files=all
  git -C "$RTL" status --porcelain --untracked-files=all
} | tee "$P/BUILD-MANIFEST.txt"

printf 'jtagdpi_sha256=' >> "$P/BUILD-MANIFEST.txt"
sha256sum "$JTAG_BUILD/jtagdpi.vpi" | cut -d' ' -f1 >> "$P/BUILD-MANIFEST.txt"
