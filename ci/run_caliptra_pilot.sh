#!/usr/bin/env bash
# Linux CI: immutable simulator/design sources; system packages are recorded.
set -euo pipefail
repo=$(pwd)
work=${1:?usage: ci/run_caliptra_pilot.sh NEW_WORK_DIRECTORY}
mkdir "$work"
work=$(cd "$work" && pwd)
mkdir "$work/evidence" "$work/prefix"
exec > >(tee "$work/evidence/bootstrap.log") 2>&1
set -x
fetch() {
  git init "$work/$1"
  git -C "$work/$1" remote add origin "$2"
  git -C "$work/$1" fetch --depth 1 origin "$3"
  git -C "$work/$1" checkout --detach FETCH_HEAD
  test "$(git -C "$work/$1" rev-parse HEAD)" = "$3"
  printf '%s %s\n' "$1" "$3" >> "$work/evidence/source-revisions.txt"
}
fetch iverilog https://github.com/steveicarus/iverilog.git dfeee909ed9f20b4870dd93423156c0170c0e1ff
fetch verilator https://github.com/verilator/verilator.git 848d926ebd4addacacd294dc84e35d9d4ae8078c
fetch caliptra https://github.com/chipsalliance/caliptra-rtl.git 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e
uname -a > "$work/evidence/host.txt"
cat /etc/os-release >> "$work/evidence/host.txt"
python3 --version >> "$work/evidence/host.txt"
g++ --version >> "$work/evidence/host.txt"
dpkg-query -W > "$work/evidence/packages.txt"
git rev-parse HEAD > "$work/evidence/qd-bfm-revision.txt"
(
  cd "$work/iverilog"
  sh autoconf.sh
  ./configure --prefix="$work/prefix"
  make -j2
  make install
  git diff --exit-code
) > "$work/evidence/iverilog-build.log" 2>&1
(
  cd "$work/verilator"
  unset VERILATOR_ROOT
  autoconf
  ./configure --prefix="$work/prefix"
  make -j2
  make install
  git diff --exit-code
) > "$work/evidence/verilator-build.log" 2>&1
find "$work/prefix" -type f -print0 | sort -z | xargs -0 sha256sum > "$work/evidence/tool-files.sha256"
export PATH="$work/prefix/bin:$PATH"
unset VERILATOR_ROOT
iverilog -V > "$work/evidence/iverilog-version.txt" 2>&1
vvp -V > "$work/evidence/vvp-version.txt" 2>&1
verilator --version > "$work/evidence/verilator-version.txt"
cd "$repo"
/usr/bin/time -v -o "$work/evidence/standalone-resource.log" \
  ./run.sh > "$work/evidence/standalone.log" 2>&1
for delay in 0 7; do
  status=0
  /usr/bin/time -v -o "$work/evidence/delay$delay-resource.log" \
    python3 run_caliptra_subordinate.py "$work/caliptra" "$work/evidence/delay$delay" \
    --response-delay "$delay" > "$work/evidence/delay$delay.log" 2>&1 || status=$?
  # Exit 2 is a visible, verified UNKNOWN, never a clean qualification result.
  test "$status" = 2
  python3 ci/check_caliptra_evidence.py "$work/evidence/delay$delay" "$work/caliptra" "$delay" \
    | tee "$work/evidence/delay$delay-status.json"
done
python3 ci/test_evidence_check.py "$work/evidence/delay7" "$work/caliptra" \
  > "$work/evidence/evidence-check-tests.log" 2>&1
