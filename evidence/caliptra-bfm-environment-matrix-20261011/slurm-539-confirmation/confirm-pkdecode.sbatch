#!/usr/bin/env bash
#SBATCH --job-name=a2-539-pkdecode
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --time=02:00:00
#SBATCH --chdir=/home/dsell/slurm-runs/caliptra-bfm/a2/issue539-pkdecode-c339-20261011-01
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/issue539-pkdecode-c339-20261011-01/logs/slurm-%j.out
set -Eeuo pipefail

RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/issue539-pkdecode-c339-20261011-01
BASE=/home/dsell/slurm-runs/caliptra-bfm/codex/maxburst-fw-20261009-06
RTL="$RUN/source"
ROOT="$RTL/submodules/adams-bridge"
IVERILOG="$BASE/toolchain/iverilog/bin/iverilog"
VVP="$BASE/toolchain/iverilog/bin/vvp"
TASK_DIR="$RUN/tasks/pkdecode"
TOP=pkdecode_tb
FILE="$ROOT/src/pk_decode/config/pkdecode_tb.vf"
mkdir -p "$TASK_DIR/runtime"
cp -a "$ROOT/src/pk_decode/tb/." "$TASK_DIR/runtime/"
export CALIPTRA_ROOT="$RTL" CALIPTRA_PRIM_ROOT="$RTL/src/caliptra_prim_generic"
export CALIPTRA_PRIM_MODULE_PREFIX=caliptra_prim_generic ADAMSBRIDGE_ROOT="$ROOT"
export LD_LIBRARY_PATH="$BASE/deps/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
grep -Fx 'Icarus=c339b9f2287a743aeb7ab6de6528e8d34a4dd602' "$RUN/source/revisions.txt"
grep -Fx 'Caliptra=49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e' "$RUN/source/revisions.txt"
grep -Fx 'Adams-Bridge=b77e3d899e828d626cfc2a0d26a6b5704cc121e0' "$RUN/source/revisions.txt"
test "$(grep -c 'parameter MLDSA_MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH' "$ROOT/src/abr_top/rtl/abr_params_pkg.sv")" -eq 1
test "$(git -C "$BASE/source/iverilog-uvm" rev-parse HEAD)" = c339b9f2287a743aeb7ab6de6528e8d34a4dd602
test -z "$(git -C "$BASE/source/iverilog-uvm" status --porcelain --untracked-files=all)"
# Existing testbench compatibility needed to compile against this pinned RTL.
python3 - "$ROOT/src/pk_decode/tb/pkdecode_tb.sv" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
old="    .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),\n    .MLDSA_K(MLDSA_K),"
new="    .MLDSA_K(MLDSA_K),"
assert s.count(old)==1
p.write_text(s.replace(old,new))
PY
# Isolated #539 workaround: cast only the two packed write-address expressions.
python3 - "$ROOT/src/pk_decode/rtl/pkdecode.sv" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
repls={
"addr: locked_dest_addr + num_mem_operands}": "addr: ABR_MEM_ADDR_WIDTH'(locked_dest_addr + num_mem_operands)}",
"addr: locked_dest_addr + num_mem_operands + 1}": "addr: ABR_MEM_ADDR_WIDTH'(locked_dest_addr + num_mem_operands + 1)}",
}
for old,new in repls.items():
    assert s.count(old)==1, (old,s.count(old))
    s=s.replace(old,new)
p.write_text(s)
PY
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
import re,sys
p=Path(sys.argv[1]); rc=sys.argv[2]
sim=(p/'sim.log').read_text(errors='replace') if (p/'sim.log').exists() else ''
stage=(p/'stage-status.txt').read_text() if (p/'stage-status.txt').exists() else ''
summary={'runner_exit':rc,'stage_status':stage.strip(),
         'pass_markers':sim.count('TESTCASE PASSED'),
         'fail_markers':sim.count('TESTCASE FAILED'),
         'write_count':len(re.findall(r'\bWriting\b',sim,re.I)),
         'all_x_lines':sum(1 for line in sim.splitlines() if re.search(r'\b(?:x{2,}|X{2,})\b',line))}
(p/'result.json').write_text(__import__('json').dumps(summary,indent=2)+'\n')
print(summary)
PY
