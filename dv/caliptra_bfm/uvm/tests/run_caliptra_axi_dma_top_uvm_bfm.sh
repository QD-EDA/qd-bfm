#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu

. "$(dirname "$0")/../../../../scripts/caliptra_bfm_memory_guard.sh"

repo_root=$(CDPATH= cd -- "$(dirname "$0")/../../../.." && pwd)
CALIPTRA_RTL=${CALIPTRA_RTL:-"$repo_root/../caliptra-rtl"}
IVERILOG_BIN=${IVERILOG_BIN:-iverilog}
VVP_BIN=${VVP_BIN:-vvp}
tmpdir=$(mktemp -d)
out="$tmpdir/caliptra_axi_dma_top_uvm_bfm.vvp"
log="$tmpdir/caliptra_axi_dma_top_uvm_bfm.log"
trap 'rm -rf "$tmpdir"' EXIT
cd "$repo_root"
reset_abort_only=0
reset_abort_mid_w_only=0
generated_reset_abort_only=0
recovery_block_sweep_only=0
recovery_route_sweep_only=0
max_sram_dut_replay_only=0
fixed_sram_modes_only=0
fifo_source_routes_only=0
fifo_source_size_sweep_only=0
fifo_destination_size_sweep_only=0
recovery_availability_modes_only=0
mailbox_fixed_modes_only=0
component_fixed_modes_only=0
default_mixed_replay_only=0
default_mixed_replay_index=-1
if [ "$#" -gt 2 ]; then
  echo "usage: $0 [--reset-abort-only|--reset-abort-mid-w-only|--generated-reset-abort-only|--recovery-block-sweep-only|--recovery-route-sweep-only|--max-sram-dut-replay-only|--fixed-sram-modes-only|--fifo-source-routes-only|--fifo-source-size-sweep-only|--fifo-destination-size-sweep-only|--recovery-availability-modes-only|--mailbox-fixed-modes-only|--component-fixed-modes-only|--default-mixed-replay-only|--default-mixed-replay-case INDEX]" >&2
  exit 2
fi
if [ "$#" -ge 1 ]; then
  case "$1" in
    --default-mixed-replay-case)
      if [ "$#" -ne 2 ]; then
        echo "usage: $0 --default-mixed-replay-case INDEX (0-24)" >&2
        exit 2
      fi
      case "$2" in
        ''|*[!0-9]*) echo "mixed replay index must be an integer from 0 to 24" >&2; exit 2 ;;
      esac
      if [ "$2" -gt 24 ]; then
        echo "mixed replay index must be from 0 to 24" >&2
        exit 2
      fi
      default_mixed_replay_only=1
      default_mixed_replay_index=$2
      ;;
    --reset-abort-only) reset_abort_only=1 ;;
    --reset-abort-mid-w-only) reset_abort_mid_w_only=1 ;;
    --generated-reset-abort-only) generated_reset_abort_only=1 ;;
    --recovery-block-sweep-only) recovery_block_sweep_only=1 ;;
    --recovery-route-sweep-only) recovery_route_sweep_only=1 ;;
    --max-sram-dut-replay-only) max_sram_dut_replay_only=1 ;;
    --fixed-sram-modes-only) fixed_sram_modes_only=1 ;;
    --fifo-source-routes-only) fifo_source_routes_only=1 ;;
    --fifo-source-size-sweep-only) fifo_source_size_sweep_only=1 ;;
    --fifo-destination-size-sweep-only) fifo_destination_size_sweep_only=1 ;;
    --recovery-availability-modes-only) recovery_availability_modes_only=1 ;;
    --mailbox-fixed-modes-only) mailbox_fixed_modes_only=1 ;;
    --component-fixed-modes-only) component_fixed_modes_only=1 ;;
    --default-mixed-replay-only) default_mixed_replay_only=1 ;;
    *)
      echo "usage: $0 [--reset-abort-only|--reset-abort-mid-w-only|--generated-reset-abort-only|--recovery-block-sweep-only|--recovery-route-sweep-only|--max-sram-dut-replay-only|--fixed-sram-modes-only|--fifo-source-routes-only|--fifo-source-size-sweep-only|--fifo-destination-size-sweep-only|--recovery-availability-modes-only|--mailbox-fixed-modes-only|--component-fixed-modes-only|--default-mixed-replay-only]" >&2
      exit 2
      ;;
  esac
