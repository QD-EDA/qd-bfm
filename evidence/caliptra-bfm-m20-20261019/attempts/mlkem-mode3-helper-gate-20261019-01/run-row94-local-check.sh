#!/bin/bash
set -euo pipefail
attempt="$1"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
archive="$attempt/../mlkem-mode3-diagnostic-array-3255-20261019-01/raw/job-3255-rows-94-100-diagnostic.tar.gz"
tar -xzf "$archive" -C "$tmp" tasks/row-94/output/runtime/ml-kem/tv/encap_ext_output.txt tasks/row-94/output/runtime/ml-kem/tv/decap_ext_input.txt
cc -Wall -Wextra -Werror -O2 dv/caliptra_bfm/native_vectors/native_mlkem.c $(pkg-config --cflags --libs openssl) -o "$tmp/native_mlkem"
"$tmp/native_mlkem" 3 -i "$tmp/tasks/row-94/output/runtime/ml-kem/tv/decap_ext_input.txt" -o "$tmp/decap_ext_output.txt"
python3 - "$tmp" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
tv=root/'tasks/row-94/output/runtime/ml-kem/tv'
source=(tv/'decap_ext_input.txt').read_text().splitlines()
encap=(tv/'encap_ext_output.txt').read_text().splitlines()
decap=(root/'decap_ext_output.txt').read_text().splitlines()
assert source[0]=='3' and len(source)==3
assert decap==['3', source[1].upper(), source[2].upper(), encap[3]]
print('row 94 archived input: mode 3 output matches the prior encapsulated shared secret')
PY
