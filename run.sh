#!/bin/sh
set -eu

out=$(mktemp)
log=$(mktemp)
trap 'rm -f "$out" "$log"' EXIT
iverilog -g2012 -s tb_axi4 -o "$out" qd_axi4_single_master.sv tb_axi4.sv
vvp "$out"
for case_name in BAD_RID BAD_RLAST; do
  if vvp "$out" "+$case_name" > "$log" 2>&1; then
    printf '%s unexpectedly passed\n' "$case_name" >&2
    exit 1
  fi
  if grep -q '^PASS:' "$log"; then
    printf '%s emitted a pass banner\n' "$case_name" >&2
    exit 1
  fi
  case "$case_name" in
    BAD_RID) grep -q 'AXI R ID mismatch' "$log" ;;
    BAD_RLAST) grep -q 'AXI single-beat read missing RLAST' "$log" ;;
  esac
done
printf 'PASS: bad response ID and missing RLAST rejected\n'

iverilog -g2012 -s tb_reset -o "$out" qd_axi4_single_master.sv tb_reset.sv
vvp "$out"
for case_name in BAD_RESET_VALID BAD_EARLY_VALID; do
  if vvp "$out" "+$case_name" > "$log" 2>&1; then
    printf '%s unexpectedly passed\n' "$case_name" >&2
    exit 1
  fi
  if grep -q '^PASS:' "$log"; then
    printf '%s emitted a pass banner\n' "$case_name" >&2
    exit 1
  fi
  case "$case_name" in
    BAD_RESET_VALID) grep -q 'reset did not clear manager outputs' "$log" ;;
    BAD_EARLY_VALID) grep -q 'request before released-reset rising edge' "$log" ;;
  esac
done
printf 'PASS: independent reset monitors rejected held/early VALID\n'

for width in 8 1024; do
  iverilog -g2012 -s tb_parameters -Ptb_parameters.WIDTH="$width" -o "$out" qd_axi4_single_master.sv tb_parameters.sv
  vvp "$out"
done
for width in 0 7 24 2048; do
  iverilog -g2012 -s tb_parameters -Ptb_parameters.WIDTH="$width" -o "$out" qd_axi4_single_master.sv tb_parameters.sv
  if vvp "$out" > "$log" 2>&1; then
    printf 'Unsupported width %s unexpectedly passed\n' "$width" >&2
    exit 1
  fi
  if grep -q '^PASS:' "$log"; then
    printf 'Unsupported width emitted a pass banner\n' >&2
    exit 1
  fi
  grep -q 'DW must be 8..1024 bits in power-of-two bytes' "$log"
done
printf 'PASS: invalid AXI size widths rejected\n'

# Four-state checks require Icarus/vvp; a two-state simulation is not an oracle.
iverilog -g2012 -s tb_four_state -o "$out" qd_axi4_single_master.sv tb_axi4.sv tb_four_state.sv
for boundary in IDLE_PAYLOAD ERROR_RDATA; do
  vvp "$out" "+SIGNAL=$boundary" > "$log" 2>&1
  grep -q "INJECTED: $boundary" "$log"
  grep -q '^PASS:' "$log"
done
for signal_name in AWREADY WREADY ARREADY BVALID RVALID BRESP RRESP BID RID RLAST RDATA; do
  for state in X Z; do
    if vvp "$out" "+SIGNAL=$signal_name" "+$state" > "$log" 2>&1; then
      printf '%s=%s unexpectedly passed\n' "$signal_name" "$state" >&2
      exit 1
    fi
    if grep -q '^PASS:' "$log"; then
      printf '%s=%s emitted a pass banner\n' "$signal_name" "$state" >&2
      exit 1
    fi
    grep -q "INJECTED: $signal_name" "$log"
    case "$signal_name" in
      BID) grep -q 'AXI B ID mismatch' "$log" ;;
      RID) grep -q 'AXI R ID mismatch' "$log" ;;
      RLAST) grep -q 'AXI single-beat read missing RLAST' "$log" ;;
      *) grep -q "AXI $signal_name is unknown" "$log" ;;
    esac
  done
done
for state in X Z; do
  if vvp "$out" +SIGNAL=CHECK "+$state" > "$log" 2>&1; then
    printf 'Unknown test condition unexpectedly passed\n' >&2
    exit 1
  fi
  grep -q 'unknown test condition rejected' "$log"
  if grep -q '^PASS:' "$log"; then exit 1; fi