fi
if [ "$#" -eq 2 ] && [ "$1" != "--default-mixed-replay-case" ]; then
  echo "usage: $0 [single replay mode]" >&2
  exit 2
fi

# Icarus requires the numeric finish argument for this otherwise unchanged
# Apache-2.0 Caliptra randomizer class.
generator_replay_mode=--dut-replay
if [ "$default_mixed_replay_only" -eq 1 ]; then
  generator_replay_mode=--dut-mixed-replay
fi
sed 's/\$fatal("/\$fatal(1, "/' \
  "$CALIPTRA_RTL/src/integration/tb/dma_transfer_randomizer.sv" \
  >"$tmpdir/dma_transfer_randomizer.sv"
python3 docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py \
  --caliptra-root "$CALIPTRA_RTL" \
  --output "$tmpdir/dma_testcase_generator.sv" \
  --manifest "$tmpdir/dma_testcase_generator_overlay.json" \
  --top tb_caliptra_axi_dma_top_uvm_bfm \
  "$generator_replay_mode"

"$IVERILOG_BIN" -uvm -g2012 -DXCELIUM \
  -I"$tmpdir" \
  -I"$CALIPTRA_RTL/src/caliptra_prim/rtl" \
  -I"$CALIPTRA_RTL/src/libs/rtl" \
  -I"$CALIPTRA_RTL/src/axi/rtl" \
  -I"$CALIPTRA_RTL/src/soc_ifc/rtl" \
  -I"$CALIPTRA_RTL/src/keyvault/rtl" \
  -I"$CALIPTRA_RTL/src/integration/rtl" \
  -I"$CALIPTRA_RTL/src/integration/rtl/caliptra_reg" \
  -I"$CALIPTRA_RTL/src/integration/tb" \
  -s tb_caliptra_axi_dma_top_uvm_bfm -o "$out" \
  -f dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f \
  "$CALIPTRA_RTL/src/caliptra_prim/rtl/caliptra_prim_util_pkg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_pkg.sv" \
  "$CALIPTRA_RTL/src/soc_ifc/rtl/soc_ifc_pkg.sv" \
  "$CALIPTRA_RTL/src/integration/tb/caliptra_top_tb_pkg.sv" \
  "$CALIPTRA_RTL/src/riscv_core/veer_el2/rtl/common_defines.sv" \
  "$CALIPTRA_RTL/src/keyvault/rtl/kv_defines_pkg.sv" \
  "$tmpdir/dma_testcase_generator.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_dma_reg_pkg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_if.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_dma_req_if.sv" \
  "$CALIPTRA_RTL/src/libs/rtl/skidbuffer.v" \
  "$CALIPTRA_RTL/src/caliptra_prim/rtl/caliptra_prim_fifo_sync_cnt.sv" \
  "$CALIPTRA_RTL/src/caliptra_prim/rtl/caliptra_prim_fifo_sync.sv" \
  "$CALIPTRA_RTL/src/keyvault/rtl/kv_fsm.sv" \
  "$CALIPTRA_RTL/src/keyvault/rtl/kv_read_rule_check.sv" \
  "$CALIPTRA_RTL/src/keyvault/rtl/kv_read_client.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_dma_reg.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_mgr_rd.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_mgr_wr.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_dma_ctrl.sv" \
  "$CALIPTRA_RTL/src/axi/rtl/axi_dma_top.sv" \
  dv/caliptra_bfm/axi/axi4_caliptra_random_stalls.sv \
  dv/caliptra_bfm/axi/axi4_caliptra_dma_if_subordinate.sv \
  dv/caliptra_bfm/uvm/axi4_caliptra_dma_if_monitor.sv \
  dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_dma_top_uvm_bfm.sv

run_case() {
  label=$1
  shift
  if ! "$VVP_BIN" "$out" "$@" >"$log" 2>&1; then
    cat "$log"
    echo "Caliptra AXI DMA top UVM BFM $label case failed" >&2
    exit 1
  fi
  cat "$log"
  if grep -Eq '^UVM_(ERROR|FATAL) :[[:space:]]*[1-9]' "$log"; then
    echo "Caliptra AXI DMA top UVM BFM $label case reported errors or fatals" >&2
    exit 1
  fi
}

