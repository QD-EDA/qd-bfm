#!/usr/bin/env bash
set -Eeuo pipefail

BASE=$(cd "$(dirname "$0")" && pwd)
JOB=${1:?pass the Slurm array job id}
REMOTE=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-env-3335fe7-20261014
DEST=$BASE/environment-results-$JOB
SSH=(ssh -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=4 DAN-DESKTOP)
SCP=(scp -q -o ConnectTimeout=10 -o ServerAliveInterval=30 -o ServerAliveCountMax=4)

mkdir -p "$DEST"
"${SSH[@]}" true
while :; do
  active=$("${SSH[@]}" "squeue -h -j '$JOB'")
  [[ -z "$active" ]] && break
  printf 'environment array %s is still active; checking again in 600 seconds\n' "$JOB"
  sleep 600
done

results=$("${SSH[@]}" "find '$REMOTE/tasks' -mindepth 2 -maxdepth 2 -type f -name result.txt | wc -l | tr -d ' '")
if [[ "$results" != 44 ]]; then
  printf 'array %s has %s/44 result records; preserving remote data for review\n' "$JOB" "$results" >&2
  exit 1
fi

"${SSH[@]}" bash -s -- "$JOB" <<'REMOTE_SCRIPT'
set -Eeuo pipefail
job=$1
run=/home/dsell/slurm-runs/caliptra-bfm/a2/m7-env-3335fe7-20261014
tmp=/tmp/a2-m7-env-${job}-evidence
rm -rf "$tmp"
mkdir -p "$tmp"
cd "$run"
find tasks -mindepth 2 -maxdepth 2 -type f ! -name '*.vvp' -print > "$tmp/files.list"
find logs -mindepth 1 -maxdepth 1 -type f -print >> "$tmp/files.list"
printf '%s\n' environment-tasks.tsv submit/environment-array.sbatch >> "$tmp/files.list"
sort -o "$tmp/files.list" "$tmp/files.list"
sha256sum $(cat "$tmp/files.list") > "$tmp/files.sha256"
tar -czf "$tmp/evidence.tgz" -T "$tmp/files.list"
sha256sum "$tmp/evidence.tgz" > "$tmp/evidence.tgz.sha256"
REMOTE_SCRIPT

mkdir -p "$DEST/unpacked"
"${SCP[@]}" "DAN-DESKTOP:/tmp/a2-m7-env-$JOB-evidence/evidence.tgz" "$DEST/evidence.tgz"
"${SCP[@]}" "DAN-DESKTOP:/tmp/a2-m7-env-$JOB-evidence/files.sha256" "$DEST/remote-sha256.txt"
"${SCP[@]}" "DAN-DESKTOP:/tmp/a2-m7-env-$JOB-evidence/evidence.tgz.sha256" "$DEST/archive-sha256.txt"
remote_archive_sha=$(awk '{print $1}' "$DEST/archive-sha256.txt")
local_archive_sha=$(shasum -a 256 "$DEST/evidence.tgz" | awk '{print $1}')
[[ "$remote_archive_sha" == "$local_archive_sha" ]]
tar -xzf "$DEST/evidence.tgz" -C "$DEST/unpacked"

python3 - "$DEST" <<'PY'
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
rows = []
for line in (root / "remote-sha256.txt").read_text().splitlines():
    expected, relpath = line.split("  ", 1)
    path = root / "unpacked" / relpath
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != expected:
        raise SystemExit(f"SHA-256 mismatch for {relpath}: {actual} != {expected}")
    rows.append(f"{actual}  {relpath}")
(root / "local-sha256.txt").write_text("\n".join(rows) + "\n")
PY

"${SSH[@]}" "set -e; test -z \"\$(squeue -h -j '$JOB')\"; rm -rf '$REMOTE' /tmp/a2-m7-env-$JOB-evidence"
rm "$DEST/evidence.tgz"
printf 'array %s: 44 task records copied and checksummed; build/VVP outputs excluded; remote run directory removed\n' "$JOB"
