#!/usr/bin/env bash
#SBATCH --job-name=bfm-m7-iverilog-main
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-iverilog-uvm-3335fe7-20261014/logs/%x-%j.out

set -Eeuo pipefail

SHA=3335fe7ec1495956c8adc5788e9a53b0f1756ecf
ROOT=/home/dsell/toolchains/iverilog-uvm-$SHA
SRC=$ROOT/source
PREFIX=$ROOT/install
LOGROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-iverilog-uvm-3335fe7-20261014/logs

mkdir -p "$LOGROOT"
test ! -e "$ROOT"
mkdir -p "$ROOT"
exec > "$LOGROOT/build-${SLURM_JOB_ID}.log" 2>&1
record_exit() {
  code=$?
  trap - EXIT
  if [[ -f "$ROOT/build-provenance.txt" ]]; then
    printf 'finished=%s\nexit_code=%s\nstatus=%s\n' \
      "$(date -Is)" "$code" "$([[ $code -eq 0 ]] && echo BUILT || echo FAILED)" \
      >> "$ROOT/build-provenance.txt"
  fi
  exit "$code"
}
trap record_exit EXIT

printf 'host=%s\nstarted=%s\nslurm_job_id=%s\nmain_sha=%s\n' \
  "$(hostname)" "$(date -Is)" "$SLURM_JOB_ID" "$SHA" | tee "$ROOT/build-provenance.txt"
uname -a | tee -a "$ROOT/build-provenance.txt"
git --version | tee -a "$ROOT/build-provenance.txt"
g++ --version | sed -n '1p' | tee -a "$ROOT/build-provenance.txt"
bison --version | sed -n '1p' | tee -a "$ROOT/build-provenance.txt"
flex --version | tee -a "$ROOT/build-provenance.txt"
gperf --version | sed -n '1p' | tee -a "$ROOT/build-provenance.txt"
grep -E '^#define Z3_(MAJOR|MINOR|FULL)_VERSION ' /usr/include/z3_version.h | tee -a "$ROOT/build-provenance.txt"
sha256sum /usr/lib/x86_64-linux-gnu/libz3.so /usr/lib/x86_64-linux-gnu/libffi.so | tee -a "$ROOT/build-provenance.txt"

git clone https://github.com/dsellerbrock/iverilog-uvm.git "$SRC"
git -C "$SRC" checkout --detach "$SHA"
git -C "$SRC" submodule update --init uvm-core
test "$(git -C "$SRC" rev-parse HEAD)" = "$SHA"
git -C "$SRC" status --short --branch | tee -a "$ROOT/build-provenance.txt"
git -C "$SRC/uvm-core" rev-parse HEAD | tee -a "$ROOT/build-provenance.txt"

cd "$SRC"
sh autoconf.sh
CPPFLAGS="-I/usr/include/x86_64-linux-gnu" \
LDFLAGS="-L/usr/lib/x86_64-linux-gnu" \
./configure --prefix="$PREFIX" --enable-libveriuser
/usr/bin/time -v -o "$LOGROOT/make-resource.log" make -j1
make install

"$PREFIX/bin/iverilog" -V 2>&1 | tee "$ROOT/iverilog-version.txt"
"$PREFIX/bin/vvp" -V 2>&1 | tee "$ROOT/vvp-version.txt"
sha256sum "$PREFIX/bin/iverilog" "$PREFIX/bin/vvp" "$PREFIX/bin/iverilog-vpi" \
  | tee "$ROOT/binary-sha256.txt"
ldd "$PREFIX/bin/iverilog" | tee "$ROOT/iverilog-ldd.txt"
ldd "$PREFIX/bin/vvp" | tee "$ROOT/vvp-ldd.txt"
make clean
"$PREFIX/bin/iverilog" -V >/dev/null 2>&1
"$PREFIX/bin/vvp" -V >/dev/null 2>&1