if [ "$default_mixed_replay_only" -eq 1 ]; then
  case_index=0
  case_limit=25
  if [ "$default_mixed_replay_index" -ge 0 ]; then
    case_index=$default_mixed_replay_index
    case_limit=$((case_index + 1))
  fi
  generated_routes="$tmpdir/default-mixed-routes"
  generated_profiles="$tmpdir/default-mixed-profiles"
  : >"$generated_routes"
  : >"$generated_profiles"
  while [ "$case_index" -lt "$case_limit" ]; do
    run_case "default-mixed-dccm-replay-$case_index" \
      +GENERATED_CASE +CALIPTRA_BFM_DUT_MIXED_REPLAY \
      "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
      +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=25 +CPTRA_VERBOSITY=0
    if grep -Fq 'block_bytes=0' "$log"; then
      if ! grep -Fq "PASS: generated DCCM record index=$case_index route=" "$log"; then
        echo "Default mixed DCCM record $case_index did not complete through axi_dma_top" >&2
        exit 1
      fi
    elif ! grep -Fq 'PASS: actual Caliptra axi_dma_top moved' "$log"; then
      echo "Default mixed DCCM record $case_index did not complete through axi_dma_top" >&2
      exit 1
    fi
    route_type=$(sed -n 's/^INFO: Caliptra DCCM case type=\([0-4]\) words=[0-9][0-9]* .*/\1/p' "$log")
    profile=$(sed -n 's/^INFO: Caliptra DCCM case type=[0-4] words=[0-9][0-9]* .*/&/p' "$log")
    if [ -z "$route_type" ] || [ -z "$profile" ]; then
      echo "Default mixed DCCM record $case_index omitted its route or profile report" >&2
      exit 1
    fi
    printf '%s\n' "$route_type" >>"$generated_routes"
    printf '%s\n' "$profile" >>"$generated_profiles"
    case_index=$((case_index + 1))
  done
  if [ "$default_mixed_replay_index" -ge 0 ]; then
    echo "INFO: selected default mixed DCCM record $default_mixed_replay_index passed through axi_dma_top"
    exit 0
  fi
  for route_type in 0 1 2 3 4; do
    if ! grep -Fxq "$route_type" "$generated_routes"; then
      echo "Default mixed replay did not cover DMA route $route_type" >&2
      exit 1
    fi
  done
  for profile_flag in 'src_fifo=1' 'dst_fifo=1' 'fixed_read=1' 'fixed_write=1' 'inject_rand_delays=1'; do
    if ! grep -Fq "$profile_flag" "$generated_profiles"; then
      echo "Default mixed replay did not cover $profile_flag" >&2
      exit 1
    fi
  done
  if ! grep -Eq 'block_bytes=(4|8|16|32|64|128|256|512|1024|2048)$' "$generated_profiles"; then
    echo "Default mixed replay did not cover a recovery-block profile" >&2
    exit 1
  fi
  echo "INFO: replayed 25 seeded default mixed DCCM records through axi_dma_top across all routes and FIFO/fixed/delay/recovery flags"
  exit 0
fi

run_reset_abort_case() {
  run_case reset-abort +RESET_ABORT
  if ! grep -Fq 'PASS: actual Caliptra axi_dma_top reset an accepted write held before B and recovered for a post-reset DMA burst' "$log"; then
    echo "Caliptra AXI DMA top did not complete the reset-abort profile" >&2
    exit 1
  fi
}

run_reset_abort_mid_w_case() {
  run_case reset-abort-mid-w +RESET_ABORT +RESET_ABORT_MID_W +RESET_ABORT_208
  if ! grep -Fq 'PASS: actual Caliptra axi_dma_top reset an accepted write after 10 W beats and recovered for a 208-word DMA transfer' "$log"; then
    echo "Caliptra AXI DMA top did not complete the 208-word mid-W reset-abort profile" >&2
    exit 1
  fi
}

run_generated_reset_abort_case() {
  run_case generated-reset-abort +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
    +CALIPTRA_BFM_DUT_REPLAY_INDEX=67 +RESET_ABORT \
    +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=68 +CPTRA_VERBOSITY=0
  if ! grep -Fq 'replaying generated DCCM testcase 67 of 68 cases' "$log" ||
     ! grep -Fq 'inject_rst=1' "$log" ||
     ! grep -Fq 'PASS: actual Caliptra axi_dma_top reset an accepted write held before B and recovered for a post-reset DMA burst' "$log"; then
    echo "Generated inject_rst DCCM record did not complete the reset-abort path" >&2
    exit 1
  fi
}

