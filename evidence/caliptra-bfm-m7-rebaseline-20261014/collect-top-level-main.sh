#!/usr/bin/env bash
set -Eeuo pipefail
BASE=$(cd "$(dirname "$0")" && pwd)
JOB=${1:?pass the Slurm array job id}
JOB_NAME=bfm-m7-top-main
REMOTE=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-top-main-3335fe7-20261014
SSH=(ssh -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=4 DAN-DESKTOP)
SCP=(scp -q -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=4)
RESULTS=$BASE/top-level-results.tsv
declare -A DONE=()

if [[ -f "$RESULTS" ]]; then
  while IFS=$'\t' read -r task _; do
    [[ "$task" == task_id || -z "$task" ]] && continue
    DONE[$task]=1
  done < "$RESULTS"
else
  printf 'task_id\tsource_row\toriginal_799_task\ttest\tc339_outcome\tc339_mcycle\tc339_mcycle_source\tc339_elapsed_s\tc339_cycles_per_s\tnew_outcome\tnew_mcycle\tnew_mcycle_source\tnew_elapsed_s\tnew_cycles_per_s\tcycles_per_s_ratio\ttimeout_s\trunner_exit\theartbeat_count\tlast_heartbeat_wall_s\tlast_heartbeat_mcycle\tmax_rss_kib\tevidence\n' > "$RESULTS"
fi

copy_if_present() {
  local remote_path=$1 local_path=$2
  if "${SSH[@]}" "test -f '$remote_path'"; then
    "${SCP[@]}" "DAN-DESKTOP:$remote_path" "$local_path"
    printf '%s\t%s\n' "$remote_path" "$local_path" >> "$MAP"
  fi
}