done
printf 'PASS: 22 active X/Z injections rejected; idle/error payload boundaries preserved\n'

iverilog -g2012 -s tb_request_args -o "$out" qd_axi4_single_master.sv tb_request_args.sv
for state in X Z; do
  for field in ADDR ID STRB DATA; do
    case "$field" in
      ADDR) message='AXI write address argument is unknown' ;;
      ID) message='AXI write ID argument is unknown' ;;
      STRB) message='AXI write strobe argument is unknown' ;;
      DATA) message='AXI write enabled data byte is unknown' ;;
    esac
    if vvp "$out" "+FIELD=$field" "+$state" > "$log" 2>&1; then exit 1; fi
    grep -q "$message" "$log"
    if grep -q '^PASS:' "$log"; then exit 1; fi
  done
  for field in ADDR ID; do
    case "$field" in
      ADDR) message='AXI read address argument is unknown' ;;
      ID) message='AXI read ID argument is unknown' ;;
    esac
    if vvp "$out" "+FIELD=$field" "+$state" +READ > "$log" 2>&1; then exit 1; fi
    grep -q "$message" "$log"
    if grep -q '^PASS:' "$log"; then exit 1; fi
  done
  for field in MASKED ZERO_STRB KNOWN; do
    vvp "$out" "+FIELD=$field" "+$state" > "$log" 2>&1
    grep -q '^PASS: request argument boundary' "$log"
  done
done
vvp "$out" +FIELD=KNOWN +READ > "$log" 2>&1
grep -q '^PASS: request argument boundary' "$log"
printf 'PASS: 12 unknown request arguments rejected before launch; masked/zero-strobe data accepted\n'

for delay in 1 3 8; do
  iverilog -g2012 -s tb_axi4 -Ptb_axi4.RESPONSE_DELAY="$delay" -o "$out" qd_axi4_single_master.sv tb_axi4.sv
  vvp "$out"
done
iverilog -g2012 -s tb_axi4 -Ptb_axi4.RESPONSE_DELAY=-1 -o "$out" qd_axi4_single_master.sv tb_axi4.sv
if vvp "$out" > "$log" 2>&1; then exit 1; fi
grep -q 'RESPONSE_DELAY must be a known nonnegative integer' "$log"
iverilog -g2012 -s tb_reset -Ptb_reset.RESPONSE_DELAY=3 -o "$out" qd_axi4_single_master.sv tb_reset.sv
vvp "$out"
iverilog -g2012 -s tb_response_stalls -o "$out" qd_axi4_single_master.sv tb_axi4.sv tb_response_stalls.sv
vvp "$out" +FIELD=ERROR_RDATA > "$log" 2>&1
grep -q '^PASS:' "$log"
for field in RDATA RID RRESP RLAST RVALID BID BRESP BVALID; do
  for state in X Z; do
    if vvp "$out" "+FIELD=$field" "+$state" > "$log" 2>&1; then exit 1; fi
    grep -q "INJECTED: $field" "$log"
    grep -q 'response changed while stalled' "$log"
    if grep -q '^PASS:' "$log"; then exit 1; fi
  done
done
for field in RVALID BVALID RDATA BRESP; do
  case "$field" in RVALID|BVALID) mode=DROP ;; *) mode=HANDSHAKE ;; esac
  if vvp "$out" "+FIELD=$field" "+$mode" > "$log" 2>&1; then exit 1; fi
  grep -q "INJECTED: $field" "$log"
  grep -q 'response changed while stalled' "$log"
  if grep -q '^PASS:' "$log"; then exit 1; fi
done
printf 'PASS: response delays 1/3/8, reset cancellation, and 20 stalled-response violations\n'

for field in RVALID BVALID; do
  for state in X Z; do
    if vvp "$out" "+FIELD=$field" "+$state" +EARLY > "$log" 2>&1; then exit 1; fi
    grep -q "AXI $field is unknown while delaying READY" "$log"
    if grep -q '^PASS:' "$log"; then exit 1; fi
  done
done
printf 'PASS: four unknown VALID cases rejected before READY assertion\n'

iverilog -g2012 -DUNKNOWN_DELAY -s tb_parameters -o "$out" qd_axi4_single_master.sv tb_parameters.sv
if vvp "$out" > "$log" 2>&1; then exit 1; fi
grep -q 'RESPONSE_DELAY must be a known nonnegative integer' "$log"
if grep -q '^PASS:' "$log"; then exit 1; fi