run_generated_recovery_sweep() {
  for block_bytes in 4 8 16 32 64; do
    run_case "generated-recovery-${block_bytes}B" +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
      +FIFO_RECOVERY +CALIPTRA_BFM_DUT_REPLAY_INDEX=26 \
      +CLP_DMA_TB_MODE_THRESH \
      "+RECOVERY_BLOCK_BYTES=$block_bytes" \
      +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=29 +CPTRA_VERBOSITY=0
    if ! grep -Fq "PASS: actual Caliptra axi_dma_top moved 65 auto-generated FIFO words through recovery blocks of $block_bytes bytes" "$log"; then
      echo "Generated FIFO recovery case did not complete with a $block_bytes-byte block" >&2
      exit 1
    fi
  done
}

run_generated_recovery_route_case() {
  case_index=$1
  block_bytes=$2
  case "$case_index" in
      27)
        route_name=axi2mbox
        pass_marker_prefix="PASS: actual Caliptra axi_dma_top moved 65 FIFO words through"
        pass_marker_suffix="into the mailbox"
        ;;
      28)
        route_name=axi2ahb
        pass_marker_prefix="PASS: actual Caliptra axi_dma_top moved 65 FIFO words through"
        pass_marker_suffix="into the component data register"
        ;;
    *)
      echo "Unsupported generated recovery route record $case_index" >&2
      exit 2
      ;;
  esac
  run_case "generated-${route_name}-recovery-${block_bytes}B" \
    +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
    "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
    +FIFO_RECOVERY +CLP_DMA_TB_MODE_THRESH \
    "+RECOVERY_BLOCK_BYTES=$block_bytes" \
    +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=29 +CPTRA_VERBOSITY=0
  pass_marker="$pass_marker_prefix ${block_bytes}-byte recovery blocks $pass_marker_suffix"
  if ! grep -Fq "$pass_marker" "$log"; then
    echo "Caliptra $route_name recovery case did not complete with a ${block_bytes}-byte block" >&2
    exit 1
  fi
}

run_recovery_route_sweep() {
  for route_index in 27 28; do
    for block_bytes in 4 8 16 32 64 128 256 512 1024 2048; do
      run_generated_recovery_route_case "$route_index" "$block_bytes"
    done
  done
}

if [ "$reset_abort_only" -eq 1 ]; then
  run_reset_abort_case
  exit 0
fi
if [ "$reset_abort_mid_w_only" -eq 1 ]; then
  run_reset_abort_mid_w_case
  exit 0
fi
if [ "$generated_reset_abort_only" -eq 1 ]; then
  run_generated_reset_abort_case
  exit 0
fi
if [ "$recovery_block_sweep_only" -eq 1 ]; then
  run_generated_recovery_sweep
  echo "INFO: generated DCCM record 26 passed testbench block-size overrides of 4, 8, 16, 32, and 64 bytes"
  exit 0
fi
if [ "$recovery_route_sweep_only" -eq 1 ]; then
  run_recovery_route_sweep
  echo "INFO: AXI2MBOX and AXI2AHB FIFO recovery passed block sizes 4 through 2048 bytes"
  exit 0
fi
if [ "$recovery_availability_modes_only" -eq 1 ]; then
  for recovery_mode in NOT_EMPTY THRESH PULSE; do
    case "$recovery_mode" in
      NOT_EMPTY) recovery_mode_id=1 ;;
      THRESH) recovery_mode_id=2 ;;
      PULSE) recovery_mode_id=3 ;;
    esac
    run_case "recovery-availability-${recovery_mode}" \
      +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY +CALIPTRA_BFM_DUT_REPLAY_INDEX=26 \
      +FIFO_RECOVERY "+CLP_DMA_TB_MODE_${recovery_mode}" \
      +RECOVERY_BLOCK_BYTES=64 +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=29 +CPTRA_VERBOSITY=0
    if ! grep -Fq "INFO: selected recovery availability mode=$recovery_mode_id" "$log" ||
       ! grep -Fq 'PASS: actual Caliptra axi_dma_top moved 65 auto-generated FIFO words through recovery blocks of 64 bytes' "$log"; then
      echo "Generated AXI2AXI recovery failed in $recovery_mode availability mode" >&2
      exit 1
    fi
  done
  echo "INFO: actual Caliptra axi_dma_top passed not-empty, threshold, and pulse recovery modes"
  exit 0
