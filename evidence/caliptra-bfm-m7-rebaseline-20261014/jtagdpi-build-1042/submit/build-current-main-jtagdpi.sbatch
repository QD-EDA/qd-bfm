#!/usr/bin/env bash
#SBATCH --job-name=bfm-m7-jtagdpi
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=00:15:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-jtagdpi-3335fe7-20261014/submit
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-jtagdpi-3335fe7-20261014/logs/%x-%j.out

set -Eeuo pipefail

ROOT=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-jtagdpi-3335fe7-20261014
C339=/home/dsell/toolchains/iverilog-c339
RTL=$C339/firmware/caliptra-rtl
IVERILOG_ROOT=/home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf
IVERILOG_SRC=$IVERILOG_ROOT/source
IVERILOG=$IVERILOG_ROOT/install/bin/iverilog
IVERILOG_VPI=$IVERILOG_ROOT/install/bin/iverilog-vpi
OUTPUT=$IVERILOG_ROOT/caliptra-jtagdpi
JTAG_SOURCE=$RTL/src/integration/test_suites/libs/jtagdpi
TCP_SOURCE=$RTL/src/integration/test_suites/libs/tcp_server

mkdir -p "$ROOT/logs" "$OUTPUT"
exec > "$ROOT/logs/build-${SLURM_JOB_ID}.log" 2>&1
test "$(git -C "$RTL" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = 3335fe7ec1495956c8adc5788e9a53b0f1756ecf
test -x "$IVERILOG" && test -x "$IVERILOG_VPI"
test ! -e "$OUTPUT/jtagdpi.vpi"
export PATH="$IVERILOG_ROOT/install/bin:$PATH"
export LD_LIBRARY_PATH="$IVERILOG_ROOT/install/lib"

printf 'host=%s\nslurm_job_id=%s\niverilog_sha=%s\ncaliptra_sha=%s\n' \
  "$(hostname)" "$SLURM_JOB_ID" \
  "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" \
  "$(git -C "$RTL" rev-parse HEAD)" | tee "$ROOT/provenance.txt"
"$IVERILOG" -V > "$ROOT/iverilog-version.txt" 2>&1
sha256sum "$JTAG_SOURCE/jtagdpi.c" "$JTAG_SOURCE/jtagdpi.h" \
  "$TCP_SOURCE/tcp_server.c" "$TCP_SOURCE/tcp_server.h" \
  > "$ROOT/source-sha256.txt"

cp "$JTAG_SOURCE/jtagdpi.c" "$JTAG_SOURCE/jtagdpi.h" \
  "$TCP_SOURCE/tcp_server.c" "$TCP_SOURCE/tcp_server.h" "$OUTPUT/"
cd "$OUTPUT"
/usr/bin/time -v -o "$ROOT/resource.log" "$IVERILOG_VPI" jtagdpi.c tcp_server.c
test -s "$OUTPUT/jtagdpi.vpi"
sha256sum "$OUTPUT/jtagdpi.vpi" > "$ROOT/plugin-sha256.txt"
ldd "$OUTPUT/jtagdpi.vpi" > "$ROOT/plugin-ldd.txt"
rm -f "$OUTPUT/jtagdpi.o" "$OUTPUT/tcp_server.o"
printf 'status=BUILT\nplugin=%s\n' "$OUTPUT/jtagdpi.vpi" > "$ROOT/status.txt"
