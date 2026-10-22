#!/bin/bash
set -euo pipefail
attempt="$1"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
seqdir="$tmp/adams/src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/sequences/src"
mkdir -p "$seqdir"
cp "$attempt/raw/kats/ML_KEM_keygen_KATs_sequence.svh" "$seqdir/"
cp "$attempt/raw/kats/ML_KEM_encaps_KATs_sequence.svh" "$seqdir/"
cc -Wall -Wextra -Werror -O2 dv/caliptra_bfm/native_vectors/native_mlkem.c $(pkg-config --cflags --libs openssl) -o "$tmp/native_mlkem"
python3 dv/caliptra_bfm/native_vectors/check_native_mlkem.py "$tmp/adams" "$tmp/native_mlkem" | tee "$attempt/raw/local-check.log"
shasum -a 256 dv/caliptra_bfm/native_vectors/native_mlkem.c dv/caliptra_bfm/native_vectors/check_native_mlkem.py > "$attempt/raw/local-source-sha256.txt"
