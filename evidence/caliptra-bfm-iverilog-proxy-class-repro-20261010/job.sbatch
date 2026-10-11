#!/bin/bash
#SBATCH --job-name=a2-proxy-repro
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/iverilog-proxy-class-min-20261010-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/iverilog-proxy-class-min-20261010-01/logs/%x-%j.out

set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/iverilog-proxy-class-min-20261010-01
IVERILOG_SRC=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/source/iverilog-uvm
IVERILOG=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog/bin
IVERILOG_SHA=c339b9f2287a743aeb7ab6de6528e8d34a4dd602
SOURCE_SHA=66d1510b0b7c752f4478bb2b7ddb665fda250cedf0a1bccee949dbefa9c0e87d

test "$(git -C "$IVERILOG_SRC" rev-parse HEAD)" = "$IVERILOG_SHA"
test -z "$(git -C "$IVERILOG_SRC" status --porcelain --untracked-files=all)"
test "$(sha256sum "$RUN/reproducer.sv" | cut -d' ' -f1)" = "$SOURCE_SHA"
test -x "$IVERILOG/iverilog"
printf 'Icarus=%s\nsource-sha256=%s\n' "$IVERILOG_SHA" "$SOURCE_SHA" | tee "$RUN/source-revisions.txt"
sha256sum "$IVERILOG/iverilog" | tee "$RUN/tool-binary.sha256"
"$IVERILOG/iverilog" -V > "$RUN/iverilog-version.txt" 2>&1

set +e
/usr/bin/time -v -o "$RUN/resource.log" timeout --signal=TERM --kill-after=5s 30s \
  "$IVERILOG/iverilog" -g2012 -s package_scoped_parameterized_class_top \
  -o "$RUN/reproducer.vvp" "$RUN/reproducer.sv" > "$RUN/compile.log" 2>&1
compile_status=$?
set -e
printf 'compile_exit=%s\n' "$compile_status" | tee "$RUN/result.txt"
if [[ "$compile_status" -eq 0 ]]; then
  echo 'unexpected: reproducer compiled' | tee -a "$RUN/result.txt"
  exit 1
fi
if ! rg -q 'syntax error|Invalid module item' "$RUN/compile.log"; then
  echo 'unexpected: failure did not match the parser diagnostic' | tee -a "$RUN/result.txt"
  exit 1
fi
echo 'reproduced: package-qualified parameterized class parse diagnostic' | tee -a "$RUN/result.txt"