fi
if [ "$max_sram_dut_replay_only" -eq 1 ]; then
  run_case max-sram-dut-replay +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
    +CALIPTRA_BFM_DUT_REPLAY_INDEX=24 \
    +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=29 +CPTRA_VERBOSITY=0
  if ! grep -Fq 'INFO: Caliptra DCCM case type=2 words=16384' "$log" ||
     ! grep -Fq 'PASS: generated DCCM record index=24 route=2 replayed through axi_dma_top' "$log"; then
    echo "Maximum DCCM-sized AXI2AXI profile did not complete through the DMA DUT" >&2
    exit 1
  fi
  exit 0
fi
if [ "$fixed_sram_modes_only" -eq 1 ]; then
  for case_index in 29 30 31; do
    case "$case_index" in
      29) fixed_read=1; fixed_write=0 ;;
      30) fixed_read=0; fixed_write=1 ;;
      31) fixed_read=1; fixed_write=1 ;;
    esac
    run_case "fixed-sram-mode-${case_index}" +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
      "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
      +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=32 +CPTRA_VERBOSITY=0
    if ! grep -Fq "fixed_read=$fixed_read fixed_write=$fixed_write inject_rand_delays=0" "$log" ||
       ! grep -Fq "PASS: generated DCCM record index=$case_index route=2 replayed through axi_dma_top" "$log"; then
      echo "Generated SRAM fixed-burst profile $case_index did not complete through the DMA DUT" >&2
      exit 1
    fi
  done
  echo "INFO: generated DCCM SRAM replay covered FIXED-read, FIXED-write, and both-FIXED profiles"
  exit 0
fi
if [ "$fifo_source_routes_only" -eq 1 ]; then
  for case_index in 32 33 34; do
    case "$case_index" in
      32) route_name=axi2axi; route_type=2 ;;
      33) route_name=axi2mbox; route_type=3 ;;
      34) route_name=axi2ahb; route_type=4 ;;
    esac
    run_case "generated-fifo-source-${route_name}" +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
      "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
      +FIFO_SOURCE_STREAM +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=35 +CPTRA_VERBOSITY=0
    if ! grep -Fq "INFO: Caliptra DCCM case type=$route_type words=65" "$log" ||
       ! grep -Fq 'INFO: FIFO source stream supplied 65 words; FIFO drained' "$log" ||
       ! grep -Fq "PASS: generated DCCM record index=$case_index route=$route_type replayed through axi_dma_top" "$log"; then
      echo "Generated FIFO-source $route_name transfer did not complete through axi_dma_top" >&2
      exit 1
    fi
  done
  echo "INFO: generated FIFO-source replay passed AXI2AXI, AXI2MBOX, and AXI2AHB routes"
  exit 0
fi
if [ "$fifo_source_size_sweep_only" -eq 1 ]; then
  case_index=35
  while [ "$case_index" -le 58 ]; do
    case "$(( (case_index - 35) % 8 ))" in
      0) word_count=1 ;;
      1) word_count=4 ;;
      2) word_count=5 ;;
      3) word_count=16 ;;
      4) word_count=64 ;;
      5) word_count=65 ;;
      6) word_count=255 ;;
      7) word_count=256 ;;
    esac
    case "$case_index" in
      35|36|37|38|39|40|41|42) route_name=axi2axi; route_type=2 ;;
      43|44|45|46|47|48|49|50) route_name=axi2mbox; route_type=3 ;;
      51|52|53|54|55|56|57|58) route_name=axi2ahb; route_type=4 ;;
    esac
    run_case "generated-fifo-source-${route_name}-${word_count}-words" +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
      "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
      +FIFO_SOURCE_STREAM +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=59 +CPTRA_VERBOSITY=0
    if ! grep -Fq "INFO: Caliptra DCCM case type=$route_type words=$word_count" "$log" ||
       ! grep -Fq "INFO: FIFO source stream supplied $word_count words; FIFO drained" "$log" ||
       ! grep -Fq "PASS: generated DCCM record index=$case_index route=$route_type replayed through axi_dma_top" "$log"; then
      echo "Generated FIFO-source $route_name transfer of $word_count words did not complete" >&2
      exit 1
    fi
    case_index=$((case_index + 1))
  done
  echo "INFO: generated FIFO-source replay passed eight sizes on AXI2AXI, AXI2MBOX, and AXI2AHB"
  exit 0
