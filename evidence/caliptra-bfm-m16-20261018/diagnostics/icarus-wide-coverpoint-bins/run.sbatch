#!/usr/bin/env bash
set -euo pipefail
RUN_DIR=/home/dsell/slurm-runs/caliptra-bfm/a2/m16-wide-bins-repro-20261018-01
IVERILOG=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP="${IVERILOG%/iverilog}/vvp"
printf 'host=%s\n' "$(hostname)"
printf 'iverilog=%s\n' "$("$IVERILOG" -V | head -1)"
printf 'iverilog_sha256=%s\n' "$(sha256sum "$IVERILOG" | cut -d' ' -f1)"
printf 'vvp=%s\n' "$("$VVP" -V | head -1)"
printf 'vvp_sha256=%s\n' "$(sha256sum "$VVP" | cut -d' ' -f1)"
cd "$RUN_DIR/source"
set +e
timeout --kill-after=5s 60s "$IVERILOG" -g2012 -s narrow_auto_bins_control -o "$RUN_DIR/narrow.vvp" narrow_auto_bins_control.sv >"$RUN_DIR/narrow.compile.log" 2>&1
NARROW_COMPILE=$?
if [ "$NARROW_COMPILE" -eq 0 ]; then
  timeout --kill-after=5s 60s "$VVP" -n "$RUN_DIR/narrow.vvp" >"$RUN_DIR/narrow.run.log" 2>&1
  NARROW_RUN=$?
else
  NARROW_RUN=99
fi
timeout --kill-after=5s 60s "$IVERILOG" -g2012 -s wide_auto_bins -o "$RUN_DIR/wide.vvp" wide_auto_bins.sv >"$RUN_DIR/wide.compile.log" 2>&1
WIDE_COMPILE=$?
if [ "$WIDE_COMPILE" -eq 0 ]; then
  timeout --kill-after=5s 60s "$VVP" -n "$RUN_DIR/wide.vvp" >"$RUN_DIR/wide.run.log" 2>&1
  WIDE_RUN=$?
else
  WIDE_RUN=99
fi
set -e
printf 'narrow_compile_exit=%s\nnarrow_run_exit=%s\nwide_compile_exit=%s\nwide_run_exit=%s\n' "$NARROW_COMPILE" "$NARROW_RUN" "$WIDE_COMPILE" "$WIDE_RUN" | tee "$RUN_DIR/result.txt"
cat "$RUN_DIR/narrow.compile.log" "$RUN_DIR/narrow.run.log" "$RUN_DIR/wide.compile.log" 2>/dev/null || true
if [ "$NARROW_COMPILE" -eq 0 ] && [ "$NARROW_RUN" -eq 0 ] && grep -q 'NARROW_AUTO_BINS_OK' "$RUN_DIR/narrow.run.log" && [ "$WIDE_COMPILE" -ne 0 ] && grep -q 'coverpoint wider than 64 bits' "$RUN_DIR/wide.compile.log"; then
  echo 'MINIMAL_REPRO_CONFIRMED'
else
  echo 'MINIMAL_REPRO_NOT_CONFIRMED'
  exit 2
fi
