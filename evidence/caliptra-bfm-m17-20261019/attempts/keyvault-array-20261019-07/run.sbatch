#!/bin/bash
#SBATCH --job-name=m17-kv-array
#SBATCH --partition=verilog
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --array=7,9,10%3
#SBATCH --output=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-kv-array-20261019-07/logs/%x-%A_%a.out
set -euo pipefail
RUN=/home/dsell/slurm-runs/caliptra-bfm/a2/m17-kv-array-20261019-07
SOURCE="$RUN/source"
CALIPTRA_ROOT=/home/dsell/toolchains/iverilog-c339/firmware/caliptra-rtl
IVL=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/iverilog
VVP=/home/dsell/toolchains/iverilog-uvm-9b5fad2afb4104caa816b257d5bccc40f01b8c66/install/bin/vvp
ROW_ID="$SLURM_ARRAY_TASK_ID"
OUT="$RUN/tasks/row-$ROW_ID"
mkdir -p "$OUT"
python3 - "$SOURCE/evidence/caliptra-bfm-m17-20261019/m17-results.tsv" "$ROW_ID" "$OUT/selection.json" <<'PY'
import csv,json,sys
rows=list(csv.DictReader(open(sys.argv[1]),delimiter="\t"))
row=next(r for r in rows if int(r["row_id"])==int(sys.argv[2]))
json.dump({"row_id":row["row_id"],"testname":row["testname"],"source_pin":row["source_pin"],"source_yaml_sha256":row["source_yaml_sha256"],"run_plusargs":json.loads(row["run_plusargs_json"])},open(sys.argv[3],"w"),indent=2)
PY
TEST_NAME=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["testname"])' "$OUT/selection.json")
PLUSARGS=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(" ".join(x for x in d["run_plusargs"] if not x.startswith("+UVM_TESTNAME=")))' "$OUT/selection.json")
{
  hostname
  date -u +%FT%TZ
  python3 --version
  "$IVL" -V 2>&1 | sed -n '1p'
  "$VVP" -V 2>&1 | sed -n '1p'
  git -C "$CALIPTRA_ROOT" rev-parse HEAD
  git -C "$CALIPTRA_ROOT" status --porcelain
  sha256sum "$IVL" "$VVP" "$RUN/source-snapshot.tar.gz" \
    "$SOURCE/docs/conformance/release_overlays/caliptra/keyvault_generated_bfm_iverilog_overlay.py" \
    "$SOURCE/evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.py"
  printf 'row_id=%s\ntestname=%s\nplusargs=%s\n' "$ROW_ID" "$TEST_NAME" "$PLUSARGS"
} > "$OUT/job-meta.txt"
python3 "$SOURCE/docs/conformance/release_overlays/caliptra/keyvault_generated_bfm_iverilog_overlay.py" \
  "$CALIPTRA_ROOT/src/keyvault/uvmf_kv/uvmf_template_output" "$OUT/prepared-overlay" \
  > "$OUT/overlay-generation.log" 2>&1
if grep -R -F "ahb_lite_slave_0_HSEL      = 1'b0" "$OUT/prepared-overlay"; then
  echo "unexpected generated HSEL tie-off remains" >&2
  exit 1
fi
find "$OUT/prepared-overlay" -type f -print0 | sort -z | xargs -0 sha256sum > "$OUT/prepared-overlay.sha256"
set +e
/usr/bin/time -v -o "$OUT/runner.resource" env CALIPTRA_ROOT="$CALIPTRA_ROOT" \
  IVERILOG_BIN="$IVL" VVP_BIN="$VVP" CALIPTRA_UVM_TESTNAME="$TEST_NAME" \
  CALIPTRA_UVM_PLUSARGS="$PLUSARGS" CALIPTRA_BFM_RUNTIME_TIMEOUT_SECONDS=600 \
  CALIPTRA_BFM_SUMMARY_LOG="$OUT/summary.log" CALIPTRA_UVM_TRACE_LOG="$OUT/sim.log" \
  python3 "$SOURCE/evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.py" --runtime \
  > "$OUT/runner.log" 2>&1
RC=$?
set -e
python3 - "$OUT" "$RC" <<'PY'
import json,os,socket,sys
from pathlib import Path
out=Path(sys.argv[1]); rc=int(sys.argv[2]); select=json.loads((out/"selection.json").read_text())
summary=(out/"summary.log").read_text(errors="replace") if (out/"summary.log").exists() else ""
log=(out/"runner.log").read_text(errors="replace")
if rc==0: status,cause="PASS","KeyVault runner pass gates satisfied"
elif "exceeded 600s" in (summary+log): status,cause="TIMEOUT","KeyVault runtime exceeded 600 seconds"
elif (out/"sim.log").exists(): status,cause="FAIL","runtime did not satisfy runner pass gates"
else: status,cause="BLOCKED","compile/setup failed before runtime"
result={**select,"host":socket.gethostname(),"slurm_job_id":os.environ.get("SLURM_JOB_ID"),"slurm_array_task_id":os.environ.get("SLURM_ARRAY_TASK_ID"),"timeout_seconds":600,"runner_exit":rc,"status":status,"cause":cause}
(out/"result.json").write_text(json.dumps(result,indent=2)+"\n")
(out/"result.txt").write_text(f"row_id={select['row_id']}\ntestname={select['testname']}\nstatus={status}\ncause={cause}\nrunner_exit={rc}\n")
PY
exit "$RC"