fi
if [ "$fifo_destination_size_sweep_only" -eq 1 ]; then
  case_index=59
  while [ "$case_index" -le 66 ]; do
    case "$((case_index - 59))" in
      0) word_count=1 ;;
      1) word_count=4 ;;
      2) word_count=5 ;;
      3) word_count=16 ;;
      4) word_count=64 ;;
      5) word_count=65 ;;
      6) word_count=255 ;;
      7) word_count=256 ;;
    esac
    run_case "generated-fifo-destination-${word_count}-words" \
      +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
      "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
      +SRAM2FIFO_CASE +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=67 +CPTRA_VERBOSITY=0
    if ! grep -Fq "INFO: Caliptra DCCM case type=2 words=$word_count" "$log" ||
       ! grep -Fq 'dst_fifo=1 fixed_read=0 fixed_write=1 inject_rst=0 inject_rand_delays=1' "$log" ||
       ! grep -Fq "PASS: generated DCCM record index=$case_index route=2 replayed through axi_dma_top" "$log" ||
       ! grep -Fq 'INFO: randomized AXI target stalls observed' "$log"; then
      echo "Generated SRAM-to-FIFO transfer of $word_count words did not complete with stalls" >&2
      exit 1
    fi
    case_index=$((case_index + 1))
  done
  run_case "generated-fifo-destination-full-capacity" \
    +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
    +CALIPTRA_BFM_DUT_REPLAY_INDEX=68 \
    +SRAM2FIFO_CASE +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=69 +CPTRA_VERBOSITY=0
  if ! grep -Fq 'INFO: Caliptra DCCM case type=2 words=16384' "$log" ||
     ! grep -Fq 'dst_fifo=1 fixed_read=0 fixed_write=1 inject_rst=0 inject_rand_delays=1' "$log" ||
     ! grep -Fq 'PASS: generated DCCM record index=68 route=2 replayed through axi_dma_top' "$log" ||
     ! grep -Fq 'INFO: randomized AXI target stalls observed' "$log"; then
    echo "Generated full-capacity SRAM-to-FIFO transfer did not complete with stalls" >&2
    exit 1
  fi
  echo "INFO: generated SRAM-to-FIFO replay passed sizes 1, 4, 5, 16, 64, 65, 255, and 256 plus 16,384-word FIFO capacity"
  exit 0
fi
if [ "$mailbox_fixed_modes_only" -eq 1 ]; then
  run_case axi2mbox-fixed-read +AXI2MBOX_FIXED_READ_CASE
  if ! grep -Fq 'PASS: actual Caliptra axi_dma_top sent 65 FIXED-read SRAM words through the mailbox request interface' "$log"; then
    echo "AXI2MBOX FIXED-read profile did not complete through the mailbox request interface" >&2
    exit 1
  fi
  run_case mbox2axi-fixed-write +MBOX2AXI_FIXED_WRITE_CASE
  if ! grep -Fq 'PASS: actual Caliptra axi_dma_top read 65 mailbox words and wrote them to one FIXED SRAM address' "$log"; then
    echo "MBOX2AXI FIXED-write profile did not complete to SRAM" >&2
    exit 1
  fi
  echo "INFO: actual Caliptra axi_dma_top passed FIXED-read AXI2MBOX and FIXED-write MBOX2AXI profiles"
  exit 0
fi
if [ "$component_fixed_modes_only" -eq 1 ]; then
  run_case axi2ahb-fixed-read +AXI2AHB_FIXED_READ_CASE
  if ! grep -Fq 'PASS: actual Caliptra axi_dma_top read 65 FIXED-address SRAM words through the component data register' "$log"; then
    echo "AXI2AHB FIXED-read profile did not complete through the component data register" >&2
    exit 1
  fi
  run_case ahb2axi-fixed-write +AHB2AXI_FIXED_WRITE_CASE
  if ! grep -Fq 'PASS: actual Caliptra axi_dma_top sent 65 component-register words to one FIXED SRAM address' "$log"; then
    echo "AHB2AXI FIXED-write profile did not complete to SRAM" >&2
    exit 1
  fi
  echo "INFO: actual Caliptra axi_dma_top passed FIXED-read AXI2AHB and FIXED-write AHB2AXI profiles"
  exit 0
