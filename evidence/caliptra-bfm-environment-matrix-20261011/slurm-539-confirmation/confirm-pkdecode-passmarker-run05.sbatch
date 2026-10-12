#!/usr/bin/env bash
#SBATCH --job-name=a2-pkdecode-pass
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/pkdecode-passmarker-c339-20261011-05
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/pkdecode-passmarker-c339-20261011-05/logs/slurm-%j.out
set -Eeuo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/pkdecode-passmarker-c339-20261011-05
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$RUN/source"
ROOT="$RTL/submodules/adams-bridge"
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
TASK_DIR="$RUN/tasks/pkdecode"
TOP=pkdecode_tb
FILE="$ROOT/src/pk_decode/config/pkdecode_tb.vf"
mkdir -p "$TASK_DIR/runtime"
export CALIPTRA_ROOT="$RTL" CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic ADAMSBRIDGE_ROOT="$ROOT"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
grep -Fx 'Icarus=c339b9f2287a743aeb7ab6de6528e8d34a4dd602' "$RUN/source/revisions.txt"
grep -Fx 'Caliptra=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e' "$RUN/source/revisions.txt"
grep -Fx 'Adams-Bridge=b77e3d899e828d626cfc2a0d26a6b5704cc121e0' "$RUN/source/revisions.txt"
test "$(grep -c 'parameter MLDSA_MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH' "$ROOT/src/abr_top/rtl/abr_params_pkg.sv")" -eq 1
test "$(grep -c '    .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),' "$ROOT/src/pk_decode/tb/pkdecode_tb.sv")" -eq 0
test "$(grep -Fc "pkdecode_test('h40, 'h0);" "$ROOT/src/pk_decode/tb/pkdecode_tb.sv")" -eq 1
grep -Fq "addr: ABR_MEM_ADDR_WIDTH'(locked_dest_addr + num_mem_operands)}" "$ROOT/src/pk_decode/rtl/pkdecode.sv"
grep -Fq "addr: ABR_MEM_ADDR_WIDTH'(locked_dest_addr + num_mem_operands + 1)}" "$ROOT/src/pk_decode/rtl/pkdecode.sv"
# Make the existing comparison loop fail loudly and emit the matrix PASS marker only when every word matches.
python3 - "$ROOT/src/pk_decode/tb/pkdecode_tb.sv" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
s=s.replace('    int i, j;\n    $display("Starting pkdecode test\\n");',
            '    int i, j, mismatch_count;\n    $display("Starting pkdecode test\\n");')
s=s.replace('    $display("Checking output data\\n");\n    for (i = 0; i < NUM_OF_COEFF; i = i + 1) begin\n        if (actual_output_mem[i] !== expected_output_mem[i]) begin\n            $display("Error: Output mismatch at index %0d. Expected: %h, Got: %h", i, expected_output_mem[i], actual_output_mem[i]);\n        end\n    end\n    $display("Test completed\\n");',
            '    $display("Checking output data\\n");\n    mismatch_count = 0;\n    for (i = 0; i < NUM_OF_COEFF; i = i + 1) begin\n        if (actual_output_mem[i] !== expected_output_mem[i]) begin\n            mismatch_count = mismatch_count + 1;\n            $display("Error: Output mismatch at index %0d. Expected: %h, Got: %h", i, expected_output_mem[i], actual_output_mem[i]);\n        end\n    end\n    if (mismatch_count == 0)\n        $display("* TESTCASE PASSED");\n    else\n        $fatal(1, "* TESTCASE FAILED: %0d output mismatches", mismatch_count);\n    $display("Test completed\\n");')
assert s.count('int i, j, mismatch_count;') == 1
assert s.count('$display("* TESTCASE PASSED");') == 1
assert s.count('$fatal(1, "* TESTCASE FAILED: %0d output mismatches", mismatch_count);') == 1
p.write_text(s)
PY
cp -a "$ROOT/src/pk_decode/tb/." "$TASK_DIR/runtime/"
sha256sum "$ROOT/src/pk_decode/rtl/pkdecode.sv" "$ROOT/src/pk_decode/tb/pkdecode_tb.sv" "$FILE" "$IVERILOG" "$VVP" > "$TASK_DIR/input-hashes.txt"
cat "$RUN/source/revisions.txt" > "$TASK_DIR/source-revisions.txt"
"$IVERILOG" -V > "$TASK_DIR/iverilog-version.txt" 2>&1
"$VVP" -V > "$TASK_DIR/vvp-version.txt" 2>&1
export ROOT IVERILOG VVP TASK_DIR TOP FILE
set +e
timeout --signal=TERM --kill-after=30s 6900s bash -c '
  set +e
  /usr/bin/time -v -o "$TASK_DIR/compile.resource" "$IVERILOG" -g2017 -gassertions -s "$TOP" \
    -I "$ROOT/src/abr_prim/rtl" -I "$ROOT/src/abr_libs/rtl" \
    -f "$FILE" -o "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/compile.log" 2>&1
  compile_rc=$?
  if [[ $compile_rc == 0 ]]; then
    cd "$TASK_DIR/runtime"
    /usr/bin/time -v -o "$TASK_DIR/sim.resource" "$VVP" -n "$TASK_DIR/$TOP.vvp" > "$TASK_DIR/sim.log" 2>&1
    sim_rc=$?
  else
    sim_rc=NOT_RUN
  fi
  printf "compile_exit=%s\\nsim_exit=%s\\n" "$compile_rc" "$sim_rc" > "$TASK_DIR/stage-status.txt"
  [[ $compile_rc == 0 && $sim_rc == 0 ]]
' bash
runner_rc=$?
set -e
python3 - "$TASK_DIR" "$runner_rc" <<'PY'
from pathlib import Path
import json, re, sys
p=Path(sys.argv[1]); sim=(p/'sim.log').read_text(errors='replace')
summary={'runner_exit':int(sys.argv[2]), 'stage_status':(p/'stage-status.txt').read_text().strip(),
         'pass_markers':sim.count('* TESTCASE PASSED'),
         'fail_markers':sim.count('* TESTCASE FAILED'),
         'mismatch_lines':sum('Error: Output mismatch' in line for line in sim.splitlines()),
         'comparison_loops':sim.count('Checking output data')}
(p/'result.json').write_text(json.dumps(summary,indent=2)+'\n')
print(summary)
PY
