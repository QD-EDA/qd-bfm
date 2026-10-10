#!/bin/bash
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-verilator-parity-20261010-01
QD="$RUN/source/qd-bfm"
BUILD="$RUN/build"
mkdir -p "$BUILD/tb_axi4_caliptra_memory_subordinate" "$BUILD/tb_axi4_caliptra_memory_queue"
cd "$QD/dv/caliptra_bfm/axi/tests"
/usr/bin/verilator --binary --timing --build-jobs 1 -Wno-fatal \
  --top-module tb_axi4_caliptra_memory_subordinate \
  --Mdir "$BUILD/tb_axi4_caliptra_memory_subordinate" \
  ../axi4_caliptra_checker.sv ../axi4_caliptra_master.sv \
  ../axi4_caliptra_memory_subordinate.sv ../axi4_caliptra_monitor.sv \
  tb_axi4_caliptra_memory_subordinate.sv
"$BUILD/tb_axi4_caliptra_memory_subordinate/Vtb_axi4_caliptra_memory_subordinate"
"$BUILD/tb_axi4_caliptra_memory_subordinate/Vtb_axi4_caliptra_memory_subordinate" +CASE=RESET_HANDSHAKES
/usr/bin/verilator --binary --timing --build-jobs 1 -Wno-fatal \
  --top-module tb_axi4_caliptra_memory_queue \
  --Mdir "$BUILD/tb_axi4_caliptra_memory_queue" \
  ../axi4_caliptra_memory_subordinate.sv tb_axi4_caliptra_memory_queue.sv
"$BUILD/tb_axi4_caliptra_memory_queue/Vtb_axi4_caliptra_memory_queue"