while ((${#DONE[@]} < 16)); do
  progress=0
  for task in $(seq 1 16); do
    [[ -n ${DONE[$task]+x} ]] && continue
    IFS=$'\t' read -r m7_index source_row original_799_task test_id matrix_testname case_dir case_yaml yaml_testname \
      c339_mcycle timeout_s selection_basis c339_outcome c339_elapsed_s c339_cycles_per_s \
      c339_last_heartbeat_mcycle c339_mcycle_source \
      < <(sed -n "$((task + 1))p" "$BASE/top-level-selection.tsv")
    RUN="$REMOTE/runs/${source_row}-${test_id}-${task}"
    if "${SSH[@]}" "squeue -h -j ${JOB}_${task} | grep -q ."; then
      if ! "${SSH[@]}" "test -s '$RUN/status.txt'"; then continue; fi
      continue
    fi
    if ! "${SSH[@]}" "test -s '$RUN/status.txt'" && ! "${SSH[@]}" "test -f '$REMOTE/logs/$JOB_NAME-${JOB}_${task}.out'"; then
      continue
    fi

    OUT="$BASE/top-level-task${JOB}_${task}"
    mkdir -p "$OUT"
    MAP="$OUT/copy-map.tsv"
    : > "$MAP"
    for name in provenance.txt resource.log runner.log status.txt tool-binaries.sha256 openssl-binaries.sha256 \
      iverilog-version.txt vvp-version.txt python-version.txt riscv-gcc-version.txt; do
      copy_if_present "$RUN/$name" "$OUT/$name"
    done
    copy_if_present "$RUN/output/$case_dir/sim.log" "$OUT/sim.log"
    copy_if_present "$RUN/output/$case_dir/firmware.log" "$OUT/firmware.log"
    copy_if_present "$RUN/output/compile.log" "$OUT/compile.log"
    copy_if_present "$RUN/output/trace_vpi/compile.log" "$OUT/trace-vpi-compile.log"
    copy_if_present "$RUN/output/result.json" "$OUT/result.json"
    copy_if_present "$REMOTE/logs/$JOB_NAME-${JOB}_${task}.out" "$OUT/slurm.log"
    while IFS=$'\t' read -r remote_path local_path; do
      remote_sha=$("${SSH[@]}" "sha256sum '$remote_path'" | awk '{print $1}')
      local_sha=$(shasum -a 256 "$local_path" | awk '{print $1}')
      [[ "$remote_sha" == "$local_sha" ]]
    done < "$MAP"

    raw_outcome=INFRA_ERROR
    reason=task_terminated_before_status
    runner_exit=unknown
    if [[ -f "$OUT/status.txt" ]]; then
      raw_outcome=$(awk -F= '$1 == "outcome" {print $2}' "$OUT/status.txt")
      reason=$(awk -F= '$1 == "reason" {print $2}' "$OUT/status.txt")
      runner_exit=$(awk -F= '$1 == "runner_exit" {print $2}' "$OUT/status.txt")
    fi
    elapsed_clock=$(awk -F': ' '/Elapsed \(wall clock\) time/ {print $NF}' "$OUT/resource.log" 2>/dev/null || true)
    if [[ -n "$elapsed_clock" ]]; then
      elapsed_s=$(python3 -c 'import sys; p=list(map(int,sys.argv[1].split(":"))); print(p[-1]+60*p[-2]+(3600*p[-3] if len(p)==3 else 0))' "$elapsed_clock")
      max_rss_kib=$(awk -F': ' '/Maximum resident set size/ {print $NF}' "$OUT/resource.log")
    else
      elapsed_s=0
      max_rss_kib=0
    fi
    outcome=$raw_outcome
    if [[ "$runner_exit" == 137 && "$elapsed_s" == "$timeout_s" ]]; then
      outcome=TIMEOUT
      reason=per_test_timeout_reached_cap
    fi
    heartbeat=$(grep '^CALIPTRA_PROGRESS_HEARTBEAT ' "$OUT/sim.log" 2>/dev/null | tail -n 1 || true)
    heartbeat_count=$(grep -c '^CALIPTRA_PROGRESS_HEARTBEAT ' "$OUT/sim.log" 2>/dev/null || true)
    wall_s=$(sed -n 's/.*wall_s=\([0-9][0-9]*\).*/\1/p' <<< "$heartbeat")
    heartbeat_mcycle=$(sed -n 's/.*mcycle=\([0-9][0-9]*\).*/\1/p' <<< "$heartbeat")
    [[ -n "$wall_s" ]] || wall_s=0
    [[ -n "$heartbeat_mcycle" ]] || heartbeat_mcycle=0
    final_mcycle=$heartbeat_mcycle
    mcycle_source=latest-heartbeat
    if [[ -f "$OUT/result.json" ]]; then
      finish_mcycle=$(python3 - "$OUT/result.json" <<'PY'
import json, sys
result=json.load(open(sys.argv[1]))
finish=result.get('finish')
print(finish[1] if isinstance(finish,list) and len(finish)>1 else '')
PY
)
      if [[ -n "$finish_mcycle" ]]; then
        final_mcycle=$finish_mcycle
        mcycle_source=finish
      fi
    fi
    new_cps=0
    ratio=0
    if (( elapsed_s > 0 )); then
      new_cps=$(python3 -c 'import sys; print(f"{int(sys.argv[1])/int(sys.argv[2]):.3f}")' "$final_mcycle" "$elapsed_s")
      ratio=$(python3 -c 'import sys; base=float(sys.argv[1]); new=float(sys.argv[2]); print(f"{new/base:.4f}" if base else "0")' "$c339_cycles_per_s" "$new_cps")
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\ttop-level-task%s_%s/README.md\n' \
      "$task" "$source_row" "$original_799_task" "$matrix_testname" "$c339_outcome" "$c339_mcycle" \
      "$c339_mcycle_source" "$c339_elapsed_s" "$c339_cycles_per_s" "$outcome" "$final_mcycle" \
      "$mcycle_source" "$elapsed_s" "$new_cps" "$ratio" "$timeout_s" "$runner_exit" \
      "$heartbeat_count" "$wall_s" "$heartbeat_mcycle" "$max_rss_kib" "$JOB" "$task" >> "$RESULTS"
    cat > "$OUT/README.md" <<EOF
# Current-main array ${JOB}_${task}: source row ${source_row}

- Test: ${matrix_testname}; original c339 task: 799_${original_799_task}
- c339: ${c339_outcome}, endpoint mcycle ${c339_mcycle} (${c339_mcycle_source}), ${c339_cycles_per_s} cycles/s
- Current main: ${outcome}; endpoint mcycle ${final_mcycle} (${mcycle_source}), ${new_cps} cycles/s; ratio ${ratio}
- Runner result: ${reason}; exit ${runner_exit}; cap / elapsed ${timeout_s}s / ${elapsed_s}s
- Last progress heartbeat: wall ${wall_s}s, mcycle ${heartbeat_mcycle} (${heartbeat_count} heartbeats)
- Peak RSS: ${max_rss_kib} KiB. Copied evidence checksums are verified in SHA256SUMS.
EOF
    (cd "$OUT" && shasum -a 256 $(find . -maxdepth 1 -type f ! -name SHA256SUMS -print | sort) > SHA256SUMS)
    cleanup=$("${SSH[@]}" "set -e; run='$RUN'; before=\$(df -B1 --output=avail /home/dsell | tail -1 | tr -d ' '); bytes=\$(du -sb \"\$run\" 2>/dev/null | awk '{print \$1}'); rm -rf \"\$run\"; after=\$(df -B1 --output=avail /home/dsell | tail -1 | tr -d ' '); printf 'task=%s_%s\\nrun_tree_bytes_removed=%s\\nbytes_available_before=%s\\nbytes_available_after=%s\\n' '$JOB' '$task' \"\$bytes\" \"\$before\" \"\$after\"")
    printf '%s\n' "$cleanup" > "$OUT/cleanup.txt"
    (cd "$OUT" && shasum -a 256 $(find . -maxdepth 1 -type f ! -name SHA256SUMS -print | sort) > SHA256SUMS)
    DONE[$task]=1
    progress=1
    printf 'recorded and cleaned %s_%s: %s, endpoint mcycle=%s, cycles/s=%s\n' "$JOB" "$task" "$outcome" "$final_mcycle" "$new_cps"
  done
  ((progress == 1)) || sleep 600
done

remote_cleanup=$("${SSH[@]}" "set -e; test -z \"\$(squeue -h -j '$JOB')\"; before=\$(df -B1 --output=avail /home/dsell | tail -1 | tr -d ' '); bytes=\$(du -sb '$REMOTE' 2>/dev/null | awk '{print \$1}'); rm -rf '$REMOTE'; after=\$(df -B1 --output=avail /home/dsell | tail -1 | tr -d ' '); printf 'array_job=%s\\nremaining_run_tree_bytes_removed=%s\\nbytes_available_before=%s\\nbytes_available_after=%s\\n' '$JOB' \"\$bytes\" \"\$before\" \"\$after\"")
printf '%s\n' "$remote_cleanup" > "$BASE/top-level-remote-cleanup.txt"
printf 'All 16 rows have terminal records and checksum-verified evidence.\n'
