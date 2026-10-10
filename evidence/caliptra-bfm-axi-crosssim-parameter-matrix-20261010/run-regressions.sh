#!/bin/bash
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/codex/caliptra-axi-param-crosssim-fix-20261010-01
QD="$RUN/source/qd-bfm"
BUILD="$RUN/build"
IVERILOG=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog/bin
export LD_LIBRARY_PATH=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/toolchain/iverilog/lib:/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
TESTS="$QD/dv/caliptra_bfm/axi/tests"
mkdir -p "$BUILD/iverilog" "$BUILD/verilator"
for data_width in 32 64 128; do
  for id_width in 1 4 8; do
    tag="data${data_width}-id${id_width}"
    out="$BUILD/iverilog/$tag.vvp"
    "$IVERILOG/iverilog" -g2012 -s tb_axi4_caliptra_parameter_matrix \
      -Ptb_axi4_caliptra_parameter_matrix.DATA_WIDTH="$data_width" \
      -Ptb_axi4_caliptra_parameter_matrix.ID_WIDTH="$id_width" -o "$out" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv" \
      "$TESTS/tb_axi4_caliptra_parameter_matrix.sv"
    "$IVERILOG/vvp" "$out"
  done
done
for data_width in 32 64 128; do
  for id_width in 1 4 8; do
    tag="data${data_width}-id${id_width}"
    dir="$BUILD/verilator/$tag"
    mkdir -p "$dir"
    /usr/bin/verilator --binary --timing --build-jobs 1 -Wno-fatal \
      --top-module tb_axi4_caliptra_parameter_matrix \
      -GDATA_WIDTH="$data_width" -GID_WIDTH="$id_width" --Mdir "$dir" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv" \
      "$QD/dv/caliptra_bfm/axi/axi4_caliptra_transaction_monitor.sv" \
      "$TESTS/tb_axi4_caliptra_parameter_matrix.sv"
    "$dir/Vtb_axi4_caliptra_parameter_matrix"
  done
done
# Retest main-target reset and queue behavior after changing shared master state.
dir="$BUILD/verilator/memory-subordinate"
mkdir -p "$dir"
/usr/bin/verilator --binary --timing --build-jobs 1 -Wno-fatal \
  --top-module tb_axi4_caliptra_memory_subordinate --Mdir "$dir" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_checker.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_master.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_monitor.sv" \
  "$TESTS/tb_axi4_caliptra_memory_subordinate.sv"
"$dir/Vtb_axi4_caliptra_memory_subordinate"
"$dir/Vtb_axi4_caliptra_memory_subordinate" +CASE=RESET_HANDSHAKES
queue_dir="$BUILD/verilator/memory-queue"
mkdir -p "$queue_dir"
/usr/bin/verilator --binary --timing --build-jobs 1 -Wno-fatal \
  --top-module tb_axi4_caliptra_memory_queue --Mdir "$queue_dir" \
  "$QD/dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv" \
  "$TESTS/tb_axi4_caliptra_memory_queue.sv"
"$queue_dir/Vtb_axi4_caliptra_memory_queue"
