#!/bin/bash
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/verilator-iverilog-axi-readwrite-20261010-01
QD=$RUN/source/qd-bfm
BUILD=$RUN/build
IVERILOG=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog/bin
export LD_LIBRARY_PATH=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog/lib:/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
mkdir -p "$BUILD/verilator" "$BUILD/iverilog"
/usr/bin/verilator --binary --timing --build-jobs 1 -Wno-fatal --top-module tb_axi4_caliptra_memory_subordinate --Mdir "$BUILD/verilator" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv" \
  "$QD/dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_memory_subordinate.sv"
"$BUILD/verilator/Vtb_axi4_caliptra_memory_subordinate"
cd "$QD/dv/caliptra_bfm/axi/tests"
"$IVERILOG/iverilog" -g2012 -s tb_axi4_caliptra_memory_subordinate -o "$BUILD/iverilog/subordinate.vvp" \
  ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv \
  ../axi4_caliptra_memory_subordinate.sv ../axi4_caliptra_monitor.sv \
  tb_axi4_caliptra_memory_subordinate.sv
"$IVERILOG/vvp" "$BUILD/iverilog/subordinate.vvp"
"$IVERILOG/vvp" "$BUILD/iverilog/subordinate.vvp" +CASE=RESET_HANDSHAKES
"$IVERILOG/iverilog" -g2012 -s tb_axi4_caliptra_memory_queue -o "$BUILD/iverilog/memory-queue.vvp" \
  ../axi4_caliptra_memory_subordinate.sv tb_axi4_caliptra_memory_queue.sv
"$IVERILOG/vvp" "$BUILD/iverilog/memory-queue.vvp"