fi

run_case success
run_reset_abort_case
run_case injected-error +INJECT_ERROR
run_case fifo-recovery +FIFO_RECOVERY +CLP_DMA_TB_MODE_THRESH
run_case axi2mbox +AXI2MBOX_CASE
if ! grep -Fq "PASS: actual Caliptra axi_dma_top read 65 SRAM words and wrote them through the mailbox request interface" "$log"; then
  echo "Caliptra AXI DMA top did not complete its AXI2MBOX mailbox writes" >&2
  exit 1
fi
run_case mbox2axi +MBOX2AXI_CASE
if ! grep -Fq "PASS: actual Caliptra axi_dma_top read 65 mailbox words and wrote them to SRAM" "$log"; then
  echo "Caliptra AXI DMA top did not complete its MBOX2AXI mailbox reads" >&2
  exit 1
fi
run_case ahb2axi +AHB2AXI_CASE
if ! grep -Fq "PASS: actual Caliptra axi_dma_top sent 65 component-register words to SRAM" "$log"; then
  echo "Caliptra AXI DMA top did not complete its AHB2AXI component writes" >&2
  exit 1
fi
run_case axi2ahb +AXI2AHB_CASE
if ! grep -Fq "PASS: actual Caliptra axi_dma_top sent 65 SRAM words through the component data register" "$log"; then
  echo "Caliptra AXI DMA top did not complete its AXI2AHB component reads" >&2
  exit 1
fi
run_case sram2fifo +SRAM2FIFO_CASE
if ! grep -Fq "PASS: actual Caliptra axi_dma_top moved 65 SRAM words to the FIFO through randomized stalls and fixed write bursts" "$log"; then
  echo "Caliptra AXI DMA top did not complete its fixed-burst SRAM-to-FIFO transfer" >&2
  exit 1
fi

