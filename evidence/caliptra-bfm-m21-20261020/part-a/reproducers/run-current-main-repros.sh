#!/usr/bin/env bash
set -u

RUN=${1:?usage: run-current-main-repros.sh remote-run-root}
SRC="$RUN/reproducers"
OUT="$RUN/output"
IVL=/home/dsell/toolchains/iverilog-uvm-main-cc25756d187314742d347267c2a513b3e640a7fb/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-main-cc25756d187314742d347267c2a513b3e640a7fb/bin/vvp
mkdir -p "$OUT"
{
  date -u +%FT%TZ
  hostname
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  sha256sum "$IVL" "$VVP"
} > "$OUT/toolchain.txt"
printf 'test\tcompile_exit\tsim_exit\n' > "$OUT/results.tsv"
for source in "$SRC"/*.sv; do
  test=${source##*/}
  test=${test%.sv}
  compile_log="$OUT/$test.compile.log"
  if timeout 30s "$IVL" -g2017 -s "$test" -o "$OUT/$test.vvp" "$source" > "$compile_log" 2>&1; then
    compile_exit=0
    if timeout 30s "$VVP" "$OUT/$test.vvp" > "$OUT/$test.sim.log" 2>&1; then
      sim_exit=0
    else
      sim_exit=$?
    fi
  else
    compile_exit=$?
    sim_exit=NA
  fi
  printf '%s\t%s\t%s\n' "$test" "$compile_exit" "$sim_exit" >> "$OUT/results.tsv"
done
expected=$(find "$SRC" -maxdepth 1 -type f -name '*.sv' | wc -l)
actual=$(tail -n +2 "$OUT/results.tsv" | wc -l)
test "$actual" -eq "$expected"
