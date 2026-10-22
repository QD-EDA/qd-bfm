#!/bin/bash
set -euo pipefail
attempt="$1"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
archive="$attempt/raw/job-3255-rows-94-100-diagnostic.tar.gz"
tar -xzf "$archive" -C "$tmp" tasks/row-94/output/runtime/ml-kem/tv/encap_ext_output.txt tasks/row-94/output/runtime/ml-kem/tv/decap_ext_input.txt
cc -Wall -Wextra -Werror -O2 dv/caliptra_bfm/native_vectors/native_mlkem.c $(pkg-config --cflags --libs openssl) -o "$tmp/native_mlkem"
set +e
"$tmp/native_mlkem" 3 -i "$tmp/tasks/row-94/output/runtime/ml-kem/tv/decap_ext_input.txt" -o "$tmp/decap_ext_output.txt" 2> "$tmp/stderr"
rc=$?
set -e
test "$rc" -ne 0
grep -F 'native_mlkem: expected: native_mlkem {1|2} -i INPUT -o OUTPUT' "$tmp/stderr"
test ! -s "$tmp/decap_ext_output.txt" || ! grep -qx '3' "$tmp/decap_ext_output.txt"
echo "RED confirmed: mode 3 rejected before producing decapsulation output (exit $rc)."