case_index=0
generated_routes="$tmpdir/generated-routes"
generated_sizes="$tmpdir/generated-sizes"
: >"$generated_routes"
: >"$generated_sizes"
while [ "$case_index" -lt 29 ]; do
  if [ "$case_index" -eq 0 ]; then
    run_case "generated-dccm-replay-$case_index" +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
      "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
      +FIFO_SOURCE_STREAM +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=29 +CPTRA_VERBOSITY=0
  elif [ "$case_index" -eq 25 ]; then
    run_case "generated-dccm-replay-$case_index" +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
      "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
      +SRAM2FIFO_CASE +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=29 +CPTRA_VERBOSITY=0
  elif [ "$case_index" -eq 26 ]; then
    run_generated_recovery_sweep
  elif [ "$case_index" -eq 27 ] || [ "$case_index" -eq 28 ]; then
    run_generated_recovery_route_case "$case_index" 128
  else
    run_case "generated-dccm-replay-$case_index" +GENERATED_CASE +CALIPTRA_BFM_DUT_REPLAY \
      "+CALIPTRA_BFM_DUT_REPLAY_INDEX=$case_index" \
      +CPTRA_RAND_TEST_DMA +NUM_ITERATIONS=29 +CPTRA_VERBOSITY=0
  fi
  if [ "$case_index" -eq 26 ]; then
    if ! grep -Fq 'PASS: actual Caliptra axi_dma_top moved 65 auto-generated FIFO words through recovery blocks of 64 bytes' "$log"; then
      echo "Generated FIFO block-size case did not complete through the recovery sequencer" >&2
      exit 1
    fi
    route_type=2
  elif [ "$case_index" -eq 27 ]; then
    if ! grep -Fq 'PASS: actual Caliptra axi_dma_top moved 65 FIFO words through 128-byte recovery blocks into the mailbox' "$log"; then
      echo "Generated AXI2MBOX recovery record did not complete through the recovery sequencer" >&2
      exit 1
    fi
    route_type=3
  elif [ "$case_index" -eq 28 ]; then
    if ! grep -Fq 'PASS: actual Caliptra axi_dma_top moved 65 FIFO words through 128-byte recovery blocks into the component data register' "$log"; then
      echo "Generated AXI2AHB recovery record did not complete through the recovery sequencer" >&2
      exit 1
    fi
    route_type=4
  else
    if ! grep -Fq "PASS: generated DCCM record index=$case_index route=" "$log"; then
      echo "Generated DCCM record $case_index was not selected for DUT replay" >&2
      exit 1
    fi
    route_type=$(sed -n 's/^PASS: generated DCCM record index=[0-9][0-9]* route=\([0-4]\) replayed through axi_dma_top$/\1/p' "$log")
    if [ -z "$route_type" ]; then
      echo "Generated DCCM record $case_index reported an invalid route" >&2
      exit 1
    fi
  fi
  printf '%s\n' "$route_type" >>"$generated_routes"
  word_count=$(sed -n 's/^INFO: Caliptra DCCM case type=[0-4] words=\([0-9][0-9]*\) .*/\1/p' "$log")
  if [ -z "$word_count" ]; then
    echo "Generated DCCM record $case_index did not report its transfer size" >&2
    exit 1
  fi
  printf '%s\n' "$word_count" >>"$generated_sizes"
  if [ "$case_index" -eq 0 ]; then
    if [ "$word_count" -ne 65536 ] ||
       ! grep -Fq 'src_fifo=1 dst_fifo=0 fixed_read=1' "$log" ||
       ! grep -Fq 'INFO: FIFO source stream supplied 65536 words; FIFO drained' "$log"; then
      echo "Maximum generated FIFO source stream was not replayed and drained" >&2
      exit 1
    fi
  elif [ "$case_index" -eq 25 ]; then
    if ! grep -Fq 'dst_fifo=1 fixed_read=0 fixed_write=1 inject_rand_delays=1' "$log" ||
       ! grep -Fq 'PASS: generated DCCM record index=25 route=2 replayed through axi_dma_top' "$log" ||
       ! grep -Fq 'INFO: randomized AXI target stalls observed' "$log"; then
      echo "Generated SRAM-to-FIFO profile did not exercise fixed writes and randomized stalls" >&2
      exit 1
    fi
  elif [ "$case_index" -eq 26 ]; then
    if ! grep -Fq 'src_fifo=1 dst_fifo=0 fixed_read=1 fixed_write=0 inject_rand_delays=0 block_bytes=64' "$log" ||
       ! grep -Fq 'INFO: Caliptra DCCM case type=2 words=65' "$log"; then
      echo "Generated FIFO recovery record did not supply a supported block-size profile" >&2
      exit 1
    fi
  elif [ "$case_index" -eq 27 ]; then
    if ! grep -Fq 'src_fifo=1 dst_fifo=0 fixed_read=1 fixed_write=0 inject_rand_delays=0 block_bytes=128' "$log" ||
       ! grep -Fq 'INFO: Caliptra DCCM case type=3 words=65' "$log"; then
      echo "Generated AXI2MBOX recovery record did not supply the expected profile" >&2
      exit 1
    fi
  elif [ "$case_index" -eq 28 ]; then
    if ! grep -Fq 'src_fifo=1 dst_fifo=0 fixed_read=1 fixed_write=0 inject_rand_delays=0 block_bytes=128' "$log" ||
       ! grep -Fq 'INFO: Caliptra DCCM case type=4 words=65' "$log"; then
      echo "Generated AXI2AHB recovery record did not supply the expected profile" >&2
      exit 1
    fi
  fi
  case_index=$((case_index + 1))
done
for route_type in 0 1 2 3 4; do
  if ! grep -Fxq "$route_type" "$generated_routes"; then
    echo "Generated DCCM DUT replay did not cover DMA route $route_type" >&2
    exit 1
  fi
done
echo "INFO: generated DCCM replay covered all five DMA routes across 29 records"
echo "INFO: generated DCCM replay covered a 65-word fixed-write SRAM-to-FIFO profile"
echo "INFO: generated DCCM replay covered the 65-word FIFO recovery profile with testbench block-size overrides of 4, 8, 16, 32, and 64 bytes"
echo "INFO: generated DCCM replay covered 65-word FIFO recovery on AXI2MBOX and AXI2AHB with block-size overrides from 4 through 2048 bytes"
for word_count in 1 4 5 16 64 65 255 256 16384 65536; do
  if ! grep -Fxq "$word_count" "$generated_sizes"; then
    echo "Generated DCCM DUT replay did not cover transfer size $word_count words" >&2
    exit 1
  fi
done
echo "INFO: generated DCCM replay covered transfer sizes 1, 4, 5, 16, 64, 65, 255, 256, 16384, and 65536 words"
