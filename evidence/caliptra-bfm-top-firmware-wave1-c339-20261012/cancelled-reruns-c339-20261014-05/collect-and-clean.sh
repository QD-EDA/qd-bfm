#!/usr/bin/env bash
set -Eeuo pipefail

BASE=$(cd "$(dirname "$0")" && pwd)
JOB=1110
JOB_NAME=bfm-m5b-post-reopen-rerun-05
REMOTE=/home/dsell/slurm-runs/caliptra-bfm/a2/m5b-cancelled-reruns-c339-20261014-05
SSH=(ssh -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=4 DAN-DESKTOP)
SCP=(scp -q -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=4)
declare -A DONE=()
if [[ -f "$BASE/results.tsv" ]]; then
  while IFS=$'\t' read -r task _; do
    [[ "$task" == array_task || -z "$task" ]] && continue
    DONE[$task]=1
  done < "$BASE/results.tsv"
fi

copy_if_present() {
  local remote_path=$1 local_path=$2
  if "${SSH[@]}" "test -f '$remote_path'"; then
    "${SCP[@]}" "DAN-DESKTOP:$remote_path" "$local_path"
    printf '%s\t%s\n' "$remote_path" "$local_path" >> "$MAP"
  fi
}

while ((${#DONE[@]} < 4)); do
  for task in 1 2 3 4; do
    [[ -n ${DONE[$task]+x} ]] && continue
    IFS=$'\t' read -r _ source_row test_id test_name case_dir case_yaml yaml_testname expected_mcycle timeout_s selection_basis \
      < <(sed -n "$((task + 1))p" "$BASE/selection.tsv")
    case "$task" in
      1) original_task=28 ;;
      2) original_task=30 ;;
      3) original_task=34 ;;
      4) original_task=35 ;;
    esac
    RUN="$REMOTE/runs/${source_row}-${test_id}-${task}"
    if ! "${SSH[@]}" "test -s '$RUN/status.txt' && ! squeue -h -j ${JOB}_${task} | grep -q ."; then
      continue
    fi

    OUT="$BASE/task${JOB}_${task}"
    mkdir -p "$OUT"
    MAP="$OUT/copy-map.tsv"
    : > "$MAP"
    for name in provenance.txt resource.log runner.log status.txt tool-binaries.sha256 openssl-binaries.sha256 iverilog-version.txt vvp-version.txt python-version.txt riscv-gcc-version.txt; do
      copy_if_present "$RUN/$name" "$OUT/$name"
    done
    copy_if_present "$RUN/output/$case_dir/sim.log" "$OUT/sim.log"
    copy_if_present "$RUN/output/result.json" "$OUT/result.json"
    copy_if_present "$REMOTE/logs/$JOB_NAME-${JOB}_${task}.out" "$OUT/slurm.log"

    while IFS=$'\t' read -r remote_path local_path; do
      remote_sha=$("${SSH[@]}" "sha256sum '$remote_path'" | awk '{print $1}')
      local_sha=$(shasum -a 256 "$local_path" | awk '{print $1}')
      [[ "$remote_sha" == "$local_sha" ]]
    done < "$MAP"
    (cd "$OUT" && shasum -a 256 $(find . -maxdepth 1 -type f ! -name SHA256SUMS -print | sort) > SHA256SUMS)

    raw_outcome=$(awk -F= '$1 == "outcome" {print $2}' "$OUT/status.txt")
    reason=$(awk -F= '$1 == "reason" {print $2}' "$OUT/status.txt")
    runner_exit=$(awk -F= '$1 == "runner_exit" {print $2}' "$OUT/status.txt")
    if [[ -f "$OUT/resource.log" ]]; then
      elapsed_clock=$(awk -F': ' '/Elapsed \(wall clock\) time/ {print $NF}' "$OUT/resource.log")
      elapsed_s=$(python3 -c 'import sys; p=list(map(int,sys.argv[1].split(":"))); print(p[-1]+60*p[-2]+(3600*p[-3] if len(p)==3 else 0))' "$elapsed_clock")
      max_rss_kib=$(awk -F': ' '/Maximum resident set size/ {print $NF}' "$OUT/resource.log")
    else
      elapsed_s=0
      max_rss_kib=0
    fi
    outcome=$raw_outcome
    if [[ "$raw_outcome" == INFRA_ERROR && "$runner_exit" == 137 && "$elapsed_s" -eq "$timeout_s" ]]; then
      slurm_job=$("${SSH[@]}" "scontrol show job ${JOB}_${task}" || true)
      if grep -q 'JobState=COMPLETED' <<< "$slurm_job" && grep -q 'ExitCode=0:0' <<< "$slurm_job"; then
        outcome=TIMEOUT
        reason=per_test_timeout_cap_exact_exit137_slurm_completed
      fi
    fi
    heartbeat=$(grep '^CALIPTRA_PROGRESS_HEARTBEAT ' "$OUT/sim.log" 2>/dev/null | tail -n 1 || true)
    heartbeat_count=$(grep -c '^CALIPTRA_PROGRESS_HEARTBEAT ' "$OUT/sim.log" 2>/dev/null || true)
    wall_s=$(sed -n 's/.*wall_s=\([0-9][0-9]*\).*/\1/p' <<< "$heartbeat")
    mcycle=$(sed -n 's/.*mcycle=\([0-9][0-9]*\).*/\1/p' <<< "$heartbeat")
    [[ -n "$wall_s" ]] || wall_s=0
    [[ -n "$mcycle" ]] || mcycle=0
    final_mcycle=$mcycle
    mcycle_source=latest-heartbeat
    if [[ "$outcome" == PASS && -f "$OUT/result.json" ]]; then
      finish_mcycle=$(python3 - "$OUT/result.json" <<'PY'
import json, sys
result=json.load(open(sys.argv[1]))
finish=result.get('finish')
print(finish[1] if isinstance(finish, list) and len(finish)>1 else '')
PY
)
      if [[ -n "$finish_mcycle" ]]; then
        final_mcycle=$finish_mcycle
        mcycle_source=finish
      fi
    fi
    printf '%s\t%s\t%s\t%s\tTERMINAL\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t0\t%s\ttask%s_%s/README.md\n' \
      "$task" "$source_row" "$original_task" "$test_name" \
      "$outcome" "$final_mcycle" "$wall_s" "$mcycle" "$timeout_s" "$elapsed_s" "$runner_exit" "$heartbeat_count" "$max_rss_kib" "$JOB" "$task" \
      >> "$BASE/results.tsv"
    cat > "$OUT/README.md" <<EOF
