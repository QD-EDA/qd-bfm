#!/bin/bash
set -euo pipefail
A=evidence/caliptra-bfm-m20-20261019/attempts/mlkem-reference-model-local-20261019-01
OUT="$A/raw"
VECTORS=dv/caliptra_bfm/native_vectors
ADAMS="$A/inputs/adams-bridge"
OPENSSL_ROOT="$(brew --prefix openssl@3)"
{
  hostname
  date -u +%FT%TZ
  uname -a
  python3 --version
  clang --version | head -n 1
  openssl version
  printf 'OpenSSL root: %s\n' "$OPENSSL_ROOT"
} > "$OUT/job-meta.txt"
shasum -a 256 "$VECTORS/native_mlkem.c" "$VECTORS/random_test_ml_kem.py" "$VECTORS/check_native_mlkem.py" "$ADAMS/src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/sequences/src/ML_KEM_keygen_KATs_sequence.svh" "$ADAMS/src/abr_top/uvmf/uvmf_template_output/project_benches/mldsa/tb/sequences/src/ML_KEM_encaps_KATs_sequence.svh" > "$OUT/source-sha256.txt"
clang -Wall -Wextra -Werror -O2 -I"$OPENSSL_ROOT/include" "$VECTORS/native_mlkem.c" -L"$OPENSSL_ROOT/lib" -Wl,-rpath,"$OPENSSL_ROOT/lib" -lcrypto -o "$OUT/native_mlkem" > "$OUT/build.log" 2>&1
python3 "$VECTORS/check_native_mlkem.py" "$ADAMS" "$OUT/native_mlkem" > "$OUT/kat-check.log" 2>&1
shasum -a 256 "$OUT/native_mlkem" > "$OUT/native_mlkem.sha256"
cat "$OUT/job-meta.txt"
cat "$OUT/kat-check.log"
cat "$OUT/native_mlkem.sha256"
