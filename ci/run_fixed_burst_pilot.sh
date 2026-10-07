#!/usr/bin/env bash
# Pinned real axi_sub observation; expected upstream warnings keep it UNKNOWN.
set -euo pipefail
root=$(cd "${1:?Caliptra checkout required}" && pwd)
out=${2:?new evidence directory required}
repo=$(cd "$(dirname "$0")/.." && pwd)
test "$(git -C "$root" rev-parse HEAD)" = 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
test -z "$(git -C "$root" status --porcelain)"
mkdir "$out"
out=$(cd "$out" && pwd)
command -v verilator > "$out/tool-path.txt"
verilator --version > "$out/tool-version.txt"
git -C "$root" rev-parse HEAD > "$out/caliptra-revision.txt"
obj="$out/obj"
cmd=(verilator --binary --timing --assert -Wno-fatal
  --top-module tb_caliptra_axi_fixed_burst --timescale 1ns/1ps
  --Mdir "$obj" "-I$root/src/caliptra_prim/rtl"
  -f "$root/src/axi/config/axi_sub.vf"
  "$repo/qd_axi4_single_master.sv" "$repo/qd_caliptra_axi_single_master.sv"
  "$repo/tb_caliptra_axi_fixed_burst.sv")
printf '%q ' "${cmd[@]}" > "$out/build-command.txt"
printf '\n' >> "$out/build-command.txt"
CALIPTRA_ROOT="$root" "${cmd[@]}" > "$out/build.log" 2>&1
grep -E '^%(Warning|Error)' "$out/build.log" | sed "s|$root/||g" > "$out/diagnostics.txt"
cat > "$out/expected-diagnostics.txt" <<'EOF'
%Warning-WIDTHTRUNC: src/axi/rtl/axi_if.sv:230:43: Operator VAR 'size' expects 3 bits on the Initial value, but Initial value's CLOG2 generates 32 bits.
%Warning-WIDTHTRUNC: src/axi/rtl/axi_if.sv:334:45: Operator VAR 'size' expects 3 bits on the Initial value, but Initial value's CLOG2 generates 32 bits.
%Warning-WIDTHEXPAND: src/axi/rtl/axi_if.sv:370:42: Operator EQ expects 32 bits on the RHS, but RHS's VARREF 'len' generates 8 bits.
EOF
diff -u "$out/expected-diagnostics.txt" "$out/diagnostics.txt"
binary="$obj/Vtb_caliptra_axi_fixed_burst"
"$binary" > "$out/run.log" 2>&1
grep -q 'PASS: real Caliptra axi_sub FIXED 16-beat pair compatibility=0' "$out/run.log"
grep -q 'PASS: real Caliptra axi_sub FIXED 256-beat pair compatibility=1' "$out/run.log"
grep -q 'COVERAGE: component beats=544 held=' "$out/run.log"
for fault in BAD_DATA BAD_USER; do
  if "$binary" "+$fault" > "$out/$fault.log" 2>&1; then
    printf '%s unexpectedly passed\n' "$fault" >&2
    exit 1
  fi
  if grep -q '^PASS:' "$out/$fault.log"; then exit 1; fi
done
grep -q 'read response/data mismatch at beat 0' "$out/BAD_DATA.log"
grep -q 'component address/control mismatch at beat 0' "$out/BAD_USER.log"
test -z "$(git -C "$root" status --porcelain)"
printf 'UNKNOWN: fixed-burst behavior observed; three upstream warnings and unavailable assertion-enabled lane remain\n'
exit 2