# Array ${JOB}_${task}: source row ${source_row}

- Test: ${test_name}
- Outcome: ${outcome} (raw wrapper outcome: ${raw_outcome}; reason: ${reason})
- Endpoint mcycle: ${final_mcycle} (${mcycle_source})
- Last progress: wall ${wall_s}s, heartbeat mcycle ${mcycle} (${heartbeat_count} heartbeats)
- Per-test cap / elapsed: ${timeout_s}s / ${elapsed_s}s
- Runner exit: ${runner_exit}; peak RSS: ${max_rss_kib} KiB
- Raw task evidence is checksum-verified in this directory; the simulator log and result JSON (when present) are preserved.
EOF

    cleanup=$("${SSH[@]}" "set -e; run='$RUN'; before=\$(df -B1 --output=avail /home/dsell | tail -1 | tr -d ' '); bytes=\$(du -sb \"\$run/output\" \"\$run/pycache\" 2>/dev/null | awk '{s+=\$1} END{print s+0}'); rm -rf \"\$run/output\" \"\$run/pycache\"; after=\$(df -B1 --output=avail /home/dsell | tail -1 | tr -d ' '); printf 'task=%s_%s\\noutput_and_cache_bytes_removed=%s\\nbytes_available_before=%s\\nbytes_available_after=%s\\n' '$JOB' '$task' \"\$bytes\" \"\$before\" \"\$after\"")
    printf '%s\n' "$cleanup" > "$OUT/cleanup.txt"
    (cd "$OUT" && shasum -a 256 $(find . -maxdepth 1 -type f ! -name SHA256SUMS -print | sort) > SHA256SUMS)
    printf '\nRemote build/output trees for this task were removed after evidence verification; %s bytes of output/cache were deleted. See `task%s_%s/cleanup.txt`.\n' \
      "$(awk -F= '$1=="output_and_cache_bytes_removed"{print $2}' <<< "$cleanup")" "$JOB" "$task" >> "$BASE/README.md"
    DONE[$task]=1
    printf 'recorded and cleaned %s_%s: %s, endpoint mcycle=%s\n' "$JOB" "$task" "$outcome" "$final_mcycle"
  done
  ((${#DONE[@]} == 4)) || sleep 600
done

printf '\nAll four array tasks have terminal records and verified evidence.\n'
